/*
  Restaurant Management System (RMS)
  Run once against a SQL Server database, then update Web.config connection string.
*/

SET NOCOUNT ON;
GO

IF OBJECT_ID('dbo.ErrorLog', 'U') IS NULL
BEGIN
  CREATE TABLE dbo.ErrorLog (
    ErrorID INT IDENTITY(1,1) PRIMARY KEY,
    Message NVARCHAR(4000) NOT NULL,
    StackTrace NVARCHAR(MAX) NULL,
    Url NVARCHAR(500) NULL,
    IPAddress NVARCHAR(50) NULL,
    CreatedAt DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME()
  );
END
GO

IF OBJECT_ID('dbo.Roles', 'U') IS NULL
BEGIN
  CREATE TABLE dbo.Roles (
    RoleID INT IDENTITY(1,1) PRIMARY KEY,
    RoleName NVARCHAR(50) NOT NULL UNIQUE
  );
END
GO

IF OBJECT_ID('dbo.Users', 'U') IS NULL
BEGIN
  CREATE TABLE dbo.Users (
    UserID INT IDENTITY(1,1) PRIMARY KEY,
    FullName NVARCHAR(120) NOT NULL,
    Email NVARCHAR(150) NOT NULL UNIQUE,
    PasswordHash NVARCHAR(256) NOT NULL,
    RoleID INT NOT NULL,
    IsActive BIT NOT NULL DEFAULT 1,
    FailedLoginAttempts INT NOT NULL DEFAULT 0,
    LockoutUntil DATETIME2 NULL,
    CreatedAt DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    CONSTRAINT FK_Users_Roles FOREIGN KEY (RoleID) REFERENCES dbo.Roles(RoleID)
  );
END
GO

IF OBJECT_ID('dbo.Categories', 'U') IS NULL
BEGIN
  CREATE TABLE dbo.Categories (
    CategoryID INT IDENTITY(1,1) PRIMARY KEY,
    Name NVARCHAR(80) NOT NULL,
    DisplayOrder INT NOT NULL DEFAULT 0,
    IsActive BIT NOT NULL DEFAULT 1
  );
END
GO

IF OBJECT_ID('dbo.MenuItems', 'U') IS NULL
BEGIN
  CREATE TABLE dbo.MenuItems (
    ItemID INT IDENTITY(1,1) PRIMARY KEY,
    CategoryID INT NOT NULL,
    Name NVARCHAR(120) NOT NULL,
    Description NVARCHAR(500) NULL,
    BasePrice DECIMAL(10,2) NOT NULL,
    ImagePath NVARCHAR(300) NULL,
    IsAvailable BIT NOT NULL DEFAULT 1,
    IsFeatured BIT NOT NULL DEFAULT 0,
    CreatedAt DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    CONSTRAINT FK_MenuItems_Categories FOREIGN KEY (CategoryID) REFERENCES dbo.Categories(CategoryID)
  );
END
GO

IF OBJECT_ID('dbo.Sizes', 'U') IS NULL
BEGIN
  CREATE TABLE dbo.Sizes (
    SizeID INT IDENTITY(1,1) PRIMARY KEY,
    SizeName NVARCHAR(20) NOT NULL,
    PriceMultiplier DECIMAL(10,2) NOT NULL DEFAULT 1
  );
END
GO

IF OBJECT_ID('dbo.ItemSizePricing', 'U') IS NULL
BEGIN
  CREATE TABLE dbo.ItemSizePricing (
    ID INT IDENTITY(1,1) PRIMARY KEY,
    ItemID INT NOT NULL,
    SizeID INT NOT NULL,
    CustomPrice DECIMAL(10,2) NULL,
    CONSTRAINT FK_ItemSizePricing_MenuItems FOREIGN KEY (ItemID) REFERENCES dbo.MenuItems(ItemID),
    CONSTRAINT FK_ItemSizePricing_Sizes FOREIGN KEY (SizeID) REFERENCES dbo.Sizes(SizeID),
    CONSTRAINT UQ_ItemSizePricing UNIQUE (ItemID, SizeID)
  );
END
GO

IF OBJECT_ID('dbo.Toppings', 'U') IS NULL
BEGIN
  CREATE TABLE dbo.Toppings (
    ToppingID INT IDENTITY(1,1) PRIMARY KEY,
    Name NVARCHAR(80) NOT NULL,
    ExtraCharge DECIMAL(10,2) NOT NULL,
    IsAvailable BIT NOT NULL DEFAULT 1
  );
END
GO

