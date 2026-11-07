/*
  OMS - keep today's role behaviour when operation permissions (PermissionsAndAudit.sql) take over.

  Before the permission model, the code decided by role name:
    Cashier / Admin ......... settle, confirm payment, add dish to an order, close the business day
    Admin ................... cancel an order, administration pages
    Admin / Manager ......... admin dashboard, messages, menu items, deals
    Every role with access .. place orders; Kitchen / Waiter / Manager / Kitchen roles: mark a dish done
  The permission migration only granted Admin, so without this script Cashier, Kitchen and Manager would lose those actions.

  Also adds three actions the code asks for but the catalog did not contain (Admin could not have been granted them):
    Users > Add, Deals List > Add, Admin Dashboard > Edit (printer configuration).

  Additive: it only INSERTS missing rows and never removes or overrides a choice made on the Roles page.
  The role grants run once (a setting records it), so a permission an Admin removes later is not re-added.
  Run AFTER PermissionsAndAudit.sql.
*/
SET NOCOUNT ON;
SET QUOTED_IDENTIFIER ON;
GO

-- 1. missing catalog entries
DECLARE @need TABLE (ModuleKey NVARCHAR(80), ActionKey NVARCHAR(80));
INSERT @need VALUES (N'Users', N'Add'), (N'DealsList', N'Add'), (N'AdminDashboard', N'Edit');

INSERT INTO dbo.ModuleActions (ModuleID, ActionID, IsActive)
SELECT m.ModuleID, p.ActionID, 1
FROM @need n
INNER JOIN dbo.Modules m ON m.ModuleKey = n.ModuleKey
INNER JOIN dbo.PermissionActions p ON p.ActionKey = n.ActionKey
WHERE NOT EXISTS (SELECT 1 FROM dbo.ModuleActions x WHERE x.ModuleID = m.ModuleID AND x.ActionID = p.ActionID);

-- Admin holds every action
INSERT INTO dbo.RolePermissions (RoleID, ModuleActionID, IsAllowed)
SELECT r.RoleID, ma.ModuleActionID, 1
FROM dbo.Roles r
INNER JOIN dbo.ModuleActions ma ON ma.IsActive = 1
WHERE r.RoleName = N'Admin'
  AND NOT EXISTS (SELECT 1 FROM dbo.RolePermissions rp WHERE rp.RoleID = r.RoleID AND rp.ModuleActionID = ma.ModuleActionID);
GO

-- 2. grants that reproduce the previous behaviour (once)
IF NOT EXISTS (SELECT 1 FROM dbo.AppSettings WHERE SettingKey = N'Migration.PermissionBaseline')
BEGIN
  DECLARE @g TABLE (RoleName NVARCHAR(50), ModuleKey NVARCHAR(80), ActionKey NVARCHAR(80));
  INSERT @g VALUES
    -- cashier
    (N'Cashier', N'NewOrder',    N'Add'),
    (N'Cashier', N'OrderList',   N'Settle'),
    (N'Cashier', N'OrderDetail', N'ConfirmPayment'),
    (N'Cashier', N'OrderDetail', N'AddDish'),
    (N'Cashier', N'DayClose',    N'CloseDay'),
    -- manager
    (N'Manager', N'NewOrder',       N'Add'),
    (N'Manager', N'Kitchen',        N'CompleteItem'),
    (N'Manager', N'AdminDashboard', N'View'),
    (N'Manager', N'Messages',       N'View'),
    (N'Manager', N'Messages',       N'Reply'),
    (N'Manager', N'MenuItems',      N'Add'),
    (N'Manager', N'MenuItems',      N'Edit'),
    (N'Manager', N'MenuItems',      N'Delete'),
    (N'Manager', N'DealsList',      N'Add'),
    (N'Manager', N'DealsList',      N'Edit'),
    (N'Manager', N'DealsList',      N'Delete'),
    -- everyone who could place an order
    (N'Waiter',      N'NewOrder', N'Add'),
    (N'Order Taker', N'NewOrder', N'Add'),
    -- kitchen screen: roles that can open it
    (N'Waiter',   N'Kitchen', N'CompleteItem'),
    (N'Kitchen',  N'Kitchen', N'CompleteItem'),
    (N'kitchen2', N'Kitchen', N'CompleteItem');

  INSERT INTO dbo.RolePermissions (RoleID, ModuleActionID, IsAllowed)
  SELECT r.RoleID, ma.ModuleActionID, 1
  FROM @g g
  INNER JOIN dbo.Roles r              ON r.RoleName = g.RoleName
  INNER JOIN dbo.Modules m            ON m.ModuleKey = g.ModuleKey
  INNER JOIN dbo.PermissionActions p  ON p.ActionKey = g.ActionKey
  INNER JOIN dbo.ModuleActions ma     ON ma.ModuleID = m.ModuleID AND ma.ActionID = p.ActionID AND ma.IsActive = 1
  WHERE NOT EXISTS (SELECT 1 FROM dbo.RolePermissions rp WHERE rp.RoleID = r.RoleID AND rp.ModuleActionID = ma.ModuleActionID);

  EXEC dbo.sp_SetSetting @SettingKey = N'Migration.PermissionBaseline', @SettingValue = N'1', @UpdatedBy = NULL;
END
GO

SELECT r.RoleName, Grants = COUNT(*)
FROM dbo.RolePermissions rp INNER JOIN dbo.Roles r ON r.RoleID = rp.RoleID
WHERE rp.IsAllowed = 1 GROUP BY r.RoleName ORDER BY r.RoleName;
GO
