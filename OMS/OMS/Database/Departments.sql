/*
  OMS - Departments module.
  Admin creates departments; menu categories are created under a department and staff can be assigned to one.
  Idempotent: safe to run more than once. Run AFTER DatabaseSetup.sql, UsersRolesSetup.sql and OrderWorkflow.sql.
*/
SET NOCOUNT ON;
SET QUOTED_IDENTIFIER ON;
GO

-- ============================================================
--  1. SCHEMA
-- ============================================================
IF OBJECT_ID('dbo.Departments', 'U') IS NULL
BEGIN
  CREATE TABLE dbo.Departments (
    DepartmentID INT IDENTITY(1,1) PRIMARY KEY,
    Name         NVARCHAR(80)  NOT NULL,
    Description  NVARCHAR(250) NULL,
    DisplayOrder INT NOT NULL CONSTRAINT DF_Departments_Order DEFAULT 0,
    IsActive     BIT NOT NULL CONSTRAINT DF_Departments_Active DEFAULT 1,
    CreatedAt    DATETIME2 NOT NULL CONSTRAINT DF_Departments_Created DEFAULT SYSUTCDATETIME(),
    CreatedBy    INT NULL
  );
  CREATE UNIQUE INDEX UX_Departments_Name ON dbo.Departments (Name);
END
GO

-- Existing categories / users stay valid (NULL = not assigned yet).
IF COL_LENGTH('dbo.Categories', 'DepartmentID') IS NULL
  ALTER TABLE dbo.Categories ADD DepartmentID INT NULL;
IF COL_LENGTH('dbo.Users', 'DepartmentID') IS NULL
  ALTER TABLE dbo.Users ADD DepartmentID INT NULL;
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_Categories_Department')
  ALTER TABLE dbo.Categories ADD CONSTRAINT FK_Categories_Department FOREIGN KEY (DepartmentID) REFERENCES dbo.Departments (DepartmentID);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_Users_Department')
  ALTER TABLE dbo.Users ADD CONSTRAINT FK_Users_Department FOREIGN KEY (DepartmentID) REFERENCES dbo.Departments (DepartmentID);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Categories_Department' AND object_id = OBJECT_ID('dbo.Categories'))
  CREATE INDEX IX_Categories_Department ON dbo.Categories (DepartmentID);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Users_Department' AND object_id = OBJECT_ID('dbo.Users'))
  CREATE INDEX IX_Users_Department ON dbo.Users (DepartmentID);
GO

-- ============================================================
--  2. DEPARTMENTS (CRUD)
-- ============================================================
CREATE OR ALTER PROCEDURE dbo.sp_GetDepartments
  @ActiveOnly BIT = 0
AS
BEGIN
  SET NOCOUNT ON;
  SELECT d.DepartmentID, d.Name AS DepartmentName, d.Description, d.DisplayOrder, d.IsActive, d.CreatedAt,
         CategoryCount = (SELECT COUNT(*) FROM dbo.Categories c WHERE c.DepartmentID = d.DepartmentID),
         UserCount     = (SELECT COUNT(*) FROM dbo.Users u WHERE u.DepartmentID = d.DepartmentID)
  FROM dbo.Departments d
  WHERE @ActiveOnly = 0 OR d.IsActive = 1
  ORDER BY d.DisplayOrder, d.Name;
END
GO

-- Insert when @DepartmentID = 0/NULL, otherwise update.
CREATE OR ALTER PROCEDURE dbo.sp_SaveDepartment
  @DepartmentID INT OUTPUT,
  @Name         NVARCHAR(80),
  @Description  NVARCHAR(250) = NULL,
  @DisplayOrder INT = 0,
  @IsActive     BIT = 1,
  @CreatedBy    INT = NULL
