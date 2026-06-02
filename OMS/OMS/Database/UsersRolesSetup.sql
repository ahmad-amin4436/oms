/*
  OMS - Restaurant Management System
  Users management + Roles & Rights stored procedures.
  Run AFTER DatabaseSetup.sql and NavMenuSetup.sql.

  "Rights" in this system = which Roles can see which navigation Groups
  (dbo.NavGroupRoles). Editing a role's rights here controls what that
  role sees in the sidebar — the same data the Site.Master renders from.
*/

SET NOCOUNT ON;
GO

-- ============================================================
--  USERS  (CRUD)
-- ============================================================

-- Refresh the listing proc so it also returns RoleID (needed to
-- pre-select the role dropdown when editing a user).
CREATE OR ALTER PROCEDURE dbo.sp_GetAllUsers
AS
BEGIN
  SELECT u.UserID, u.FullName, u.Email, u.RoleID, r.RoleName, u.IsActive, u.CreatedAt
  FROM dbo.Users u
  INNER JOIN dbo.Roles r ON u.RoleID = r.RoleID
  ORDER BY u.CreatedAt DESC;
END
GO

CREATE OR ALTER PROCEDURE dbo.sp_GetUserByID
  @UserID INT
AS
BEGIN
  SELECT u.UserID, u.FullName, u.Email, u.RoleID, r.RoleName, u.IsActive, u.CreatedAt
  FROM dbo.Users u
  INNER JOIN dbo.Roles r ON u.RoleID = r.RoleID
  WHERE u.UserID = @UserID;
END
GO

-- Insert when @UserID = 0/NULL, otherwise update.
-- @PasswordHash may be NULL on update (means "keep existing password").
CREATE OR ALTER PROCEDURE dbo.sp_SaveUser
  @UserID       INT OUTPUT,
  @FullName     NVARCHAR(120),
  @Email        NVARCHAR(150),
  @PasswordHash NVARCHAR(256) = NULL,
  @RoleID       INT,
  @IsActive     BIT
AS
BEGIN
  SET NOCOUNT ON;

  -- Enforce unique email (table also has a UNIQUE constraint; this gives a clean message).
  IF EXISTS (SELECT 1 FROM dbo.Users
             WHERE Email = @Email AND UserID <> ISNULL(@UserID, 0))
  BEGIN
    RAISERROR('A user with that email already exists.', 16, 1);
    RETURN;
  END

  IF ISNULL(@UserID, 0) = 0
  BEGIN
    IF @PasswordHash IS NULL
    BEGIN
      RAISERROR('A password is required for a new user.', 16, 1);
      RETURN;
    END

    INSERT INTO dbo.Users (FullName, Email, PasswordHash, RoleID, IsActive)
    VALUES (@FullName, @Email, @PasswordHash, @RoleID, @IsActive);
    SET @UserID = SCOPE_IDENTITY();
  END
  ELSE
  BEGIN
    UPDATE dbo.Users
    SET FullName     = @FullName,
        Email        = @Email,
        PasswordHash = COALESCE(@PasswordHash, PasswordHash),
        RoleID       = @RoleID,
        IsActive     = @IsActive
    WHERE UserID = @UserID;
  END
END
GO

-- Hard delete a user. Blocked if the user has order history (FK),
-- in which case the caller should deactivate instead.
CREATE OR ALTER PROCEDURE dbo.sp_DeleteUser
  @UserID INT
AS
BEGIN
  SET NOCOUNT ON;

  IF EXISTS (SELECT 1 FROM dbo.Orders WHERE CreatedBy = @UserID)
  BEGIN
    RAISERROR('This user has order history and cannot be deleted. Deactivate the account instead.', 16, 1);
    RETURN;
  END

  DELETE FROM dbo.Users WHERE UserID = @UserID;
END
GO

-- ============================================================
--  ROLES  (CRUD)
-- ============================================================

-- All roles plus a live count of how many users hold each role.
CREATE OR ALTER PROCEDURE dbo.sp_GetRoles
AS
BEGIN
  SELECT r.RoleID,
         r.RoleName,
         UserCount = (SELECT COUNT(*) FROM dbo.Users u WHERE u.RoleID = r.RoleID)
  FROM dbo.Roles r
  ORDER BY r.RoleName;
