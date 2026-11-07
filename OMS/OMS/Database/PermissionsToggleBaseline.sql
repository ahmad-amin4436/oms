/*
  OMS - the Toggle (enable/disable) buttons are now checked against their own Toggle permission
  instead of Edit. Managers could toggle menu items and deals through Edit, so give them Toggle
  once to keep that behaviour. Admin already holds every action. Insert-only, run once.
*/
SET NOCOUNT ON;
INSERT INTO dbo.RolePermissions (RoleID, ModuleActionID, IsAllowed)
SELECT r.RoleID, ma.ModuleActionID, 1
FROM dbo.Roles r
INNER JOIN dbo.Modules m ON m.ModuleKey IN (N'MenuItems', N'DealsList')
INNER JOIN dbo.PermissionActions p ON p.ActionKey = N'Toggle'
INNER JOIN dbo.ModuleActions ma ON ma.ModuleID = m.ModuleID AND ma.ActionID = p.ActionID AND ma.IsActive = 1
WHERE r.RoleName = N'Manager'
  AND NOT EXISTS (SELECT 1 FROM dbo.RolePermissions rp WHERE rp.RoleID = r.RoleID AND rp.ModuleActionID = ma.ModuleActionID);
GO