AS
BEGIN
  SET NOCOUNT ON;
  SET @Name = LTRIM(RTRIM(@Name));

  IF @Name = ''
  BEGIN
    RAISERROR('Department name is required.', 16, 1);
    RETURN;
  END

  IF EXISTS (SELECT 1 FROM dbo.Departments WHERE Name = @Name AND DepartmentID <> ISNULL(@DepartmentID, 0))
  BEGIN
    RAISERROR('A department with that name already exists.', 16, 1);
    RETURN;
  END

  IF ISNULL(@DepartmentID, 0) = 0
  BEGIN
    INSERT INTO dbo.Departments (Name, Description, DisplayOrder, IsActive, CreatedBy)
    VALUES (@Name, NULLIF(LTRIM(RTRIM(@Description)), ''), @DisplayOrder, @IsActive, @CreatedBy);
    SET @DepartmentID = SCOPE_IDENTITY();
  END
  ELSE
  BEGIN
    UPDATE dbo.Departments
    SET Name = @Name, Description = NULLIF(LTRIM(RTRIM(@Description)), ''), DisplayOrder = @DisplayOrder, IsActive = @IsActive
    WHERE DepartmentID = @DepartmentID;
  END
END
GO

-- Hard delete only while nothing uses the department; otherwise the caller deactivates instead.
CREATE OR ALTER PROCEDURE dbo.sp_DeleteDepartment
  @DepartmentID INT
AS
BEGIN
  SET NOCOUNT ON;

  IF EXISTS (SELECT 1 FROM dbo.Categories WHERE DepartmentID = @DepartmentID)
  BEGIN
    RAISERROR('This department still has menu categories. Move or remove them first, or deactivate the department.', 16, 1);
    RETURN;
  END
  IF EXISTS (SELECT 1 FROM dbo.Users WHERE DepartmentID = @DepartmentID)
  BEGIN
    RAISERROR('Staff are still assigned to this department. Reassign them first, or deactivate the department.', 16, 1);
    RETURN;
  END

  DELETE FROM dbo.Departments WHERE DepartmentID = @DepartmentID;
END
GO

-- ============================================================
--  3. CATEGORIES: created under a department
-- ============================================================
CREATE OR ALTER PROCEDURE dbo.sp_GetAllCategories
AS
BEGIN
  SELECT c.CategoryID,
         c.Name AS CategoryName,
         c.DisplayOrder,
         c.IsActive,
         c.DepartmentID,
         DepartmentName = d.Name,
         ItemCount = (SELECT COUNT(*) FROM dbo.MenuItems mi WHERE mi.CategoryID = c.CategoryID)
  FROM dbo.Categories c
  LEFT JOIN dbo.Departments d ON d.DepartmentID = c.DepartmentID
  ORDER BY d.DisplayOrder, d.Name, c.DisplayOrder, c.Name;
END
GO

CREATE OR ALTER PROCEDURE dbo.sp_SaveCategory
  @CategoryID   INT OUTPUT,
  @Name         NVARCHAR(80),
  @DisplayOrder INT = 0,
  @IsActive     BIT = 1,
  @DepartmentID INT = NULL
AS
BEGIN
  SET NOCOUNT ON;

  IF @DepartmentID IS NOT NULL AND NOT EXISTS (SELECT 1 FROM dbo.Departments WHERE DepartmentID = @DepartmentID)
  BEGIN
    RAISERROR('That department no longer exists.', 16, 1);
    RETURN;
  END

  IF ISNULL(@CategoryID, 0) = 0
  BEGIN
    INSERT INTO dbo.Categories (Name, DisplayOrder, IsActive, DepartmentID)
    VALUES (@Name, @DisplayOrder, @IsActive, @DepartmentID);
    SET @CategoryID = SCOPE_IDENTITY();
  END
  ELSE
  BEGIN
    UPDATE dbo.Categories
    SET Name = @Name, DisplayOrder = @DisplayOrder, IsActive = @IsActive, DepartmentID = @DepartmentID
    WHERE CategoryID = @CategoryID;
  END
END
GO

