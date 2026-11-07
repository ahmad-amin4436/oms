/*
  OMS - Roles & Rights audit fixes. Additive and re-runnable: only inserts missing rows, switches
  unused catalog entries off (IsActive = 0, never deleted) and replaces sp_CanRolePerform.
  Run AFTER PermissionsAndAudit.sql, PermissionsPreserveBehaviour.sql and DeleteOrderItem.sql.

  1. Audit Logs and Printer Configuration are real pages, so they get their own modules instead of
     borrowing Admin Dashboard (Audit Logs > View, Printer Configuration > View / Edit).
     Existing grants are copied, so nobody gains or loses access.
  2. Admin Dashboard > Edit only ever meant "edit printers"; it is switched off (Printer Configuration > Edit replaces it).
  3. Categories > Toggle is switched off: the category screen has no toggle button (active/inactive is part of Edit).
  4. Baseline grants so roles keep what they could do before these operations were enforced.
*/
SET NOCOUNT ON;
SET QUOTED_IDENTIFIER ON;
GO

-- 1. modules + actions ---------------------------------------------------------------
INSERT INTO dbo.Modules (ModuleKey, ModuleName, IsActive)
SELECT v.k, v.n, 1 FROM (VALUES (N'AuditLogs', N'Audit Logs'), (N'PrinterConfiguration', N'Printer Configuration')) v(k, n)
WHERE NOT EXISTS (SELECT 1 FROM dbo.Modules m WHERE m.ModuleKey = v.k);

DECLARE @new TABLE (ModuleKey NVARCHAR(80), ActionKey NVARCHAR(80));
INSERT @new VALUES (N'AuditLogs', N'View'), (N'PrinterConfiguration', N'View'), (N'PrinterConfiguration', N'Edit');

INSERT INTO dbo.ModuleActions (ModuleID, ActionID, IsActive)
SELECT m.ModuleID, p.ActionID, 1
FROM @new n
INNER JOIN dbo.Modules m ON m.ModuleKey = n.ModuleKey
INNER JOIN dbo.PermissionActions p ON p.ActionKey = n.ActionKey
WHERE NOT EXISTS (SELECT 1 FROM dbo.ModuleActions x WHERE x.ModuleID = m.ModuleID AND x.ActionID = p.ActionID);

-- carry the old grants over: (old module, old action) -> (new module, new action)
DECLARE @copy TABLE (FromModule NVARCHAR(80), FromAction NVARCHAR(80), ToModule NVARCHAR(80), ToAction NVARCHAR(80));
INSERT @copy VALUES
  (N'AdminDashboard', N'View', N'AuditLogs',            N'View'),
  (N'AdminDashboard', N'View', N'PrinterConfiguration', N'View'),
  (N'AdminDashboard', N'Edit', N'PrinterConfiguration', N'Edit');

INSERT INTO dbo.RolePermissions (RoleID, ModuleActionID, IsAllowed)
SELECT DISTINCT rp.RoleID, nma.ModuleActionID, 1
FROM @copy c
INNER JOIN dbo.Modules fm ON fm.ModuleKey = c.FromModule
INNER JOIN dbo.PermissionActions fp ON fp.ActionKey = c.FromAction
INNER JOIN dbo.ModuleActions fma ON fma.ModuleID = fm.ModuleID AND fma.ActionID = fp.ActionID
INNER JOIN dbo.RolePermissions rp ON rp.ModuleActionID = fma.ModuleActionID AND rp.IsAllowed = 1
INNER JOIN dbo.Modules tm ON tm.ModuleKey = c.ToModule
INNER JOIN dbo.PermissionActions tp ON tp.ActionKey = c.ToAction
INNER JOIN dbo.ModuleActions nma ON nma.ModuleID = tm.ModuleID AND nma.ActionID = tp.ActionID
WHERE NOT EXISTS (SELECT 1 FROM dbo.RolePermissions x WHERE x.RoleID = rp.RoleID AND x.ModuleActionID = nma.ModuleActionID);