IF OBJECT_ID('dbo.Offers', 'U') IS NULL
BEGIN
  CREATE TABLE dbo.Offers (
    OfferID INT IDENTITY(1,1) PRIMARY KEY,
    Title NVARCHAR(150) NOT NULL,
    Description NVARCHAR(500) NULL,
    DiscountType NVARCHAR(20) NOT NULL,
    DiscountValue DECIMAL(10,2) NOT NULL,
    StartDate DATE NOT NULL,
    EndDate DATE NOT NULL,
    IsActive BIT NOT NULL DEFAULT 1,
    ImagePath NVARCHAR(300) NULL
  );
END
GO

IF OBJECT_ID('dbo.Coupons', 'U') IS NULL
BEGIN
  CREATE TABLE dbo.Coupons (
    CouponID INT IDENTITY(1,1) PRIMARY KEY,
    Code NVARCHAR(30) NOT NULL UNIQUE,
    Description NVARCHAR(300) NULL,
    DiscountType NVARCHAR(20) NOT NULL,
    DiscountValue DECIMAL(10,2) NOT NULL,
    MinOrderValue DECIMAL(10,2) NOT NULL DEFAULT 0,
    MaxUses INT NOT NULL DEFAULT 0,
    UsedCount INT NOT NULL DEFAULT 0,
    ExpiryDate DATE NOT NULL,
    IsActive BIT NOT NULL DEFAULT 1
  );
END
GO

IF OBJECT_ID('dbo.Orders', 'U') IS NULL
BEGIN
  CREATE TABLE dbo.Orders (
    OrderID INT IDENTITY(1,1) PRIMARY KEY,
    OrderNumber NVARCHAR(20) NOT NULL UNIQUE,
    CustomerName NVARCHAR(120) NULL,
    CustomerPhone NVARCHAR(30) NULL,
    CustomerAddress NVARCHAR(300) NULL,
    TableNumber NVARCHAR(20) NULL,
    OrderType NVARCHAR(20) NOT NULL,
    Status NVARCHAR(20) NOT NULL DEFAULT 'Pending',
    PaymentMethod NVARCHAR(20) NOT NULL DEFAULT 'Cash',
    PaymentStatus NVARCHAR(20) NOT NULL DEFAULT 'Pending',
    PaymentReference NVARCHAR(80) NULL,
    SubTotal DECIMAL(10,2) NOT NULL DEFAULT 0,
    DiscountAmount DECIMAL(10,2) NOT NULL DEFAULT 0,
    TaxAmount DECIMAL(10,2) NOT NULL DEFAULT 0,
    TotalAmount DECIMAL(10,2) NOT NULL DEFAULT 0,
    CouponID INT NULL,
    Notes NVARCHAR(500) NULL,
    CreatedBy INT NULL,
    CreatedAt DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    UpdatedAt DATETIME2 NULL,
    CONSTRAINT FK_Orders_Coupons FOREIGN KEY (CouponID) REFERENCES dbo.Coupons(CouponID),
    CONSTRAINT FK_Orders_Users FOREIGN KEY (CreatedBy) REFERENCES dbo.Users(UserID)
  );
END
GO

IF OBJECT_ID('dbo.OrderItems', 'U') IS NULL
BEGIN
  CREATE TABLE dbo.OrderItems (
    OrderItemID INT IDENTITY(1,1) PRIMARY KEY,
    OrderID INT NOT NULL,
    ItemID INT NOT NULL,
    SizeID INT NULL,
    Quantity INT NOT NULL,
    UnitPrice DECIMAL(10,2) NOT NULL,
    LineTotal DECIMAL(10,2) NOT NULL,
    SpecialInstructions NVARCHAR(200) NULL,
    CONSTRAINT FK_OrderItems_Orders FOREIGN KEY (OrderID) REFERENCES dbo.Orders(OrderID),
    CONSTRAINT FK_OrderItems_MenuItems FOREIGN KEY (ItemID) REFERENCES dbo.MenuItems(ItemID),
    CONSTRAINT FK_OrderItems_Sizes FOREIGN KEY (SizeID) REFERENCES dbo.Sizes(SizeID)
  );
END
GO

IF OBJECT_ID('dbo.OrderItemToppings', 'U') IS NULL
BEGIN
  CREATE TABLE dbo.OrderItemToppings (
    OrderItemID INT NOT NULL,
    ToppingID INT NOT NULL,
    ExtraCharge DECIMAL(10,2) NOT NULL,
    CONSTRAINT PK_OrderItemToppings PRIMARY KEY (OrderItemID, ToppingID),
    CONSTRAINT FK_OrderItemToppings_OrderItems FOREIGN KEY (OrderItemID) REFERENCES dbo.OrderItems(OrderItemID),
    CONSTRAINT FK_OrderItemToppings_Toppings FOREIGN KEY (ToppingID) REFERENCES dbo.Toppings(ToppingID)
  );
END
GO

