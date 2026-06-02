/*
  OMS - Restaurant Management System
  Deals feature: table + stored procedures, and nav wiring.
  Run AFTER DatabaseSetup.sql and NavMenuSetup.sql.

  A "Deal" is a standalone promotional offer (percentage off, flat amount off,
  or a fixed bundle price) with an active window. Distinct from Offers/Coupons.
*/

SET NOCOUNT ON;
GO

-- ============================================================
--  TABLE
-- ============================================================
IF OBJECT_ID('dbo.Deals', 'U') IS NULL
BEGIN
  CREATE TABLE dbo.Deals (
    DealID        INT IDENTITY(1,1) PRIMARY KEY,
    Title         NVARCHAR(150) NOT NULL,
    Description   NVARCHAR(500) NULL,
    DealType      NVARCHAR(20)  NOT NULL,            -- 'Percentage' | 'Flat' | 'BundlePrice'
    DiscountValue DECIMAL(10,2) NOT NULL DEFAULT 0,  -- % or flat amount (0 for BundlePrice)
    DealPrice     DECIMAL(10,2) NULL,                -- fixed price when DealType = 'BundlePrice'
    StartDate     DATE NOT NULL,
    EndDate       DATE NOT NULL,
    IsActive      BIT  NOT NULL DEFAULT 1,
    CreatedAt     DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME()
  );
END
GO

-- Menu items included in a deal. A deal may bundle available AND unavailable
-- items, so there is no availability constraint here.
IF OBJECT_ID('dbo.DealItems', 'U') IS NULL
BEGIN
  CREATE TABLE dbo.DealItems (
    DealID INT NOT NULL,
    ItemID INT NOT NULL,
    CONSTRAINT PK_DealItems PRIMARY KEY (DealID, ItemID),
    CONSTRAINT FK_DealItems_Deals     FOREIGN KEY (DealID) REFERENCES dbo.Deals(DealID)     ON DELETE CASCADE,
    CONSTRAINT FK_DealItems_MenuItems FOREIGN KEY (ItemID) REFERENCES dbo.MenuItems(ItemID)
  );
END
GO

-- ============================================================
--  STORED PROCEDURES
-- ============================================================

CREATE OR ALTER PROCEDURE dbo.sp_GetDeals
  @IsActive BIT = NULL
AS
BEGIN
  SELECT DealID, Title, Description, DealType, DiscountValue, DealPrice,
         StartDate, EndDate, IsActive, CreatedAt
  FROM dbo.Deals
  WHERE (@IsActive IS NULL OR IsActive = @IsActive)
  ORDER BY StartDate DESC, DealID DESC;
END
GO

CREATE OR ALTER PROCEDURE dbo.sp_GetDealByID
  @DealID INT
AS
BEGIN
  SELECT DealID, Title, Description, DealType, DiscountValue, DealPrice,
         StartDate, EndDate, IsActive, CreatedAt
  FROM dbo.Deals
  WHERE DealID = @DealID;
END
GO

-- Insert when @DealID = 0/NULL, otherwise update.
-- @ItemIDs = comma-separated MenuItems.ItemID list to include in the deal
-- (available and/or unavailable). The deal's item set is fully replaced.
CREATE OR ALTER PROCEDURE dbo.sp_SaveDeal
  @DealID        INT OUTPUT,
  @Title         NVARCHAR(150),
  @Description   NVARCHAR(500) = NULL,
  @DealType      NVARCHAR(20),
  @DiscountValue DECIMAL(10,2) = 0,
  @DealPrice     DECIMAL(10,2) = NULL,
  @StartDate     DATE,
  @EndDate       DATE,
  @IsActive      BIT,
  @ItemIDs       NVARCHAR(MAX) = NULL
AS
BEGIN
  SET NOCOUNT ON;

  IF @EndDate < @StartDate
  BEGIN
    RAISERROR('End date cannot be earlier than start date.', 16, 1);
    RETURN;
  END

  BEGIN TRAN;

  IF ISNULL(@DealID, 0) = 0
  BEGIN
    INSERT INTO dbo.Deals (Title, Description, DealType, DiscountValue, DealPrice, StartDate, EndDate, IsActive)
    VALUES (@Title, @Description, @DealType, @DiscountValue, @DealPrice, @StartDate, @EndDate, @IsActive);
    SET @DealID = SCOPE_IDENTITY();
  END
  ELSE
  BEGIN
    UPDATE dbo.Deals
    SET Title = @Title, Description = @Description, DealType = @DealType,
        DiscountValue = @DiscountValue, DealPrice = @DealPrice,
        StartDate = @StartDate, EndDate = @EndDate, IsActive = @IsActive
    WHERE DealID = @DealID;
  END

  -- Replace the deal's menu-item set.
  DELETE FROM dbo.DealItems WHERE DealID = @DealID;

  IF @ItemIDs IS NOT NULL AND LTRIM(RTRIM(@ItemIDs)) <> ''
  BEGIN
    INSERT INTO dbo.DealItems (DealID, ItemID)
    SELECT DISTINCT @DealID, TRY_CONVERT(INT, LTRIM(RTRIM(value)))
    FROM STRING_SPLIT(@ItemIDs, ',')
    WHERE TRY_CONVERT(INT, LTRIM(RTRIM(value))) IS NOT NULL
      AND EXISTS (SELECT 1 FROM dbo.MenuItems mi
                  WHERE mi.ItemID = TRY_CONVERT(INT, LTRIM(RTRIM(value))));
  END

  COMMIT TRAN;
