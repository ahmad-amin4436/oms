/*
  OMS - Additive operation permissions and audit logging migration.
  Run AFTER DatabaseSetup.sql, UsersRolesSetup.sql, and the final order workflow scripts.
  This script does not drop or recreate existing navigation, order, kitchen, or printing objects.
*/
SET NOCOUNT ON;
GO

IF COL_LENGTH('dbo.ActivityLog', 'RoleName') IS NULL
  ALTER TABLE dbo.ActivityLog ADD RoleName NVARCHAR(50) NULL;
IF COL_LENGTH('dbo.ActivityLog', 'Module') IS NULL
  ALTER TABLE dbo.ActivityLog ADD Module NVARCHAR(80) NULL;
IF COL_LENGTH('dbo.ActivityLog', 'OrderID') IS NULL
  ALTER TABLE dbo.ActivityLog ADD OrderID INT NULL;
IF COL_LENGTH('dbo.ActivityLog', 'EntityType') IS NULL
  ALTER TABLE dbo.ActivityLog ADD EntityType NVARCHAR(80) NULL;
IF COL_LENGTH('dbo.ActivityLog', 'EntityID') IS NULL
  ALTER TABLE dbo.ActivityLog ADD EntityID INT NULL;
IF COL_LENGTH('dbo.ActivityLog', 'FieldName') IS NULL
  ALTER TABLE dbo.ActivityLog ADD FieldName NVARCHAR(100) NULL;
IF COL_LENGTH('dbo.ActivityLog', 'PreviousValue') IS NULL
  ALTER TABLE dbo.ActivityLog ADD PreviousValue NVARCHAR(MAX) NULL;
IF COL_LENGTH('dbo.ActivityLog', 'NewValue') IS NULL
  ALTER TABLE dbo.ActivityLog ADD NewValue NVARCHAR(MAX) NULL;
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_ActivityLog_OrderID' AND object_id = OBJECT_ID('dbo.ActivityLog'))
  CREATE INDEX IX_ActivityLog_OrderID ON dbo.ActivityLog (OrderID, CreatedAt DESC);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_ActivityLog_CreatedAt' AND object_id = OBJECT_ID('dbo.ActivityLog'))
  CREATE INDEX IX_ActivityLog_CreatedAt ON dbo.ActivityLog (CreatedAt DESC);
GO

DECLARE @modules TABLE (ModuleKey NVARCHAR(80), ExistingModuleKey NVARCHAR(80), SortOrder INT);
INSERT INTO @modules VALUES
	('Administration', 'AdminDashboard', 10),
  ('Orders', 'OrderList', 20),
  ('Menu', 'MenuItems', 30),
  ('Deals', 'DealsList', 40),
  ('Offers', 'Offers', 50),
  ('Kitchen', 'Kitchen', 60),
  ('Reports', 'Reports', 70),
  ('Analytics', 'Analytics', 80);

IF EXISTS (SELECT 1 FROM @modules m LEFT JOIN dbo.Modules x ON x.ModuleKey = m.ExistingModuleKey WHERE x.ModuleID IS NULL)
BEGIN
  ;THROW 50101, 'One or more required OMS modules are missing from dbo.Modules.', 1;
END
GO

-- PermissionActions and ModuleActions already contain the authoritative
-- module-local action catalog. Do not insert composite action keys here.

-- Preserve the existing built-in behavior through initial database grants.
-- Administrators receive all currently defined operation permissions.
UPDATE rp
SET IsAllowed = 1
FROM dbo.RolePermissions rp
INNER JOIN dbo.Roles r ON r.RoleID = rp.RoleID
INNER JOIN dbo.ModuleActions ma ON ma.ModuleActionID = rp.ModuleActionID
WHERE r.RoleName = 'Admin'
  AND ma.IsActive = 1;

INSERT INTO dbo.RolePermissions (RoleID, ModuleActionID, IsAllowed)
SELECT r.RoleID, ma.ModuleActionID, 1
FROM dbo.Roles r
INNER JOIN dbo.ModuleActions ma ON ma.IsActive = 1
WHERE r.RoleName = 'Admin'
  AND NOT EXISTS
  (
	SELECT 1 FROM dbo.RolePermissions rp
	WHERE rp.RoleID = r.RoleID AND rp.ModuleActionID = ma.ModuleActionID
  );

GO

CREATE OR ALTER PROCEDURE dbo.sp_GetPermissionCatalog
  @RoleID INT = NULL
AS
BEGIN
  SET NOCOUNT ON;
	SELECT m.ModuleID, m.ModuleKey, m.ModuleName,
		  ma.ModuleActionID AS PermissionID, p.ActionKey, p.ActionName,
		 SortOrder = ROW_NUMBER() OVER (PARTITION BY m.ModuleID ORDER BY p.ActionName),
		 Granted = CONVERT(BIT, CASE WHEN ISNULL(rp.IsAllowed, 0) = 1 THEN 1 ELSE 0 END)
  FROM dbo.Modules m
  INNER JOIN dbo.ModuleActions ma ON ma.ModuleID = m.ModuleID AND ma.IsActive = 1
  INNER JOIN dbo.PermissionActions p ON p.ActionID = ma.ActionID
  LEFT JOIN dbo.RolePermissions rp ON rp.ModuleActionID = ma.ModuleActionID AND rp.RoleID = @RoleID
  WHERE m.IsActive = 1
  ORDER BY m.ModuleID, p.ActionName;