IF OBJECT_ID('dbo.Messages', 'U') IS NULL
BEGIN
  CREATE TABLE dbo.Messages (
    MessageID INT IDENTITY(1,1) PRIMARY KEY,
    CustomerName NVARCHAR(120) NOT NULL,
    CustomerEmail NVARCHAR(150) NULL,
    CustomerPhone NVARCHAR(30) NULL,
    Subject NVARCHAR(150) NOT NULL,
    Body NVARCHAR(MAX) NOT NULL,
    IsRead BIT NOT NULL DEFAULT 0,
    CreatedAt DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    RepliedAt DATETIME2 NULL,
    ReplyBody NVARCHAR(MAX) NULL
  );
END
GO

IF OBJECT_ID('dbo.ActivityLog', 'U') IS NULL
BEGIN
  CREATE TABLE dbo.ActivityLog (
    LogID INT IDENTITY(1,1) PRIMARY KEY,
    UserID INT NULL,
    Action NVARCHAR(100) NOT NULL,
    Description NVARCHAR(500) NULL,
    IPAddress NVARCHAR(50) NULL,
    CreatedAt DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    CONSTRAINT FK_ActivityLog_Users FOREIGN KEY (UserID) REFERENCES dbo.Users(UserID)
  );
END
GO

IF OBJECT_ID('dbo.AppSettings', 'U') IS NULL
BEGIN
  CREATE TABLE dbo.AppSettings (
    SettingKey NVARCHAR(80) NOT NULL PRIMARY KEY,
    SettingValue NVARCHAR(500) NOT NULL,
    UpdatedAt DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME()
  );
END
GO

CREATE INDEX IX_Orders_CreatedAt ON dbo.Orders(CreatedAt);
CREATE INDEX IX_Orders_Status ON dbo.Orders(Status);
CREATE INDEX IX_OrderItems_ItemID ON dbo.OrderItems(ItemID);
GO

IF NOT EXISTS (SELECT 1 FROM dbo.Roles)
BEGIN
  SET IDENTITY_INSERT dbo.Roles ON;
  INSERT INTO dbo.Roles (RoleID, RoleName) VALUES (1,'Admin'),(2,'Manager'),(3,'Cashier'),(4,'Kitchen');
  SET IDENTITY_INSERT dbo.Roles OFF;
END
GO

IF NOT EXISTS (SELECT 1 FROM dbo.Users WHERE Email = 'admin@rms.com')
BEGIN
  SET IDENTITY_INSERT dbo.Users ON;
  INSERT INTO dbo.Users (UserID, FullName, Email, PasswordHash, RoleID, IsActive, CreatedAt)
  VALUES (1, 'System Admin', 'admin@rms.com', '6G94qKPK8LYNjnTllCqm2G3BUM08AzOK7yW30tfjrMc=', 1, 1, SYSUTCDATETIME());
  SET IDENTITY_INSERT dbo.Users OFF;
END
GO

IF NOT EXISTS (SELECT 1 FROM dbo.Categories)
BEGIN
  SET IDENTITY_INSERT dbo.Categories ON;
  INSERT INTO dbo.Categories (CategoryID, Name, DisplayOrder, IsActive)
  VALUES (1,'Pizzas',1,1),(2,'Sides',2,1),(3,'Drinks',3,1),(4,'Desserts',4,1),(5,'Combos',5,1);
  SET IDENTITY_INSERT dbo.Categories OFF;
END
GO

IF NOT EXISTS (SELECT 1 FROM dbo.Sizes)
BEGIN
  SET IDENTITY_INSERT dbo.Sizes ON;
  INSERT INTO dbo.Sizes (SizeID, SizeName, PriceMultiplier)
  VALUES (1,'Small',1.00),(2,'Medium',1.30),(3,'Large',1.60),(4,'XL',2.00);
  SET IDENTITY_INSERT dbo.Sizes OFF;
END
GO

IF NOT EXISTS (SELECT 1 FROM dbo.Toppings)
BEGIN
  SET IDENTITY_INSERT dbo.Toppings ON;
  INSERT INTO dbo.Toppings (ToppingID, Name, ExtraCharge, IsAvailable)
  VALUES (1,'Extra Cheese',50,1),(2,'Mushrooms',40,1),(3,'Olives',35,1),(4,'Jalapenos',30,1),(5,'Chicken',80,1);
  SET IDENTITY_INSERT dbo.Toppings OFF;
END
GO