END
GO

-- All menu items (available AND unavailable) for the deal item picker.
CREATE OR ALTER PROCEDURE dbo.sp_GetMenuItemsForDeal
AS
BEGIN
  SELECT mi.ItemID, mi.Name AS ItemName, mi.IsAvailable,
         c.CategoryID, c.Name AS CategoryName, c.DisplayOrder
  FROM dbo.MenuItems mi
  INNER JOIN dbo.Categories c ON mi.CategoryID = c.CategoryID
  ORDER BY c.DisplayOrder, c.Name, mi.Name;
END
GO

-- The ItemIDs currently attached to a deal (for edit mode pre-selection).
CREATE OR ALTER PROCEDURE dbo.sp_GetDealItems
  @DealID INT
AS
BEGIN
  SELECT ItemID FROM dbo.DealItems WHERE DealID = @DealID;
END
GO

-- Hard delete a deal (no order history references it).
CREATE OR ALTER PROCEDURE dbo.sp_DeleteDeal
  @DealID INT
AS
BEGIN
  DELETE FROM dbo.Deals WHERE DealID = @DealID;
END
GO

CREATE OR ALTER PROCEDURE dbo.sp_ToggleDealStatus
  @DealID INT
AS
BEGIN
  UPDATE dbo.Deals SET IsActive = 1 - IsActive WHERE DealID = @DealID;
  SELECT IsActive FROM dbo.Deals WHERE DealID = @DealID;
END
GO

-- Active deals (IsActive and within their date window) for the New Order screen,
-- plus a second result set of each deal's items with current base prices.
CREATE OR ALTER PROCEDURE dbo.sp_GetActiveDealsWithItems
AS
BEGIN
  SET NOCOUNT ON;
  DECLARE @today DATE = CAST(SYSUTCDATETIME() AS DATE);

  -- Result set 1: the deals
  SELECT d.DealID, d.Title, d.Description, d.DealType, d.DiscountValue, d.DealPrice
  FROM dbo.Deals d
  WHERE d.IsActive = 1
    AND d.StartDate <= @today
    AND d.EndDate   >= @today
    AND EXISTS (SELECT 1 FROM dbo.DealItems di WHERE di.DealID = d.DealID)
  ORDER BY d.Title;

  -- Result set 2: their items (base prices included)
  SELECT di.DealID, di.ItemID, mi.Name AS ItemName, mi.BasePrice
  FROM dbo.DealItems di
  INNER JOIN dbo.Deals d     ON d.DealID = di.DealID
  INNER JOIN dbo.MenuItems mi ON mi.ItemID = di.ItemID
  WHERE d.IsActive = 1
    AND d.StartDate <= @today
    AND d.EndDate   >= @today
  ORDER BY di.DealID, mi.Name;
END
GO

-- ============================================================
--  NAV WIRING
--  Repurpose the "Offers & Coupons" group as "Deals" with two items:
--  Create Deals + Deals List. Idempotent.
-- ============================================================
DECLARE @grpDeals INT =
  (SELECT TOP 1 GroupID FROM dbo.NavGroups
   WHERE GroupName IN ('Offers & Coupons', 'Deals') ORDER BY GroupID);

IF @grpDeals IS NOT NULL
BEGIN
  UPDATE dbo.NavGroups SET GroupName = 'Deals' WHERE GroupID = @grpDeals;

  -- Remove the old Offers/Coupons items (and any item-level rights on them).
  DELETE nir FROM dbo.NavItemRoles nir
    INNER JOIN dbo.NavItems i ON i.ItemID = nir.ItemID
    WHERE i.GroupID = @grpDeals
      AND i.Url IN ('~/Offers/OfferList.aspx', '~/Offers/ManageCoupons.aspx');
  DELETE FROM dbo.NavItems
    WHERE GroupID = @grpDeals
      AND Url IN ('~/Offers/OfferList.aspx', '~/Offers/ManageCoupons.aspx');

  IF NOT EXISTS (SELECT 1 FROM dbo.NavItems WHERE Url = '~/Deals/CreateDeals.aspx')
    INSERT INTO dbo.NavItems (GroupID, ItemName, Url, SortOrder)
    VALUES (@grpDeals, 'Create Deals', '~/Deals/CreateDeals.aspx', 1);

  IF NOT EXISTS (SELECT 1 FROM dbo.NavItems WHERE Url = '~/Deals/DealsList.aspx')
    INSERT INTO dbo.NavItems (GroupID, ItemName, Url, SortOrder)
    VALUES (@grpDeals, 'Deals List', '~/Deals/DealsList.aspx', 2);
END
GO

PRINT 'Deals table, procedures and nav items created successfully.';
GO