-- Admin holds every active action
INSERT INTO dbo.RolePermissions (RoleID, ModuleActionID, IsAllowed)
SELECT r.RoleID, ma.ModuleActionID, 1
FROM dbo.Roles r INNER JOIN dbo.ModuleActions ma ON ma.IsActive = 1
WHERE r.RoleName = N'Admin'
  AND NOT EXISTS (SELECT 1 FROM dbo.RolePermissions x WHERE x.RoleID = r.RoleID AND x.ModuleActionID = ma.ModuleActionID);

-- 2 + 3. switch off entries that match nothing on the site
UPDATE ma SET IsActive = 0
FROM dbo.ModuleActions ma
INNER JOIN dbo.Modules m ON m.ModuleID = ma.ModuleID
INNER JOIN dbo.PermissionActions p ON p.ActionID = ma.ActionID
WHERE (m.ModuleKey = N'AdminDashboard' AND p.ActionKey = N'Edit')
   OR (m.ModuleKey = N'Categories'     AND p.ActionKey = N'Toggle');
GO

-- 4. baseline grants (insert-only) -------------------------------------------------------------
DECLARE @g TABLE (RoleName NVARCHAR(50), ModuleKey NVARCHAR(80), ActionKey NVARCHAR(80));
-- the notification bell was shown to everyone; marking read was Admin / Manager
INSERT @g SELECT r.RoleName, N'Notifications', N'View' FROM dbo.Roles r;
INSERT @g VALUES (N'Manager', N'Notifications', N'MarkRead');
-- categories were editable by whoever could edit menu items
INSERT @g VALUES (N'Manager', N'Categories', N'View'), (N'Manager', N'Categories', N'Add'),
                 (N'Manager', N'Categories', N'Edit'), (N'Manager', N'Categories', N'Delete');
-- offers / coupons pages were open to anyone with the Deals menu
INSERT @g VALUES (N'Manager', N'Offers', N'View'), (N'Manager', N'Offers', N'Toggle');
-- dish tickets: every role that can open Order Detail
INSERT @g VALUES (N'Cashier', N'OrderDetail', N'Print'), (N'Manager', N'OrderDetail', N'Print');
-- invoice print button: every role with the Print Invoice menu
INSERT @g SELECT x.RoleName, N'Reports', N'View'  FROM (VALUES (N'Cashier'), (N'Manager'), (N'Order Taker'), (N'Waiter')) x(RoleName);
INSERT @g SELECT x.RoleName, N'Reports', N'Print' FROM (VALUES (N'Cashier'), (N'Manager'), (N'Order Taker'), (N'Waiter')) x(RoleName);
-- table export was available on every screen the role could open
INSERT @g VALUES (N'Cashier', N'OrderList', N'Export'), (N'Manager', N'OrderList', N'Export'),
                 (N'Manager', N'MenuItems', N'Export'), (N'Cashier', N'Analytics', N'Export');

INSERT INTO dbo.RolePermissions (RoleID, ModuleActionID, IsAllowed)
SELECT DISTINCT r.RoleID, ma.ModuleActionID, 1
FROM @g g
INNER JOIN dbo.Roles r             ON r.RoleName = g.RoleName
INNER JOIN dbo.Modules m           ON m.ModuleKey = g.ModuleKey
INNER JOIN dbo.PermissionActions p ON p.ActionKey = g.ActionKey
INNER JOIN dbo.ModuleActions ma    ON ma.ModuleID = m.ModuleID AND ma.ActionID = p.ActionID AND ma.IsActive = 1
WHERE NOT EXISTS (SELECT 1 FROM dbo.RolePermissions x WHERE x.RoleID = r.RoleID AND x.ModuleActionID = ma.ModuleActionID);
GO

-- sp_CanRolePerform: Audit Logs / Printer Configuration resolve to their own modules now.
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
    WHEN @RootKey = 'Administration' AND @ModuleKey = 'Administration' THEN 'AdminDashboard'
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
PRINT 'Roles & Rights audit migration applied.';
GO