IF NOT EXISTS (SELECT 1 FROM dbo.MenuItems)
BEGIN
  SET IDENTITY_INSERT dbo.MenuItems ON;
  INSERT INTO dbo.MenuItems (ItemID, CategoryID, Name, Description, BasePrice, ImagePath, IsAvailable, IsFeatured, CreatedAt)
  VALUES
    (1,1,'Margherita','Classic tomato and mozzarella',599,NULL,1,1,SYSUTCDATETIME()),
    (2,1,'BBQ Chicken','Smoky BBQ with grilled chicken',799,NULL,1,1,SYSUTCDATETIME()),
    (3,1,'Veggie Supreme','Garden-fresh vegetables',699,NULL,1,0,SYSUTCDATETIME()),
    (4,2,'Garlic Bread','Toasted garlic bread',249,NULL,1,0,SYSUTCDATETIME()),
    (5,3,'Soft Drink','Chilled soft drink',120,NULL,1,0,SYSUTCDATETIME());
  SET IDENTITY_INSERT dbo.MenuItems OFF;
END
GO

IF NOT EXISTS (SELECT 1 FROM dbo.AppSettings WHERE SettingKey = 'TaxPercent')
  INSERT INTO dbo.AppSettings (SettingKey, SettingValue) VALUES ('TaxPercent', '16');
GO

CREATE OR ALTER PROCEDURE dbo.sp_LogActivity
  @UserID INT = NULL,
  @Action NVARCHAR(100),
  @Description NVARCHAR(500) = NULL,
  @IPAddress NVARCHAR(50) = NULL
AS
BEGIN
  INSERT INTO dbo.ActivityLog (UserID, Action, Description, IPAddress)
  VALUES (@UserID, @Action, @Description, @IPAddress);
END
GO

CREATE OR ALTER PROCEDURE dbo.sp_LogError
  @Message NVARCHAR(4000),
  @StackTrace NVARCHAR(MAX) = NULL,
  @Url NVARCHAR(500) = NULL,
  @IPAddress NVARCHAR(50) = NULL
AS
BEGIN
  INSERT INTO dbo.ErrorLog (Message, StackTrace, Url, IPAddress)
  VALUES (@Message, @StackTrace, @Url, @IPAddress);
END
GO

CREATE OR ALTER PROCEDURE dbo.sp_GetUserByEmail
  @Email NVARCHAR(150)
AS
BEGIN
  SELECT u.UserID, u.FullName, u.Email, u.PasswordHash, u.IsActive, u.FailedLoginAttempts,
         u.LockoutUntil, r.RoleID, r.RoleName
  FROM dbo.Users u
  INNER JOIN dbo.Roles r ON u.RoleID = r.RoleID
  WHERE u.Email = @Email;
END
GO

CREATE OR ALTER PROCEDURE dbo.sp_RecordLoginResult
  @UserID INT,
  @Succeeded BIT
AS
BEGIN
  IF @Succeeded = 1
    UPDATE dbo.Users SET FailedLoginAttempts = 0, LockoutUntil = NULL WHERE UserID = @UserID;
  ELSE
    UPDATE dbo.Users
    SET FailedLoginAttempts = FailedLoginAttempts + 1,
        LockoutUntil = CASE WHEN FailedLoginAttempts + 1 >= 5 THEN DATEADD(MINUTE, 15, SYSUTCDATETIME()) ELSE LockoutUntil END
    WHERE UserID = @UserID;
END
GO

CREATE OR ALTER PROCEDURE dbo.sp_GetDashboardSummary
  @Date DATE
AS
BEGIN
  DECLARE @Start DATETIME2 = @Date;
  DECLARE @End DATETIME2 = DATEADD(DAY, 1, @Start);
  DECLARE @YesterdayStart DATETIME2 = DATEADD(DAY, -1, @Start);

  SELECT
    TodayOrders = COUNT(CASE WHEN CreatedAt >= @Start AND CreatedAt < @End THEN 1 END),
    YesterdayOrders = COUNT(CASE WHEN CreatedAt >= @YesterdayStart AND CreatedAt < @Start THEN 1 END),
    TodayRevenue = ISNULL(SUM(CASE WHEN CreatedAt >= @Start AND CreatedAt < @End AND PaymentStatus = 'Paid' THEN TotalAmount END), 0),
    PendingOrders = COUNT(CASE WHEN Status = 'Pending' THEN 1 END)
  FROM dbo.Orders;

  SELECT TOP 1 mi.Name, SUM(oi.Quantity) AS OrderCount
  FROM dbo.OrderItems oi
  INNER JOIN dbo.MenuItems mi ON oi.ItemID = mi.ItemID
  INNER JOIN dbo.Orders o ON oi.OrderID = o.OrderID
  WHERE o.CreatedAt >= DATEADD(DAY, -7, @End)
  GROUP BY mi.Name
  ORDER BY SUM(oi.Quantity) DESC;
END
GO