END
GO

-- sp_SaveRole and sp_DeleteRole are defined further down (in the
-- item-level rights section) so they can also keep NavItemRoles in sync.

-- ============================================================
--  RIGHTS  (nav-group visibility per role)
-- ============================================================

-- One row per nav group, with the section it belongs to, ordered for display.
CREATE OR ALTER PROCEDURE dbo.sp_GetNavGroups
AS
BEGIN
  SELECT g.GroupID,
         g.GroupName,
         SectionName = ISNULL(s.SectionName, '(Top level)'),
         g.SortOrder
  FROM dbo.NavGroups g
  LEFT JOIN dbo.NavSections s ON g.SectionID = s.SectionID
  WHERE g.IsActive = 1
  ORDER BY g.SortOrder, g.GroupName;
END
GO

-- The current GroupID <-> RoleName grants (excluding the 'All' wildcard,
-- which is managed via seed data, not the per-role matrix).
CREATE OR ALTER PROCEDURE dbo.sp_GetNavGroupRoles
AS
BEGIN
  SELECT GroupID, RoleName FROM dbo.NavGroupRoles WHERE RoleName <> 'All';
END
GO

-- Replace the full set of group grants for a single role.
-- @GroupIDs is a comma-separated list of GroupIDs the role may see.
CREATE OR ALTER PROCEDURE dbo.sp_SetRoleNavGroups
  @RoleName NVARCHAR(50),
  @GroupIDs NVARCHAR(MAX) = NULL
AS
BEGIN
  SET NOCOUNT ON;

  -- Wipe this role's existing (non-wildcard) grants, then re-add the selected set.
  DELETE FROM dbo.NavGroupRoles WHERE RoleName = @RoleName;

  IF @GroupIDs IS NOT NULL AND LTRIM(RTRIM(@GroupIDs)) <> ''
  BEGIN
    INSERT INTO dbo.NavGroupRoles (GroupID, RoleName)
    SELECT DISTINCT TRY_CONVERT(INT, LTRIM(RTRIM(value))), @RoleName
    FROM STRING_SPLIT(@GroupIDs, ',')
    WHERE TRY_CONVERT(INT, LTRIM(RTRIM(value))) IS NOT NULL
      AND EXISTS (SELECT 1 FROM dbo.NavGroups g
                  WHERE g.GroupID = TRY_CONVERT(INT, LTRIM(RTRIM(value))));
  END
END
GO

-- ============================================================
--  ITEM-LEVEL RIGHTS  (per nav sub-item visibility per role)
--
--  Model: "inherit unless overridden".
--    * An item with NO rows in NavItemRoles is visible whenever its
--      parent group is visible to the role (the original behaviour).
--    * As soon as an item has at least one NavItemRoles row, it becomes
--      restricted: only the listed roles (or 'All') can see it.
-- ============================================================

IF OBJECT_ID('dbo.NavItemRoles', 'U') IS NULL
BEGIN
  CREATE TABLE dbo.NavItemRoles (
    ID       INT          IDENTITY(1,1) PRIMARY KEY,
    ItemID   INT          NOT NULL,
    RoleName NVARCHAR(50) NOT NULL,
    CONSTRAINT FK_NavItemRoles_Items FOREIGN KEY (ItemID) REFERENCES dbo.NavItems(ItemID),
    CONSTRAINT UQ_NavItemRoles UNIQUE (ItemID, RoleName)
  );
END
GO