END
GO

CREATE OR ALTER PROCEDURE dbo.sp_SetRolePermissions
  @RoleID INT,
  @PermissionIDs NVARCHAR(MAX) = NULL
AS
BEGIN
  SET NOCOUNT ON;
  IF NOT EXISTS (SELECT 1 FROM dbo.Roles WHERE RoleID = @RoleID)
  BEGIN
	;THROW 50100, 'The selected role does not exist.', 1;
  END

  BEGIN TRANSACTION;
	DELETE rp
  FROM dbo.RolePermissions rp
  INNER JOIN dbo.ModuleActions ma ON ma.ModuleActionID = rp.ModuleActionID
  INNER JOIN dbo.Modules m ON m.ModuleID = ma.ModuleID
  WHERE rp.RoleID = @RoleID AND m.IsActive = 1 AND ma.IsActive = 1;

  IF NULLIF(LTRIM(RTRIM(@PermissionIDs)), '') IS NOT NULL
  BEGIN
	INSERT INTO dbo.RolePermissions (RoleID, ModuleActionID, IsAllowed)
	SELECT @RoleID, ma.ModuleActionID, 1
	FROM
	(
	  SELECT DISTINCT TRY_CONVERT(INT, LTRIM(RTRIM(value))) AS ModuleActionID
	  FROM STRING_SPLIT(@PermissionIDs, ',')
	) DISTINCT_VALUE
	INNER JOIN dbo.ModuleActions ma ON ma.ModuleActionID = DISTINCT_VALUE.ModuleActionID AND ma.IsActive = 1
	INNER JOIN dbo.Modules m ON m.ModuleID = ma.ModuleID AND m.IsActive = 1
	WHERE DISTINCT_VALUE.ModuleActionID IS NOT NULL;
  END
  COMMIT TRANSACTION;
END
GO

CREATE OR ALTER PROCEDURE dbo.sp_CanRolePerform
  @RoleName NVARCHAR(50),
  @ActionKey NVARCHAR(80),
  @CanPerform BIT OUTPUT
AS
BEGIN
  SET NOCOUNT ON;
  SET @CanPerform = 0;

	DECLARE @RootKey NVARCHAR(80), @ModuleKey NVARCHAR(80), @LocalActionKey NVARCHAR(80);
  SET @RootKey = PARSENAME(@ActionKey, 3);
  SET @ModuleKey = PARSENAME(@ActionKey, 2);
  SET @LocalActionKey = PARSENAME(@ActionKey, 1);

  IF @LocalActionKey IS NULL
  BEGIN
	SET @LocalActionKey = @ActionKey;
	SET @ModuleKey = @ActionKey;
  END
  ELSE IF @ModuleKey IS NULL
	SET @ModuleKey = @RootKey;

  IF @RootKey IS NULL
	SET @RootKey = @ModuleKey;

	SET @ModuleKey = CASE
	WHEN @RootKey = 'Administration' AND @ModuleKey IN ('AuditLogs', 'PrinterConfiguration', 'Administration') THEN 'AdminDashboard'
	WHEN @RootKey = 'Administration' THEN @ModuleKey
	WHEN @RootKey = 'Orders' AND @LocalActionKey = 'Add' THEN 'NewOrder'
	WHEN @RootKey = 'Orders' AND @LocalActionKey IN ('AddItem', 'ConfirmPayment', 'Cancel') THEN 'OrderDetail'
	WHEN @RootKey = 'Orders' AND @LocalActionKey = 'CloseBusinessDay' THEN 'DayClose'
	WHEN @RootKey = 'Orders' THEN 'OrderList'
	WHEN @RootKey = 'Menu' THEN 'MenuItems'
	WHEN @RootKey = 'Deals' THEN 'DealsList'
	ELSE @ModuleKey END;

  SET @LocalActionKey = CASE
	WHEN @RootKey = 'Orders' AND @LocalActionKey = 'CloseBusinessDay' THEN 'CloseDay'
	WHEN @RootKey = 'Orders' AND @LocalActionKey = 'AddItem' THEN 'AddDish'
	WHEN @RootKey = 'Orders' AND @LocalActionKey = 'ConfirmPayment' THEN 'ConfirmPayment'
	WHEN @RootKey = 'Kitchen' AND @LocalActionKey = 'MarkDone' THEN 'CompleteItem'
	ELSE @LocalActionKey END;

  IF EXISTS
  (
	SELECT 1
	FROM dbo.Roles r
	INNER JOIN dbo.RolePermissions rp ON rp.RoleID = r.RoleID
	INNER JOIN dbo.ModuleActions ma ON ma.ModuleActionID = rp.ModuleActionID AND ma.IsActive = 1 AND rp.IsAllowed = 1
	INNER JOIN dbo.Modules m ON m.ModuleID = ma.ModuleID AND m.ModuleKey = @ModuleKey AND m.IsActive = 1
	INNER JOIN dbo.PermissionActions p ON p.ActionID = ma.ActionID
	WHERE r.RoleName = @RoleName AND p.ActionKey = @LocalActionKey
  )
	SET @CanPerform = 1;