CREATE OR ALTER PROCEDURE dbo.sp_GetRevenueByDay
  @StartDate DATE,
  @EndDate DATE
AS
BEGIN
  SELECT CAST(CreatedAt AS DATE) AS SaleDate, ISNULL(SUM(TotalAmount), 0) AS Revenue
  FROM dbo.Orders
  WHERE CreatedAt >= @StartDate AND CreatedAt < DATEADD(DAY, 1, @EndDate) AND PaymentStatus = 'Paid'
  GROUP BY CAST(CreatedAt AS DATE)
  ORDER BY SaleDate;
END
GO

CREATE OR ALTER PROCEDURE dbo.sp_GetOrdersByHour
  @Date DATE
AS
BEGIN
  SELECT DATEPART(HOUR, CreatedAt) AS OrderHour, COUNT(*) AS OrderCount
  FROM dbo.Orders
  WHERE CreatedAt >= @Date AND CreatedAt < DATEADD(DAY, 1, @Date)
  GROUP BY DATEPART(HOUR, CreatedAt)
  ORDER BY OrderHour;
END
GO

CREATE OR ALTER PROCEDURE dbo.sp_GetTopMenuItems
  @StartDate DATE,
  @EndDate DATE,
  @TopN INT = 5
AS
BEGIN
  SELECT TOP (@TopN) mi.ItemID, mi.Name, SUM(oi.Quantity) AS QuantitySold, SUM(oi.LineTotal) AS Revenue
  FROM dbo.OrderItems oi
  INNER JOIN dbo.MenuItems mi ON oi.ItemID = mi.ItemID
  INNER JOIN dbo.Orders o ON oi.OrderID = o.OrderID
  WHERE o.CreatedAt >= @StartDate AND o.CreatedAt < DATEADD(DAY, 1, @EndDate)
  GROUP BY mi.ItemID, mi.Name
  ORDER BY SUM(oi.Quantity) DESC;
END
GO

CREATE OR ALTER PROCEDURE dbo.sp_GetOrders
  @Status NVARCHAR(20) = NULL,
  @StartDate DATE = NULL,
  @EndDate DATE = NULL,
  @OrderType NVARCHAR(20) = NULL,
  @PaymentMethod NVARCHAR(20) = NULL
AS
BEGIN
  SELECT TOP 500 *
  FROM dbo.Orders
  WHERE (@Status IS NULL OR Status = @Status)
    AND (@OrderType IS NULL OR OrderType = @OrderType)
    AND (@PaymentMethod IS NULL OR PaymentMethod = @PaymentMethod)
    AND (@StartDate IS NULL OR CreatedAt >= @StartDate)
    AND (@EndDate IS NULL OR CreatedAt < DATEADD(DAY, 1, @EndDate))
  ORDER BY CreatedAt DESC;
END
GO

CREATE OR ALTER PROCEDURE dbo.sp_GetOrderByID
  @OrderID INT
AS
BEGIN
  SELECT * FROM dbo.Orders WHERE OrderID = @OrderID;
  SELECT oi.*, mi.Name AS ItemName, s.SizeName
  FROM dbo.OrderItems oi
  INNER JOIN dbo.MenuItems mi ON oi.ItemID = mi.ItemID
  LEFT JOIN dbo.Sizes s ON oi.SizeID = s.SizeID
  WHERE oi.OrderID = @OrderID;
  SELECT oit.*, t.Name
  FROM dbo.OrderItemToppings oit
  INNER JOIN dbo.OrderItems oi ON oit.OrderItemID = oi.OrderItemID
  INNER JOIN dbo.Toppings t ON oit.ToppingID = t.ToppingID
  WHERE oi.OrderID = @OrderID;
END
GO

CREATE OR ALTER PROCEDURE dbo.sp_CreateOrder
  @CustomerName NVARCHAR(120) = NULL,
  @Phone NVARCHAR(30) = NULL,
  @Address NVARCHAR(300) = NULL,
  @TableNumber NVARCHAR(20) = NULL,
  @OrderType NVARCHAR(20),
  @PaymentMethod NVARCHAR(20),
  @PaymentStatus NVARCHAR(20),
  @SubTotal DECIMAL(10,2),
  @DiscountAmount DECIMAL(10,2),
  @TaxAmount DECIMAL(10,2),
  @TotalAmount DECIMAL(10,2),
  @CouponID INT = NULL,
  @Notes NVARCHAR(500) = NULL,
  @CreatedBy INT = NULL,
  @OrderID INT OUTPUT