-- Rebuild the nav fetch so Result Set 3 (items) honours item-level rights.
-- An item is returned when its group is visible AND either:
--   (a) it has no NavItemRoles rows at all (inherit from group), OR
--   (b) it has a row for this role or for 'All'.
CREATE OR ALTER PROCEDURE dbo.sp_GetNavMenuByRole
    @RoleName NVARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;

    -- Result Set 1: Sections that have at least one visible group for this role
    SELECT DISTINCT s.SectionID, s.SectionName, s.SortOrder
    FROM   dbo.NavSections s
    INNER JOIN dbo.NavGroups     g   ON g.SectionID = s.SectionID AND g.IsActive = 1
    INNER JOIN dbo.NavGroupRoles ngr ON ngr.GroupID  = g.GroupID
    WHERE  s.IsActive = 1
      AND (ngr.RoleName = @RoleName OR ngr.RoleName = 'All')
    ORDER BY s.SortOrder;

    -- Result Set 2: Distinct groups visible to this role, in display order
    SELECT DISTINCT
           g.GroupID, g.SectionID, g.GroupName, g.IconClass,
           g.Url, g.CollapseId, g.SortOrder
    FROM   dbo.NavGroups     g
    INNER JOIN dbo.NavGroupRoles ngr ON ngr.GroupID = g.GroupID
    WHERE  g.IsActive = 1
      AND (ngr.RoleName = @RoleName OR ngr.RoleName = 'All')
    ORDER BY g.SortOrder;

    -- Result Set 3: Items for visible groups, with item-level rights applied
    SELECT DISTINCT
           i.ItemID, i.GroupID, i.ItemName, i.Url,
           i.SortOrder, i.BadgeText, i.BadgeClass
    FROM   dbo.NavItems      i
    INNER JOIN dbo.NavGroups     g   ON g.GroupID   = i.GroupID  AND g.IsActive = 1
    INNER JOIN dbo.NavGroupRoles ngr ON ngr.GroupID  = g.GroupID
    WHERE  i.IsActive = 1
      AND (ngr.RoleName = @RoleName OR ngr.RoleName = 'All')
      AND (
            -- (a) no item-level restriction: inherit group visibility
            NOT EXISTS (SELECT 1 FROM dbo.NavItemRoles nir WHERE nir.ItemID = i.ItemID)
            -- (b) restricted, but granted to this role (or everyone)
            OR EXISTS (SELECT 1 FROM dbo.NavItemRoles nir
                       WHERE nir.ItemID = i.ItemID
                         AND (nir.RoleName = @RoleName OR nir.RoleName = 'All'))
          )
    ORDER BY i.GroupID, i.SortOrder;
END
GO

-- All active items with their parent group, for the rights matrix.
CREATE OR ALTER PROCEDURE dbo.sp_GetNavItems
AS
BEGIN
  SELECT i.ItemID, i.GroupID, i.ItemName, i.SortOrder
  FROM dbo.NavItems i
  INNER JOIN dbo.NavGroups g ON g.GroupID = i.GroupID AND g.IsActive = 1
  WHERE i.IsActive = 1
  ORDER BY i.GroupID, i.SortOrder;
END
GO

-- Current ItemID <-> RoleName grants (excluding the 'All' wildcard).
CREATE OR ALTER PROCEDURE dbo.sp_GetNavItemRoles
AS
BEGIN
  SELECT ItemID, RoleName FROM dbo.NavItemRoles WHERE RoleName <> 'All';
END
GO

-- Replace the explicit item grants for a single role.
--   @GrantItemIDs   = items this role IS allowed to see (checked boxes).
--   @ScopeItemIDs   = the full set of items the page evaluated for this role —
--                     i.e. every item belonging to a group the role can see.
--                     Items in scope but NOT granted are the ones being hidden.
--
-- Inherit-unless-overridden semantics: an item is "restricted" once it has ANY
-- NavItemRoles row; thereafter every role needs an explicit grant to see it.
-- When this call newly restricts an item (because the role hides a sibling in
-- the same group), we backfill explicit grants for the OTHER roles that can see
-- that item today, so one role's restriction never silently hides it elsewhere.
--
-- An item is only restricted when at least one of its in-scope siblings is hidden;
-- groups where the role keeps every page stay on pure inheritance (no rows added).
CREATE OR ALTER PROCEDURE dbo.sp_SetRoleNavItems
  @RoleName     NVARCHAR(50),
  @GrantItemIDs NVARCHAR(MAX) = NULL,
  @ScopeItemIDs NVARCHAR(MAX) = NULL