-- ============================================================
--  3b. KITCHEN: each dish carries its category's department
--      (OrderWorkflow.sql defines the base version; run this file after it)
-- ============================================================
CREATE OR ALTER PROCEDURE dbo.sp_GetKitchenItems
AS
BEGIN
  SET NOCOUNT ON;
  SELECT oi.OrderItemID, oi.OrderID, o.OrderNumber, o.TableNumber, o.OrderType,
         ItemName = mi.Name, oi.Quantity, s.SizeName, oi.SpecialInstructions,
         c.CategoryID, CategoryName = c.Name,
         DepartmentID = ISNULL(c.DepartmentID, 0), DepartmentName = ISNULL(d.Name, 'Unassigned'),
         AgeSeconds = DATEDIFF(SECOND, o.CreatedAt, SYSUTCDATETIME())
  FROM dbo.OrderItems oi
  INNER JOIN dbo.Orders o     ON o.OrderID = oi.OrderID
  INNER JOIN dbo.MenuItems mi ON mi.ItemID = oi.ItemID
  INNER JOIN dbo.Categories c ON c.CategoryID = mi.CategoryID
  LEFT JOIN dbo.Departments d ON d.DepartmentID = c.DepartmentID
  LEFT JOIN dbo.Sizes s       ON s.SizeID = oi.SizeID
  WHERE oi.KitchenStatus = 'Preparing' AND o.Status <> 'Cancelled'
  ORDER BY o.CreatedAt, oi.OrderItemID;
END
GO

-- ============================================================
--  4. USERS: optional department
-- ============================================================
CREATE OR ALTER PROCEDURE dbo.sp_GetAllUsers
AS
BEGIN
  SELECT u.UserID, u.FullName, u.Email, u.RoleID, r.RoleName, u.IsActive, u.CreatedAt,
         u.DepartmentID, DepartmentName = d.Name
  FROM dbo.Users u
  INNER JOIN dbo.Roles r ON u.RoleID = r.RoleID
  LEFT JOIN dbo.Departments d ON d.DepartmentID = u.DepartmentID
  ORDER BY u.CreatedAt DESC;
END
GO

CREATE OR ALTER PROCEDURE dbo.sp_GetUserByID
  @UserID INT
AS
BEGIN
  SELECT u.UserID, u.FullName, u.Email, u.RoleID, r.RoleName, u.IsActive, u.CreatedAt,
         u.DepartmentID, DepartmentName = d.Name
  FROM dbo.Users u
  INNER JOIN dbo.Roles r ON u.RoleID = r.RoleID
  LEFT JOIN dbo.Departments d ON d.DepartmentID = u.DepartmentID
  WHERE u.UserID = @UserID;
END
GO

CREATE OR ALTER PROCEDURE dbo.sp_SaveUser
  @UserID       INT OUTPUT,
  @FullName     NVARCHAR(120),
  @Email        NVARCHAR(150),
  @PasswordHash NVARCHAR(256) = NULL,
  @RoleID       INT,
  @IsActive     BIT,
  @DepartmentID INT = NULL
AS
BEGIN
  SET NOCOUNT ON;

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

    INSERT INTO dbo.Users (FullName, Email, PasswordHash, RoleID, IsActive, DepartmentID)
    VALUES (@FullName, @Email, @PasswordHash, @RoleID, @IsActive, @DepartmentID);
    SET @UserID = SCOPE_IDENTITY();
  END
  ELSE
  BEGIN
    UPDATE dbo.Users
    SET FullName     = @FullName,
        Email        = @Email,
        PasswordHash = COALESCE(@PasswordHash, PasswordHash),
        RoleID       = @RoleID,
        IsActive     = @IsActive,
        DepartmentID = @DepartmentID
    WHERE UserID = @UserID;
  END
END
GO

-- ============================================================
--  5. NAVIGATION: "Departments" under Admin Panel (inherits the group's roles, like Settings)
-- ============================================================
IF NOT EXISTS (SELECT 1 FROM dbo.NavItems WHERE Url = '~/Admin/Departments.aspx')
BEGIN
  DECLARE @grpAdmin INT = (SELECT TOP 1 GroupID FROM dbo.NavGroups WHERE GroupName = 'Admin Panel' ORDER BY GroupID);
  IF @grpAdmin IS NOT NULL
    INSERT INTO dbo.NavItems (GroupID, ItemName, Url, SortOrder)
    VALUES (@grpAdmin, 'Departments', '~/Admin/Departments.aspx',
            ISNULL((SELECT MAX(SortOrder) FROM dbo.NavItems WHERE GroupID = @grpAdmin), 0) + 1);
END
GO

PRINT 'Departments module applied.';
GO