AS
BEGIN
  DECLARE @Today CHAR(8) = CONVERT(CHAR(8), GETUTCDATE(), 112);
  DECLARE @Next INT = (SELECT COUNT(*) + 1 FROM dbo.Orders WHERE CONVERT(CHAR(8), CreatedAt, 112) = @Today);
  DECLARE @OrderNumber NVARCHAR(20) = CONCAT('ORD-', @Today, '-', RIGHT(CONCAT('0000', @Next), 4));

  INSERT INTO dbo.Orders (OrderNumber, CustomerName, CustomerPhone, CustomerAddress, TableNumber, OrderType, PaymentMethod, PaymentStatus,
                          SubTotal, DiscountAmount, TaxAmount, TotalAmount, CouponID, Notes, CreatedBy)
  VALUES (@OrderNumber, @CustomerName, @Phone, @Address, @TableNumber, @OrderType, @PaymentMethod, @PaymentStatus,
          @SubTotal, @DiscountAmount, @TaxAmount, @TotalAmount, @CouponID, @Notes, @CreatedBy);
  SET @OrderID = SCOPE_IDENTITY();
END
GO

CREATE OR ALTER PROCEDURE dbo.sp_AddOrderItem
  @OrderID INT,
  @ItemID INT,
  @SizeID INT = NULL,
  @Quantity INT,
  @UnitPrice DECIMAL(10,2),
  @Instructions NVARCHAR(200) = NULL,
  @OrderItemID INT OUTPUT
AS
BEGIN
  INSERT INTO dbo.OrderItems (OrderID, ItemID, SizeID, Quantity, UnitPrice, LineTotal, SpecialInstructions)
  VALUES (@OrderID, @ItemID, @SizeID, @Quantity, @UnitPrice, @Quantity * @UnitPrice, @Instructions);
  SET @OrderItemID = SCOPE_IDENTITY();
END
GO

CREATE OR ALTER PROCEDURE dbo.sp_AddOrderItemTopping
  @OrderItemID INT,
  @ToppingID INT,
  @ExtraCharge DECIMAL(10,2)
AS
BEGIN
  INSERT INTO dbo.OrderItemToppings (OrderItemID, ToppingID, ExtraCharge)
  VALUES (@OrderItemID, @ToppingID, @ExtraCharge);
END
GO

CREATE OR ALTER PROCEDURE dbo.sp_UpdateOrderStatus
  @OrderID INT,
  @Status NVARCHAR(20),
  @UpdatedBy INT = NULL
AS
BEGIN
  UPDATE dbo.Orders SET Status = @Status, UpdatedAt = SYSUTCDATETIME() WHERE OrderID = @OrderID;
  EXEC dbo.sp_LogActivity @UpdatedBy, 'UpdateOrderStatus', @Status, NULL;
END
GO

CREATE OR ALTER PROCEDURE dbo.sp_CancelOrder
  @OrderID INT,
  @CancelledBy INT = NULL,
  @Reason NVARCHAR(500) = NULL
AS
BEGIN
  UPDATE dbo.Orders SET Status = 'Cancelled', Notes = CONCAT(ISNULL(Notes + CHAR(13) + CHAR(10), ''), 'Cancel reason: ', @Reason), UpdatedAt = SYSUTCDATETIME()
  WHERE OrderID = @OrderID;
  EXEC dbo.sp_LogActivity @CancelledBy, 'CancelOrder', @Reason, NULL;
END
GO

CREATE OR ALTER PROCEDURE dbo.sp_GetMenuItems
  @CategoryID INT = NULL,
  @IsAvailable BIT = NULL
AS
BEGIN
  SELECT mi.*, c.Name AS CategoryName
  FROM dbo.MenuItems mi
  INNER JOIN dbo.Categories c ON mi.CategoryID = c.CategoryID
  WHERE (@CategoryID IS NULL OR mi.CategoryID = @CategoryID)
    AND (@IsAvailable IS NULL OR mi.IsAvailable = @IsAvailable)
  ORDER BY c.DisplayOrder, mi.Name;
END
GO

CREATE OR ALTER PROCEDURE dbo.sp_GetMenuItemByID
  @ItemID INT
AS
BEGIN
  SELECT * FROM dbo.MenuItems WHERE ItemID = @ItemID;
END
GO

CREATE OR ALTER PROCEDURE dbo.sp_SaveMenuItem
  @ItemID INT OUTPUT,
  @CategoryID INT,
  @Name NVARCHAR(120),
  @Description NVARCHAR(500) = NULL,
  @BasePrice DECIMAL(10,2),
  @ImagePath NVARCHAR(300) = NULL,
  @IsAvailable BIT,
  @IsFeatured BIT = 0