AS
BEGIN
  SET NOCOUNT ON;

  DECLARE @grant TABLE (ItemID INT PRIMARY KEY);
  DECLARE @scope TABLE (ItemID INT PRIMARY KEY);

  IF @GrantItemIDs IS NOT NULL AND LTRIM(RTRIM(@GrantItemIDs)) <> ''
    INSERT INTO @grant (ItemID)
    SELECT DISTINCT TRY_CONVERT(INT, LTRIM(RTRIM(value)))
    FROM STRING_SPLIT(@GrantItemIDs, ',')
    WHERE TRY_CONVERT(INT, LTRIM(RTRIM(value))) IS NOT NULL;

  IF @ScopeItemIDs IS NOT NULL AND LTRIM(RTRIM(@ScopeItemIDs)) <> ''
    INSERT INTO @scope (ItemID)
    SELECT DISTINCT TRY_CONVERT(INT, LTRIM(RTRIM(value)))
    FROM STRING_SPLIT(@ScopeItemIDs, ',')
    WHERE TRY_CONVERT(INT, LTRIM(RTRIM(value))) IS NOT NULL;

  BEGIN TRAN;

  -- "To restrict" = in-scope items that are NOT granted to this role,
  -- PLUS their visible siblings (same group). Restricting an item means every
  -- role that should keep it needs an explicit row. We compute the affected
  -- groups (those with at least one hidden in-scope item) and restrict ALL their
  -- in-scope items.
  DECLARE @affectedGroups TABLE (GroupID INT PRIMARY KEY);
  INSERT INTO @affectedGroups (GroupID)
  SELECT DISTINCT i.GroupID
  FROM @scope s
  INNER JOIN dbo.NavItems i ON i.ItemID = s.ItemID
  WHERE NOT EXISTS (SELECT 1 FROM @grant g WHERE g.ItemID = s.ItemID);

  -- Backfill OTHER roles for every in-scope item in an affected group that is
  -- currently unrestricted, snapshotting today's group-based visibility.
  INSERT INTO dbo.NavItemRoles (ItemID, RoleName)
  SELECT DISTINCT i.ItemID, ngr.RoleName
  FROM @scope s
  INNER JOIN dbo.NavItems i        ON i.ItemID = s.ItemID
  INNER JOIN @affectedGroups ag    ON ag.GroupID = i.GroupID
  INNER JOIN dbo.NavGroupRoles ngr ON ngr.GroupID = i.GroupID
  WHERE ngr.RoleName <> @RoleName
    AND NOT EXISTS (SELECT 1 FROM dbo.NavItemRoles nir WHERE nir.ItemID = i.ItemID)   -- only items not yet restricted
    AND NOT EXISTS (SELECT 1 FROM dbo.NavItemRoles x
                    WHERE x.ItemID = i.ItemID AND x.RoleName = ngr.RoleName);

  -- Replace this role's own explicit grants. Only grant items that are actually
  -- restricted (already carry rows from another role, e.g. the backfill above) —
  -- an item nobody has restricted stays on pure inheritance, so adding a lone row
  -- for this role would wrongly hide it from every other role.
  DELETE FROM dbo.NavItemRoles WHERE RoleName = @RoleName;

  INSERT INTO dbo.NavItemRoles (ItemID, RoleName)
  SELECT g.ItemID, @RoleName
  FROM @grant g
  WHERE EXISTS (SELECT 1 FROM dbo.NavItems i WHERE i.ItemID = g.ItemID)
    AND EXISTS (SELECT 1 FROM dbo.NavItemRoles nir WHERE nir.ItemID = g.ItemID);

  -- Cleanup: any item that no longer has a "hidden for someone" reason can drop
  -- back to inheritance. An item is safe to fully clear only when EVERY role that
  -- can see its group also has a grant (i.e. nobody is excluded) — in that case
  -- the explicit rows are redundant. Remove rows for such items.
  ;WITH ItemRoleCounts AS (
    SELECT i.ItemID,
           GrantRoles = (SELECT COUNT(DISTINCT nir.RoleName) FROM dbo.NavItemRoles nir WHERE nir.ItemID = i.ItemID),
           GroupRoles = (SELECT COUNT(DISTINCT ngr.RoleName) FROM dbo.NavGroupRoles ngr WHERE ngr.GroupID = i.GroupID)
    FROM dbo.NavItems i
  )
  DELETE nir
  FROM dbo.NavItemRoles nir
  INNER JOIN ItemRoleCounts c ON c.ItemID = nir.ItemID
  WHERE c.GrantRoles >= c.GroupRoles;   -- nobody excluded → redundant, revert to inherit

  COMMIT TRAN;