END
GO

CREATE OR ALTER PROCEDURE dbo.sp_LogActivity
  @UserID INT = NULL,
  @Action NVARCHAR(100),
  @Description NVARCHAR(500) = NULL,
  @IPAddress NVARCHAR(50) = NULL,
  @Module NVARCHAR(80) = NULL,
  @OrderID INT = NULL,
  @EntityType NVARCHAR(80) = NULL,
  @EntityID INT = NULL,
  @FieldName NVARCHAR(100) = NULL,
  @PreviousValue NVARCHAR(MAX) = NULL,
  @NewValue NVARCHAR(MAX) = NULL
AS
BEGIN
  SET NOCOUNT ON;
  DECLARE @RoleName NVARCHAR(50) =
	(SELECT TOP 1 r.RoleName FROM dbo.Users u INNER JOIN dbo.Roles r ON r.RoleID = u.RoleID WHERE u.UserID = @UserID);

  INSERT INTO dbo.ActivityLog
	(UserID, RoleName, Module, Action, Description, IPAddress, OrderID, EntityType, EntityID, FieldName, PreviousValue, NewValue)
  VALUES
	(@UserID, @RoleName, @Module, @Action, @Description, @IPAddress, @OrderID, @EntityType, @EntityID, @FieldName, @PreviousValue, @NewValue);
END
GO

CREATE OR ALTER PROCEDURE dbo.sp_GetAuditLogs
  @UserID INT = NULL,
  @RoleName NVARCHAR(50) = NULL,
  @Action NVARCHAR(100) = NULL,
  @Module NVARCHAR(80) = NULL,
  @StartDate DATE = NULL,
  @EndDate DATE = NULL,
  @OrderID INT = NULL
AS
BEGIN
  SET NOCOUNT ON;
  SELECT TOP (1000)
	a.LogID, a.UserID, u.FullName, a.RoleName, a.Module, a.Action, a.Description,
	a.IPAddress, a.OrderID, a.EntityType, a.EntityID, a.FieldName,
	a.PreviousValue, a.NewValue, a.CreatedAt
  FROM dbo.ActivityLog a
  LEFT JOIN dbo.Users u ON u.UserID = a.UserID
  WHERE (@UserID IS NULL OR a.UserID = @UserID)
	AND (@RoleName IS NULL OR a.RoleName = @RoleName)
	AND (@Action IS NULL OR a.Action = @Action)
	AND (@Module IS NULL OR a.Module = @Module)
	AND (@StartDate IS NULL OR a.CreatedAt >= @StartDate)
	AND (@EndDate IS NULL OR a.CreatedAt < DATEADD(DAY, 1, @EndDate))
	AND (@OrderID IS NULL OR a.OrderID = @OrderID)
  ORDER BY a.CreatedAt DESC, a.LogID DESC;
END
GO

CREATE OR ALTER PROCEDURE dbo.sp_GetAuditModules
AS
BEGIN
  SET NOCOUNT ON;
  SELECT ModuleKey, ModuleName
	FROM dbo.Modules
  WHERE IsActive = 1
	ORDER BY ModuleID, ModuleName;
END
GO

CREATE OR ALTER PROCEDURE dbo.sp_GetAuditActions
AS
BEGIN
  SET NOCOUNT ON;
  SELECT ActionKey, ActionName
	FROM dbo.PermissionActions
  ORDER BY ActionName;
END
GO

-- Add the page to the existing Admin Panel group without recreating navigation data.
DECLARE @AdminGroupID INT = (SELECT TOP 1 GroupID FROM dbo.NavGroups WHERE GroupName = 'Admin Panel' AND IsActive = 1);
IF @AdminGroupID IS NOT NULL
AND NOT EXISTS (SELECT 1 FROM dbo.NavItems WHERE GroupID = @AdminGroupID AND Url = '~/Admin/AuditLogs.aspx')
BEGIN
  INSERT INTO dbo.NavItems (GroupID, ItemName, Url, SortOrder)
  VALUES (@AdminGroupID, 'Audit Logs', '~/Admin/AuditLogs.aspx',
		  ISNULL((SELECT MAX(SortOrder) + 1 FROM dbo.NavItems WHERE GroupID = @AdminGroupID), 1));
END
GO

DECLARE @AuditItemID INT = (SELECT TOP 1 ItemID FROM dbo.NavItems WHERE Url = '~/Admin/AuditLogs.aspx');
IF @AuditItemID IS NOT NULL
AND NOT EXISTS (SELECT 1 FROM dbo.NavItemRoles WHERE ItemID = @AuditItemID AND RoleName = 'Admin')
  INSERT INTO dbo.NavItemRoles (ItemID, RoleName) VALUES (@AuditItemID, 'Admin');
GO

PRINT 'OMS operation permissions and audit logging migration applied.';
GO