AS
BEGIN
  IF ISNULL(@ItemID, 0) = 0
  BEGIN
    INSERT INTO dbo.MenuItems (CategoryID, Name, Description, BasePrice, ImagePath, IsAvailable, IsFeatured)
    VALUES (@CategoryID, @Name, @Description, @BasePrice, @ImagePath, @IsAvailable, @IsFeatured);
    SET @ItemID = SCOPE_IDENTITY();
  END
  ELSE
  BEGIN
    UPDATE dbo.MenuItems
    SET CategoryID = @CategoryID, Name = @Name, Description = @Description, BasePrice = @BasePrice,
        ImagePath = COALESCE(@ImagePath, ImagePath), IsAvailable = @IsAvailable, IsFeatured = @IsFeatured
    WHERE ItemID = @ItemID;
  END
END
GO

CREATE OR ALTER PROCEDURE dbo.sp_DeleteMenuItem
  @ItemID INT
AS
BEGIN
  UPDATE dbo.MenuItems SET IsAvailable = 0 WHERE ItemID = @ItemID;
END
GO

CREATE OR ALTER PROCEDURE dbo.sp_GetSizePricingMatrix
AS
BEGIN
  SELECT mi.ItemID, mi.Name AS ItemName, s.SizeID, s.SizeName,
         CalculatedPrice = CAST(mi.BasePrice * s.PriceMultiplier AS DECIMAL(10,2)),
         isp.CustomPrice,
         EffectivePrice = COALESCE(isp.CustomPrice, CAST(mi.BasePrice * s.PriceMultiplier AS DECIMAL(10,2)))
  FROM dbo.MenuItems mi
  CROSS JOIN dbo.Sizes s
  LEFT JOIN dbo.ItemSizePricing isp ON mi.ItemID = isp.ItemID AND s.SizeID = isp.SizeID
  ORDER BY mi.Name, s.SizeID;
END
GO

CREATE OR ALTER PROCEDURE dbo.sp_SaveSizePricing
  @ItemID INT,
  @SizeID INT,
  @CustomPrice DECIMAL(10,2) = NULL
AS
BEGIN
  MERGE dbo.ItemSizePricing AS target
  USING (SELECT @ItemID AS ItemID, @SizeID AS SizeID) AS src
  ON target.ItemID = src.ItemID AND target.SizeID = src.SizeID
  WHEN MATCHED THEN UPDATE SET CustomPrice = @CustomPrice
  WHEN NOT MATCHED THEN INSERT (ItemID, SizeID, CustomPrice) VALUES (@ItemID, @SizeID, @CustomPrice);
END
GO

CREATE OR ALTER PROCEDURE dbo.sp_GetToppings
AS
BEGIN
  SELECT * FROM dbo.Toppings ORDER BY Name;
END
GO

CREATE OR ALTER PROCEDURE dbo.sp_SaveTopping
  @ToppingID INT OUTPUT,
  @Name NVARCHAR(80),
  @ExtraCharge DECIMAL(10,2),
  @IsAvailable BIT
AS
BEGIN
  IF ISNULL(@ToppingID, 0) = 0
  BEGIN
    INSERT INTO dbo.Toppings (Name, ExtraCharge, IsAvailable) VALUES (@Name, @ExtraCharge, @IsAvailable);
    SET @ToppingID = SCOPE_IDENTITY();
  END
  ELSE
    UPDATE dbo.Toppings SET Name = @Name, ExtraCharge = @ExtraCharge, IsAvailable = @IsAvailable WHERE ToppingID = @ToppingID;
END
GO

CREATE OR ALTER PROCEDURE dbo.sp_GetOffers
  @IsActive BIT = NULL
AS
BEGIN
  SELECT * FROM dbo.Offers WHERE (@IsActive IS NULL OR IsActive = @IsActive) ORDER BY StartDate DESC;
END
GO

CREATE OR ALTER PROCEDURE dbo.sp_SaveOffer
  @OfferID INT OUTPUT,
  @Title NVARCHAR(150),
  @Description NVARCHAR(500) = NULL,
  @DiscountType NVARCHAR(20),
  @DiscountValue DECIMAL(10,2),
  @StartDate DATE,
  @EndDate DATE,
  @IsActive BIT,
  @ImagePath NVARCHAR(300) = NULL
AS
BEGIN
  IF ISNULL(@OfferID, 0) = 0
  BEGIN
    INSERT INTO dbo.Offers (Title, Description, DiscountType, DiscountValue, StartDate, EndDate, IsActive, ImagePath)
    VALUES (@Title, @Description, @DiscountType, @DiscountValue, @StartDate, @EndDate, @IsActive, @ImagePath);
    SET @OfferID = SCOPE_IDENTITY();
  END
  ELSE
    UPDATE dbo.Offers SET Title = @Title, Description = @Description, DiscountType = @DiscountType, DiscountValue = @DiscountValue,
      StartDate = @StartDate, EndDate = @EndDate, IsActive = @IsActive, ImagePath = COALESCE(@ImagePath, ImagePath)
    WHERE OfferID = @OfferID;