END
GO

-- Keep item grants in sync when a role is renamed.
-- (sp_SaveRole already syncs NavGroupRoles; extend it to NavItemRoles too.)
CREATE OR ALTER PROCEDURE dbo.sp_SaveRole
  @RoleID   INT OUTPUT,
  @RoleName NVARCHAR(50)
AS
BEGIN
  SET NOCOUNT ON;

  IF EXISTS (SELECT 1 FROM dbo.Roles
             WHERE RoleName = @RoleName AND RoleID <> ISNULL(@RoleID, 0))
  BEGIN
    RAISERROR('A role with that name already exists.', 16, 1);
    RETURN;
  END

  IF ISNULL(@RoleID, 0) = 0
  BEGIN
    INSERT INTO dbo.Roles (RoleName) VALUES (@RoleName);
    SET @RoleID = SCOPE_IDENTITY();
  END
  ELSE
  BEGIN
    DECLARE @OldName NVARCHAR(50) = (SELECT RoleName FROM dbo.Roles WHERE RoleID = @RoleID);

    UPDATE dbo.Roles SET RoleName = @RoleName WHERE RoleID = @RoleID;

    IF @OldName IS NOT NULL AND @OldName <> @RoleName
    BEGIN
      UPDATE dbo.NavGroupRoles SET RoleName = @RoleName WHERE RoleName = @OldName;
      UPDATE dbo.NavItemRoles  SET RoleName = @RoleName WHERE RoleName = @OldName;
    END
  END
END
GO

-- Extend role delete to also clear its item grants.
CREATE OR ALTER PROCEDURE dbo.sp_DeleteRole
  @RoleID INT
AS
BEGIN
  SET NOCOUNT ON;

  IF EXISTS (SELECT 1 FROM dbo.Users WHERE RoleID = @RoleID)
  BEGIN
    RAISERROR('This role is assigned to one or more users and cannot be deleted.', 16, 1);
    RETURN;
  END

  DECLARE @RoleName NVARCHAR(50) = (SELECT RoleName FROM dbo.Roles WHERE RoleID = @RoleID);

  DELETE FROM dbo.NavItemRoles  WHERE RoleName = @RoleName;
  DELETE FROM dbo.NavGroupRoles WHERE RoleName = @RoleName;
  DELETE FROM dbo.Roles WHERE RoleID = @RoleID;
END
GO

-- ============================================================
--  NAV ITEM: "Roles & Rights" under the Admin Panel group
--  Idempotent — safe on databases already seeded before this page existed.
-- ============================================================
IF NOT EXISTS (SELECT 1 FROM dbo.NavItems WHERE Url = '~/Admin/Roles.aspx')
BEGIN
  DECLARE @grpAdmin INT =
    (SELECT TOP 1 GroupID FROM dbo.NavGroups WHERE GroupName = 'Admin Panel' ORDER BY GroupID);

  IF @grpAdmin IS NOT NULL
  BEGIN
    -- Place it right after "Users"; bump anything at/after that slot down by one.
    DECLARE @usersOrder INT =
      (SELECT TOP 1 SortOrder FROM dbo.NavItems
       WHERE GroupID = @grpAdmin AND Url = '~/Admin/Users.aspx');

    IF @usersOrder IS NULL SET @usersOrder = 1;

    UPDATE dbo.NavItems
    SET SortOrder = SortOrder + 1
    WHERE GroupID = @grpAdmin AND SortOrder > @usersOrder;

    INSERT INTO dbo.NavItems (GroupID, ItemName, Url, SortOrder)
    VALUES (@grpAdmin, 'Roles & Rights', '~/Admin/Roles.aspx', @usersOrder + 1);
  END
END
GO

