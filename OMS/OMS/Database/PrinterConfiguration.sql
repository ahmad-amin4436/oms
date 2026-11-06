/*
  OMS - Department printer configuration.
  Run AFTER Departments.sql and the navigation/roles setup scripts.
  Permissions remain database-driven through NavGroupRoles/NavItemRoles.
*/
SET NOCOUNT ON;
SET QUOTED_IDENTIFIER ON;
GO

-- ============================================================
-- 1. PRINTER CONFIGURATION ON THE EXISTING DEPARTMENTS TABLE
-- ============================================================
IF COL_LENGTH('dbo.Departments', 'PrinterIP') IS NULL
  ALTER TABLE dbo.Departments ADD PrinterIP NVARCHAR(255) NULL;
IF COL_LENGTH('dbo.Departments', 'PrinterName') IS NULL
  ALTER TABLE dbo.Departments ADD PrinterName NVARCHAR(255) NULL;
IF COL_LENGTH('dbo.Departments', 'PrinterPort') IS NULL
  ALTER TABLE dbo.Departments ADD PrinterPort INT NULL;
IF COL_LENGTH('dbo.Departments', 'PrinterEnabled') IS NULL
  ALTER TABLE dbo.Departments ADD PrinterEnabled BIT NOT NULL CONSTRAINT DF_Departments_PrinterEnabled DEFAULT 0;
IF COL_LENGTH('dbo.Departments', 'LastPrinterTestResult') IS NULL
  ALTER TABLE dbo.Departments ADD LastPrinterTestResult NVARCHAR(500) NULL;
IF COL_LENGTH('dbo.Departments', 'LastPrinterTestAt') IS NULL
  ALTER TABLE dbo.Departments ADD LastPrinterTestAt DATETIME2 NULL;
GO

-- ============================================================
-- 2. PRINTER CONFIGURATION PROCEDURES
-- ============================================================
CREATE OR ALTER PROCEDURE dbo.sp_GetDepartmentPrinterConfigurations
AS
BEGIN
  SET NOCOUNT ON;

  SELECT DepartmentID, DepartmentName = Name, Description, IsActive,
		  PrinterIP, PrinterName, PrinterPort, PrinterEnabled,
		 LastPrinterTestResult, LastPrinterTestAt
  FROM dbo.Departments
  ORDER BY DisplayOrder, Name;
END
GO

CREATE OR ALTER PROCEDURE dbo.sp_SaveDepartmentPrinterConfiguration
  @DepartmentID          INT,
  @PrinterIP             NVARCHAR(255) = NULL,
	@PrinterName           NVARCHAR(255) = NULL,
  @PrinterPort           INT = NULL,
  @PrinterEnabled        BIT = 0
AS
BEGIN
  SET NOCOUNT ON;

  IF NOT EXISTS (SELECT 1 FROM dbo.Departments WHERE DepartmentID = @DepartmentID)
  BEGIN
	RAISERROR('That department no longer exists.', 16, 1);
	RETURN;
  END

  SET @PrinterIP = NULLIF(LTRIM(RTRIM(@PrinterIP)), '');
  SET @PrinterName = NULLIF(LTRIM(RTRIM(@PrinterName)), '');

  IF @PrinterEnabled = 1 AND @PrinterPort IS NULL
	SET @PrinterPort = 9100;

	IF @PrinterEnabled = 1 AND @PrinterIP IS NULL AND @PrinterName IS NULL
  BEGIN
	RAISERROR('Enter a LAN printer IP/host or a Windows printer queue name when the printer is enabled.', 16, 1);
	RETURN;
  END

  IF @PrinterPort IS NOT NULL AND (@PrinterPort < 1 OR @PrinterPort > 65535)
  BEGIN
	RAISERROR('Printer port must be between 1 and 65535.', 16, 1);
	RETURN;
  END

  UPDATE dbo.Departments
  SET PrinterIP = @PrinterIP,
		PrinterName = @PrinterName,
	  PrinterPort = @PrinterPort,
	  PrinterEnabled = @PrinterEnabled
  WHERE DepartmentID = @DepartmentID;
END
GO

-- Intended for the local Windows Service integration. The service can report its
-- result through a future authenticated OMS endpoint without changing the print-feed API.
CREATE OR ALTER PROCEDURE dbo.sp_RecordDepartmentPrinterTest
  @DepartmentID INT,
  @TestResult   NVARCHAR(500),
  @TestedAt     DATETIME2 = NULL
AS
BEGIN
  SET NOCOUNT ON;

  IF NOT EXISTS (SELECT 1 FROM dbo.Departments WHERE DepartmentID = @DepartmentID)
  BEGIN
	RAISERROR('That department no longer exists.', 16, 1);
	RETURN;
  END

  UPDATE dbo.Departments
  SET LastPrinterTestResult = NULLIF(LTRIM(RTRIM(@TestResult)), ''),
	  LastPrinterTestAt = ISNULL(@TestedAt, SYSUTCDATETIME())
  WHERE DepartmentID = @DepartmentID;
END
GO

-- ============================================================
-- 3. NAVIGATION
-- The Admin Panel group is already governed by its database role grants.
-- No role is hardcoded here; Roles.aspx controls who receives this item.
-- ============================================================
IF NOT EXISTS (SELECT 1 FROM dbo.NavItems WHERE Url = '~/Admin/PrinterConfiguration.aspx')
BEGIN
  DECLARE @grpAdmin INT =
	(SELECT TOP 1 GroupID FROM dbo.NavGroups WHERE GroupName = 'Admin Panel' ORDER BY GroupID);

  IF @grpAdmin IS NOT NULL
	INSERT INTO dbo.NavItems (GroupID, ItemName, Url, SortOrder)
	VALUES (@grpAdmin, 'Printer Configuration', '~/Admin/PrinterConfiguration.aspx',
			ISNULL((SELECT MAX(SortOrder) FROM dbo.NavItems WHERE GroupID = @grpAdmin), 0) + 1);
END
GO

PRINT 'Department printer configuration applied.';
GO