END
GO

CREATE OR ALTER PROCEDURE dbo.sp_GetCoupons
AS
BEGIN
  SELECT * FROM dbo.Coupons ORDER BY ExpiryDate DESC;
END
GO

CREATE OR ALTER PROCEDURE dbo.sp_ValidateCoupon
  @Code NVARCHAR(30),
  @OrderAmount DECIMAL(10,2),
  @DiscountAmount DECIMAL(10,2) OUTPUT,
  @CouponID INT OUTPUT
AS
BEGIN
  SET @DiscountAmount = 0;
  SET @CouponID = NULL;

  SELECT TOP 1 @CouponID = CouponID,
    @DiscountAmount = CASE WHEN DiscountType = 'Percentage' THEN (@OrderAmount * DiscountValue / 100.0) ELSE DiscountValue END
  FROM dbo.Coupons
  WHERE Code = @Code AND IsActive = 1 AND ExpiryDate >= CAST(GETUTCDATE() AS DATE)
    AND @OrderAmount >= MinOrderValue AND (MaxUses = 0 OR UsedCount < MaxUses);
END
GO

CREATE OR ALTER PROCEDURE dbo.sp_IncrementCouponUsage
  @CouponID INT
AS
BEGIN
  UPDATE dbo.Coupons SET UsedCount = UsedCount + 1 WHERE CouponID = @CouponID;
END
GO

CREATE OR ALTER PROCEDURE dbo.sp_GetSalesAnalytics
  @StartDate DATE,
  @EndDate DATE,
  @GroupBy NVARCHAR(20) = 'Day'
AS
BEGIN
  SELECT CAST(CreatedAt AS DATE) AS Period, COUNT(*) AS Orders, SUM(TotalAmount) AS Revenue, AVG(TotalAmount) AS AverageOrderValue
  FROM dbo.Orders
  WHERE CreatedAt >= @StartDate AND CreatedAt < DATEADD(DAY, 1, @EndDate)
  GROUP BY CAST(CreatedAt AS DATE)
  ORDER BY Period;
END
GO

CREATE OR ALTER PROCEDURE dbo.sp_GetPaymentAnalytics
  @StartDate DATE,
  @EndDate DATE
AS
BEGIN
  SELECT PaymentMethod, COUNT(*) AS Orders, SUM(TotalAmount) AS Revenue
  FROM dbo.Orders
  WHERE CreatedAt >= @StartDate AND CreatedAt < DATEADD(DAY, 1, @EndDate)
  GROUP BY PaymentMethod;
END
GO

CREATE OR ALTER PROCEDURE dbo.sp_GetMenuAnalytics
  @StartDate DATE,
  @EndDate DATE
AS
BEGIN
  SELECT mi.Name, SUM(oi.Quantity) AS QuantitySold, SUM(oi.LineTotal) AS Revenue
  FROM dbo.OrderItems oi
  INNER JOIN dbo.MenuItems mi ON oi.ItemID = mi.ItemID
  INNER JOIN dbo.Orders o ON oi.OrderID = o.OrderID
  WHERE o.CreatedAt >= @StartDate AND o.CreatedAt < DATEADD(DAY, 1, @EndDate)
  GROUP BY mi.Name
  ORDER BY Revenue DESC;
END
GO

CREATE OR ALTER PROCEDURE dbo.sp_GetMessages
  @IsRead BIT = NULL
AS
BEGIN
  SELECT * FROM dbo.Messages WHERE (@IsRead IS NULL OR IsRead = @IsRead) ORDER BY CreatedAt DESC;
END
GO

CREATE OR ALTER PROCEDURE dbo.sp_SaveMessage
  @Name NVARCHAR(120),
  @Email NVARCHAR(150) = NULL,
  @Phone NVARCHAR(30) = NULL,
  @Subject NVARCHAR(150),
  @Body NVARCHAR(MAX)
AS
BEGIN
  INSERT INTO dbo.Messages (CustomerName, CustomerEmail, CustomerPhone, Subject, Body)
  VALUES (@Name, @Email, @Phone, @Subject, @Body);
END
GO

CREATE OR ALTER PROCEDURE dbo.sp_ReplyMessage
  @MessageID INT,
  @ReplyBody NVARCHAR(MAX),
  @RepliedBy INT = NULL
AS
BEGIN
  UPDATE dbo.Messages SET IsRead = 1, RepliedAt = SYSUTCDATETIME(), ReplyBody = @ReplyBody WHERE MessageID = @MessageID;
  EXEC dbo.sp_LogActivity @RepliedBy, 'ReplyMessage', @ReplyBody, NULL;
END
GO