-- ============================================================
--  PAGE ACCESS  (authorize a page load against nav rights)
--
--  Single source of truth: a role may open a page when the nav system
--  would show it that page. Two cases:
--    * the URL is a GROUP direct link  -> NavGroupRoles decides.
--    * the URL is a nav ITEM           -> group must be visible AND the
--      item-level rights allow it (inherit-unless-overridden).
--  'All' grants apply to everyone. @CanAccess is 1/0.
--
--  URLs are compared by their tail (e.g. 'reports/printinvoice.aspx') so a
--  stored '~/Reports/PrintInvoice.aspx' matches the page's app-relative path.
-- ============================================================
CREATE OR ALTER PROCEDURE dbo.sp_CanRoleAccessUrl
  @RoleName  NVARCHAR(50),
  @Url       NVARCHAR(500),
  @CanAccess BIT OUTPUT
AS
BEGIN
  SET NOCOUNT ON;
  SET @CanAccess = 0;

  -- Normalise: strip leading ~ and /, lowercase. Compare on the trailing path.
  DECLARE @needle NVARCHAR(500) = LOWER(LTRIM(RTRIM(@Url)));
  WHILE LEFT(@needle, 1) IN ('~', '/') SET @needle = SUBSTRING(@needle, 2, 4000);

  -- 1) Group direct-link match (e.g. Dashboard, Analytics, Print Invoice)
  IF EXISTS (
        SELECT 1
        FROM dbo.NavGroups g
        INNER JOIN dbo.NavGroupRoles ngr ON ngr.GroupID = g.GroupID
        WHERE g.IsActive = 1
          AND g.Url IS NOT NULL
          AND @needle = REPLACE(LOWER(LTRIM(RTRIM(g.Url))), '~/', '')
          AND (ngr.RoleName = @RoleName OR ngr.RoleName = 'All')
     )
  BEGIN
    SET @CanAccess = 1;
    RETURN;
  END

  -- 2) Nav item match — group visible AND item rights allow (inherit-unless-overridden)
  IF EXISTS (
        SELECT 1
        FROM dbo.NavItems i
        INNER JOIN dbo.NavGroups     g   ON g.GroupID  = i.GroupID AND g.IsActive = 1
        INNER JOIN dbo.NavGroupRoles ngr ON ngr.GroupID = g.GroupID
        WHERE i.IsActive = 1
          AND @needle = REPLACE(LOWER(LTRIM(RTRIM(i.Url))), '~/', '')
          AND (ngr.RoleName = @RoleName OR ngr.RoleName = 'All')
          AND (
                NOT EXISTS (SELECT 1 FROM dbo.NavItemRoles nir WHERE nir.ItemID = i.ItemID)
                OR EXISTS (SELECT 1 FROM dbo.NavItemRoles nir
                           WHERE nir.ItemID = i.ItemID
                             AND (nir.RoleName = @RoleName OR nir.RoleName = 'All'))
              )
     )
  BEGIN
    SET @CanAccess = 1;
    RETURN;
  END
END
GO

-- Returns >0 when the URL is registered in the nav (as a group link or item),
-- regardless of role. Lets the app tell "denied" apart from "not nav-gated".
CREATE OR ALTER PROCEDURE dbo.sp_UrlExistsInNav
  @Url NVARCHAR(500)
AS
BEGIN
  SET NOCOUNT ON;

  DECLARE @needle NVARCHAR(500) = LOWER(LTRIM(RTRIM(@Url)));
  WHILE LEFT(@needle, 1) IN ('~', '/') SET @needle = SUBSTRING(@needle, 2, 4000);

  SELECT COUNT(*) AS HitCount
  FROM (
    SELECT REPLACE(LOWER(LTRIM(RTRIM(Url))), '~/', '') AS U
    FROM dbo.NavGroups WHERE Url IS NOT NULL AND IsActive = 1
    UNION ALL
    SELECT REPLACE(LOWER(LTRIM(RTRIM(Url))), '~/', '') AS U
    FROM dbo.NavItems WHERE IsActive = 1
  ) x
  WHERE x.U = @needle;
END
GO

PRINT 'Users management + Roles & Rights procedures created successfully.';
GO
