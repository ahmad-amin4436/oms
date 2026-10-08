/*
  OMS - Order workflow: two statuses, payment confirmation, business-day close.
  Run AFTER OrderEnhancements.sql (and AnalyticsFix.sql / DashboardData.sql). Safe to re-run.
  This script owns these procedures from now on - it redefines the versions in earlier scripts:
    sp_CreateOrder, sp_UpdateOrderStatus, sp_CancelOrder, sp_AddOrderItem, sp_GetOrders,
    sp_GetOrderByID, sp_GetItemsSoldCount, sp_GetDashboardSummary, sp_GetTwoMonthDailySales,
    sp_GetDailyOrdersByType, sp_GetRevenueByOrderType, sp_GetRevenueByDay, sp_GetOrdersByHour,
    sp_GetTopMenuItems, sp_GetPaymentAnalytics, sp_GetAnalyticsSummary.
  If an older script is re-run later, re-run this one after it.

  Rules
    Status is Pending (unpaid) or Confirmed (fully paid). Cancelled stays as the admin-only
    "void" action. Only a Cashier/Admin confirms payment (enforced by the app; sp_ConfirmOrder
    records who). Confirming sets PaymentStatus = Paid.
    Sales = Confirmed orders. Cancelled orders are reported separately.
    A business day is opened by the first order after the previous day was closed and stays
    open - across midnight - until a Cashier/Admin closes it. Only one day is open at a time.
    A day cannot be closed while it still has Pending (unpaid) orders.
    Reports group by the order's business date (6 AM local boundary for orders that pre-date
    this feature), not by calendar date.
*/
SET NOCOUNT ON;
SET QUOTED_IDENTIFIER ON;   -- required by the filtered index below (sqlcmd defaults to OFF)
SET ANSI_NULLS ON;
GO

-- ============================================================
--  1. SCHEMA
-- ============================================================

IF OBJECT_ID('dbo.BusinessDays', 'U') IS NULL
BEGIN
  CREATE TABLE dbo.BusinessDays (
    BusinessDayID   INT IDENTITY(1,1) PRIMARY KEY,
    BusinessDate    DATE         NOT NULL,                       -- label of the day (date it was opened, 6 AM local boundary)
    OpenedAt        DATETIME2    NOT NULL DEFAULT SYSUTCDATETIME(),
    OpenedBy        INT          NULL,
    ClosedAt        DATETIME2    NULL,
    ClosedBy        INT          NULL,
    OpenSlot        TINYINT      NULL DEFAULT 1,                 -- 1 while open, NULL once closed
    TotalOrders     INT          NULL,                           -- snapshot at close (non-cancelled)
    SalesAmount     DECIMAL(12,2) NULL,                          -- snapshot at close (Confirmed)
    CancelledOrders INT          NULL,
    CancelledAmount DECIMAL(12,2) NULL,
    Notes           NVARCHAR(200) NULL,
    CONSTRAINT FK_BusinessDays_OpenedBy FOREIGN KEY (OpenedBy) REFERENCES dbo.Users(UserID),
    CONSTRAINT FK_BusinessDays_ClosedBy FOREIGN KEY (ClosedBy) REFERENCES dbo.Users(UserID)
  );
END
GO

-- At most one open business day, enforced by the database.
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'UX_BusinessDays_Open' AND object_id = OBJECT_ID('dbo.BusinessDays'))
  CREATE UNIQUE INDEX UX_BusinessDays_Open ON dbo.BusinessDays (OpenSlot) WHERE OpenSlot IS NOT NULL;
GO

IF COL_LENGTH('dbo.Orders', 'BusinessDayID') IS NULL ALTER TABLE dbo.Orders ADD BusinessDayID INT NULL;
IF COL_LENGTH('dbo.Orders', 'PaidAt')        IS NULL ALTER TABLE dbo.Orders ADD PaidAt DATETIME2 NULL;
IF COL_LENGTH('dbo.Orders', 'ConfirmedBy')   IS NULL ALTER TABLE dbo.Orders ADD ConfirmedBy INT NULL;
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_Orders_BusinessDays')
  ALTER TABLE dbo.Orders ADD CONSTRAINT FK_Orders_BusinessDays FOREIGN KEY (BusinessDayID) REFERENCES dbo.BusinessDays(BusinessDayID);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_Orders_ConfirmedBy')
  ALTER TABLE dbo.Orders ADD CONSTRAINT FK_Orders_ConfirmedBy FOREIGN KEY (ConfirmedBy) REFERENCES dbo.Users(UserID);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Orders_BusinessDay' AND object_id = OBJECT_ID('dbo.Orders'))
  CREATE INDEX IX_Orders_BusinessDay ON dbo.Orders (BusinessDayID, Status) INCLUDE (TotalAmount, CreatedBy, PaymentMethod);
GO

-- ============================================================
--  2. ONE-TIME STATUS MIGRATION  (guarded by a flag, so re-running never remaps again)
--     Delivered            -> Confirmed (paid)
--     Confirmed/Preparing/Ready/Pending -> Pending (unpaid; a Cashier confirms when paid)
--     Cancelled stays Cancelled.
-- ============================================================
IF NOT EXISTS (SELECT 1 FROM dbo.AppSettings WHERE SettingKey = 'StatusMigration2')
BEGIN
  -- Order matters: unpaid first, THEN promote Delivered (otherwise the promoted rows would be
  -- caught by the first rule because they are now called Confirmed).
  UPDATE dbo.Orders SET Status = 'Pending', PaymentStatus = 'Pending'
  WHERE Status IN ('Confirmed', 'Preparing', 'Ready');

  UPDATE dbo.Orders
  SET Status = 'Confirmed', PaymentStatus = 'Paid',
      PaidAt = ISNULL(PaidAt, ISNULL(UpdatedAt, CreatedAt))
  WHERE Status = 'Delivered';

  INSERT INTO dbo.AppSettings (SettingKey, SettingValue) VALUES ('StatusMigration2', 'done');
END
GO

-- ============================================================
--  3. BUSINESS DAY BACKFILL (orders that pre-date this feature)
-- ============================================================
DECLARE @days TABLE (BizDate DATE PRIMARY KEY, FirstAt DATETIME2, LastAt DATETIME2);
INSERT INTO @days
SELECT CAST(DATEADD(HOUR, -1, CreatedAt) AS DATE), MIN(CreatedAt), MAX(CreatedAt)   -- 5h offset - 6h boundary
FROM dbo.Orders WHERE BusinessDayID IS NULL
GROUP BY CAST(DATEADD(HOUR, -1, CreatedAt) AS DATE);

DECLARE @ins TABLE (BusinessDayID INT, BusinessDate DATE);

-- Old days are closed. The newest one stays open only if it is still "live" (an order in the
-- last 12 hours) and nothing is open yet; otherwise the next order opens a fresh day.
INSERT INTO dbo.BusinessDays (BusinessDate, OpenedAt, ClosedAt, OpenSlot, Notes)
OUTPUT inserted.BusinessDayID, inserted.BusinessDate INTO @ins
SELECT d.BizDate, d.FirstAt,
       CASE WHEN d.BizDate = (SELECT MAX(BizDate) FROM @days)
                 AND d.LastAt > DATEADD(HOUR, -12, SYSUTCDATETIME())
                 AND NOT EXISTS (SELECT 1 FROM dbo.BusinessDays WHERE OpenSlot = 1) THEN NULL ELSE d.LastAt END,
       CASE WHEN d.BizDate = (SELECT MAX(BizDate) FROM @days)
                 AND d.LastAt > DATEADD(HOUR, -12, SYSUTCDATETIME())
                 AND NOT EXISTS (SELECT 1 FROM dbo.BusinessDays WHERE OpenSlot = 1) THEN 1 END,
       'Created from existing orders'
FROM @days d ORDER BY d.BizDate;

UPDATE o SET o.BusinessDayID = i.BusinessDayID
FROM dbo.Orders o
INNER JOIN @ins i ON i.BusinessDate = CAST(DATEADD(HOUR, -1, o.CreatedAt) AS DATE)
WHERE o.BusinessDayID IS NULL;

-- Snapshot totals for the days that were just closed.
UPDATE bd SET
  TotalOrders     = x.Ord,
  SalesAmount     = x.Sales,
  CancelledOrders = x.Canc,
  CancelledAmount = x.CancAmt
FROM dbo.BusinessDays bd
INNER JOIN @ins i ON i.BusinessDayID = bd.BusinessDayID
CROSS APPLY (SELECT Ord     = COUNT(CASE WHEN o.Status <> 'Cancelled' THEN 1 END),
                    Sales   = ISNULL(SUM(CASE WHEN o.Status = 'Confirmed' THEN o.TotalAmount END), 0),
                    Canc    = COUNT(CASE WHEN o.Status = 'Cancelled' THEN 1 END),
                    CancAmt = ISNULL(SUM(CASE WHEN o.Status = 'Cancelled' THEN o.TotalAmount END), 0)
             FROM dbo.Orders o WHERE o.BusinessDayID = bd.BusinessDayID) x
WHERE bd.ClosedAt IS NOT NULL;
GO

-- ============================================================
--  4. VIEW: every order with its business date (used by all daily reports)
-- ============================================================
CREATE OR ALTER VIEW dbo.vw_OrdersBiz AS
SELECT o.OrderID, o.OrderNumber, o.Status, o.OrderType, o.PaymentMethod, o.PaymentStatus,
       o.SubTotal, o.DiscountAmount, o.TaxAmount, o.TotalAmount, o.CreatedAt, o.CreatedBy,
       o.BusinessDayID,
       BizDate = ISNULL(bd.BusinessDate, CAST(DATEADD(HOUR, -1, o.CreatedAt) AS DATE))
FROM dbo.Orders o
LEFT JOIN dbo.BusinessDays bd ON bd.BusinessDayID = o.BusinessDayID;
GO

-- ============================================================
--  5. ORDER PROCEDURES
-- ============================================================

-- The order taker is mandatory, and the order joins the open business day (a new day is
-- opened automatically when the previous one was closed).
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
  @OrderID INT OUTPUT,
  @TaxPercent DECIMAL(5,2) = NULL
AS
BEGIN
  SET NOCOUNT ON;
  SET XACT_ABORT ON;

  IF @CreatedBy IS NULL OR NOT EXISTS (SELECT 1 FROM dbo.Users WHERE UserID = @CreatedBy)
    THROW 50020, 'The order taker could not be identified. Please sign in again.', 1;

  BEGIN TRANSACTION;

  DECLARE @Day INT = (SELECT TOP 1 BusinessDayID FROM dbo.BusinessDays WITH (UPDLOCK, HOLDLOCK) WHERE OpenSlot = 1);
  IF @Day IS NULL
  BEGIN
    INSERT INTO dbo.BusinessDays (BusinessDate, OpenedBy)
    VALUES (CAST(DATEADD(HOUR, -1, SYSUTCDATETIME()) AS DATE), @CreatedBy);   -- 6 AM local boundary
    SET @Day = SCOPE_IDENTITY();
  END

  DECLARE @Today CHAR(8) = CONVERT(CHAR(8), GETUTCDATE(), 112);
  DECLARE @Next INT = (SELECT COUNT(*) + 1 FROM dbo.Orders WHERE CONVERT(CHAR(8), CreatedAt, 112) = @Today);
  DECLARE @OrderNumber NVARCHAR(20) = CONCAT('ORD-', @Today, '-', RIGHT(CONCAT('0000', @Next), 4));

  INSERT INTO dbo.Orders (OrderNumber, CustomerName, CustomerPhone, CustomerAddress, TableNumber, OrderType, PaymentMethod,
                          PaymentStatus, Status, SubTotal, DiscountAmount, TaxAmount, TaxPercent, TotalAmount, CouponID, Notes,
                          CreatedBy, BusinessDayID)
  VALUES (@OrderNumber, @CustomerName, @Phone, @Address, @TableNumber, @OrderType, @PaymentMethod,
          'Pending', 'Pending',                      -- every order starts unpaid
          @SubTotal, @DiscountAmount, @TaxAmount, @TaxPercent, @TotalAmount, @CouponID, @Notes,
          @CreatedBy, @Day);
  SET @OrderID = SCOPE_IDENTITY();

  COMMIT TRANSACTION;
END
GO

-- Status now follows payment: it can only change through sp_ConfirmOrder (or cancel).
CREATE OR ALTER PROCEDURE dbo.sp_UpdateOrderStatus
  @OrderID INT,
  @Status NVARCHAR(20),
  @UpdatedBy INT = NULL
AS
BEGIN
  THROW 50030, 'Order status follows payment. Use Confirm Payment (Cashier) or Cancel Order (Admin).', 1;
END
GO

IF OBJECT_ID('dbo.sp_ConfirmOrder', 'P') IS NULL EXEC('CREATE PROCEDURE dbo.sp_ConfirmOrder AS SELECT 1');
GO
-- Pending -> Confirmed (= fully paid). The app only lets a Cashier/Admin call this; the user is
-- recorded. If the customer pays with a different method than the order was taken with, the method
-- is updated and tax is re-priced at @TaxPercent (the rate the app resolved for that method).
ALTER PROCEDURE dbo.sp_ConfirmOrder
  @OrderID INT,
  @ConfirmedBy INT,
  @PaymentMethod NVARCHAR(20) = NULL,
  @TaxPercent DECIMAL(9,4) = NULL
AS
BEGIN
  SET NOCOUNT ON;
  SET XACT_ABORT ON;

  IF @ConfirmedBy IS NULL OR NOT EXISTS (SELECT 1 FROM dbo.Users WHERE UserID = @ConfirmedBy)
    THROW 50021, 'The cashier could not be identified. Please sign in again.', 1;
  IF @PaymentMethod IS NOT NULL AND @PaymentMethod NOT IN ('Cash', 'Card', 'Wallet', 'BankTransfer')
    THROW 50022, 'Unknown payment method.', 1;

  BEGIN TRANSACTION;

  DECLARE @Status NVARCHAR(20), @Method NVARCHAR(20), @Sub DECIMAL(10,2), @Disc DECIMAL(10,2), @Day INT, @DayClosed BIT, @Moved INT = NULL;
  SELECT @Status = o.Status, @Method = o.PaymentMethod, @Sub = o.SubTotal, @Disc = o.DiscountAmount,
         @Day = o.BusinessDayID, @DayClosed = CASE WHEN bd.ClosedAt IS NOT NULL THEN 1 ELSE 0 END
  FROM dbo.Orders o WITH (UPDLOCK, HOLDLOCK)
  LEFT JOIN dbo.BusinessDays bd ON bd.BusinessDayID = o.BusinessDayID
  WHERE o.OrderID = @OrderID;

  IF @Status IS NULL      THROW 50001, 'Order not found.', 1;
  IF @Status = 'Cancelled' THROW 50023, 'A cancelled order cannot be confirmed.', 1;
  IF @Status = 'Confirmed' THROW 50024, 'This order is already confirmed (paid).', 1;
  -- An old unpaid order paid today: the money arrives today, so it joins the OPEN business day
  -- (a new one is opened if none). The closed day it came from is left exactly as it was closed.
  IF @DayClosed = 1
  BEGIN
    DECLARE @Open INT = (SELECT TOP 1 BusinessDayID FROM dbo.BusinessDays WITH (UPDLOCK, HOLDLOCK) WHERE OpenSlot = 1);
    IF @Open IS NULL
    BEGIN
      INSERT INTO dbo.BusinessDays (BusinessDate, OpenedBy)
      VALUES (CAST(DATEADD(HOUR, -1, SYSUTCDATETIME()) AS DATE), @ConfirmedBy);
      SET @Open = SCOPE_IDENTITY();
    END
    UPDATE dbo.Orders SET BusinessDayID = @Open WHERE OrderID = @OrderID;
    SET @Moved = @Day;
  END

  IF @PaymentMethod IS NOT NULL AND @PaymentMethod <> @Method AND @TaxPercent IS NOT NULL
  BEGIN
    DECLARE @Tax DECIMAL(10,2) = ROUND((@Sub - @Disc) * @TaxPercent / 100.0, 2);
    UPDATE dbo.Orders
    SET PaymentMethod = @PaymentMethod, TaxPercent = @TaxPercent, TaxAmount = @Tax,
        TotalAmount = @Sub - @Disc + @Tax
    WHERE OrderID = @OrderID;
  END
  ELSE IF @PaymentMethod IS NOT NULL
    UPDATE dbo.Orders SET PaymentMethod = @PaymentMethod WHERE OrderID = @OrderID;

  UPDATE dbo.Orders
  SET Status = 'Confirmed', PaymentStatus = 'Paid', PaidAt = SYSUTCDATETIME(),
      ConfirmedBy = @ConfirmedBy, UpdatedAt = SYSUTCDATETIME()
  WHERE OrderID = @OrderID;

  DECLARE @Desc NVARCHAR(500) = CONCAT('Order #', @OrderID, ' paid (', ISNULL(@PaymentMethod, @Method), ') - confirmed',
                              CASE WHEN @Moved IS NOT NULL THEN CONCAT(' - settled late, moved from business day #', @Moved) ELSE '' END);
  EXEC dbo.sp_LogActivity @ConfirmedBy, 'ConfirmOrder', @Desc, NULL;

  COMMIT TRANSACTION;
END
GO

-- Cancel: Pending anytime; Confirmed only while its business day is still open (a closed day's
-- sales are final).
CREATE OR ALTER PROCEDURE dbo.sp_CancelOrder
  @OrderID INT,
  @CancelledBy INT = NULL,
  @Reason NVARCHAR(500) = NULL
AS
BEGIN
  DECLARE @Current NVARCHAR(20), @DayClosed BIT;
  SELECT @Current = o.Status, @DayClosed = CASE WHEN bd.ClosedAt IS NOT NULL THEN 1 ELSE 0 END
  FROM dbo.Orders o LEFT JOIN dbo.BusinessDays bd ON bd.BusinessDayID = o.BusinessDayID
  WHERE o.OrderID = @OrderID;

  IF @Current IS NULL
    THROW 50001, 'Order not found.', 1;
  IF @Current = 'Cancelled'
    THROW 50004, 'Order is already cancelled.', 1;
  IF @Current = 'Confirmed' AND @DayClosed = 1
    THROW 50005, 'A paid order from a closed business day cannot be cancelled.', 1;

  UPDATE dbo.Orders
  SET Status = 'Cancelled', CancelledAt = SYSUTCDATETIME(), CancelledBy = @CancelledBy,
      CancelReason = @Reason, UpdatedAt = SYSUTCDATETIME()
  WHERE OrderID = @OrderID;

  DECLARE @Desc NVARCHAR(500) = LEFT(CONCAT('Order #', @OrderID, ' (was ', @Current, '): ', ISNULL(@Reason, 'no reason given')), 500);
  EXEC dbo.sp_LogActivity @CancelledBy, 'CancelOrder', @Desc, NULL;
END
GO

-- Dishes can be added only while the order is Pending (unpaid) and its day is open.
CREATE OR ALTER PROCEDURE dbo.sp_AddOrderItem
  @OrderID  INT,
  @ItemID   INT,
  @Quantity INT,
  @AddedBy  INT = NULL
AS
BEGIN
  SET NOCOUNT ON;
  SET XACT_ABORT ON;

  IF @Quantity IS NULL OR @Quantity < 1 OR @Quantity > 100
    THROW 50010, 'Quantity must be between 1 and 100.', 1;

  BEGIN TRANSACTION;

  DECLARE @Status NVARCHAR(20), @Sub DECIMAL(10,2), @Disc DECIMAL(10,2), @Tax DECIMAL(10,2),
          @Rate DECIMAL(9,4), @ItemName NVARCHAR(120), @Price DECIMAL(10,2), @DayClosed BIT;

  SELECT @Status = o.Status, @Sub = o.SubTotal, @Disc = o.DiscountAmount, @Tax = o.TaxAmount, @Rate = o.TaxPercent,
         @DayClosed = CASE WHEN bd.ClosedAt IS NOT NULL THEN 1 ELSE 0 END
  FROM dbo.Orders o WITH (UPDLOCK, HOLDLOCK)
  LEFT JOIN dbo.BusinessDays bd ON bd.BusinessDayID = o.BusinessDayID
  WHERE o.OrderID = @OrderID;

  IF @Status IS NULL
    THROW 50001, 'Order not found.', 1;
  IF @Status <> 'Pending' OR @DayClosed = 1
    THROW 50011, 'Dishes can only be added while the order is Pending (unpaid). Take a new order instead.', 1;

  SELECT @ItemName = Name, @Price = BasePrice FROM dbo.MenuItems WHERE ItemID = @ItemID AND IsAvailable = 1;
  IF @ItemName IS NULL
    THROW 50012, 'That dish is not available.', 1;

  INSERT INTO dbo.OrderItems (OrderID, ItemID, Quantity, UnitPrice, LineTotal)
  VALUES (@OrderID, @ItemID, @Quantity, @Price, @Quantity * @Price);

  IF @Rate IS NULL
    SET @Rate = CASE WHEN @Sub - @Disc > 0 THEN ROUND(@Tax * 100.0 / (@Sub - @Disc), 2)
                     ELSE ISNULL(TRY_CONVERT(DECIMAL(9,4),
                                (SELECT SettingValue FROM dbo.AppSettings WHERE SettingKey = 'TaxPercent')), 16) END;

  DECLARE @NewSub  DECIMAL(10,2) = (SELECT SUM(LineTotal) FROM dbo.OrderItems WHERE OrderID = @OrderID);
  DECLARE @NewDisc DECIMAL(10,2) = CASE WHEN @Sub > 0 THEN ROUND(@NewSub * @Disc / @Sub, 2) ELSE 0 END;
  DECLARE @NewTax  DECIMAL(10,2) = ROUND((@NewSub - @NewDisc) * @Rate / 100.0, 2);

  UPDATE dbo.Orders
  SET SubTotal = @NewSub, DiscountAmount = @NewDisc, TaxAmount = @NewTax,
      TotalAmount = @NewSub - @NewDisc + @NewTax, UpdatedAt = SYSUTCDATETIME()
  WHERE OrderID = @OrderID;

  DECLARE @Desc NVARCHAR(500) = LEFT(CONCAT('Order #', @OrderID, ': added ', @Quantity, ' x ', @ItemName, ' @ ', @Price), 500);
  EXEC dbo.sp_LogActivity @AddedBy, 'AddOrderItem', @Desc, NULL;

  COMMIT TRANSACTION;
END
GO

-- Listing: now carries the order taker and business date; @CurrentDayOnly limits to the open day.
CREATE OR ALTER PROCEDURE dbo.sp_GetOrders
  @Status NVARCHAR(20) = NULL,
  @StartDate DATE = NULL,
  @EndDate DATE = NULL,
  @OrderType NVARCHAR(20) = NULL,
  @PaymentMethod NVARCHAR(20) = NULL,
  @OrderRef NVARCHAR(30) = NULL,
  @CustomerName NVARCHAR(120) = NULL,
  @TableNumber NVARCHAR(20) = NULL,
  @PageSize INT = NULL,
  @PageNumber INT = 1,
  @CurrentDayOnly BIT = 0
AS
BEGIN
  SET NOCOUNT ON;
  DECLARE @OrderID INT = TRY_CONVERT(INT, @OrderRef);
  DECLARE @Take INT = CASE WHEN @PageSize IS NULL THEN 500 ELSE @PageSize + 1 END;
  DECLARE @Skip INT = CASE WHEN @PageSize IS NULL THEN 0 ELSE (CASE WHEN @PageNumber < 1 THEN 0 ELSE @PageNumber - 1 END) * @PageSize END;

  SELECT o.*, CreatedByName = u.FullName, bd.BusinessDate,
         DayClosed = CASE WHEN bd.ClosedAt IS NOT NULL THEN 1 ELSE 0 END
  FROM dbo.Orders o
  LEFT JOIN dbo.Users u         ON u.UserID = o.CreatedBy
  LEFT JOIN dbo.BusinessDays bd ON bd.BusinessDayID = o.BusinessDayID
  WHERE (@Status IS NULL OR o.Status = @Status)
    AND (@OrderType IS NULL OR o.OrderType = @OrderType)
    AND (@PaymentMethod IS NULL OR o.PaymentMethod = @PaymentMethod)
    AND (@StartDate IS NULL OR o.CreatedAt >= @StartDate)
    AND (@EndDate IS NULL OR o.CreatedAt < DATEADD(DAY, 1, @EndDate))
    AND (@OrderRef IS NULL OR o.OrderID = @OrderID OR o.OrderNumber LIKE '%' + @OrderRef + '%')
    AND (@CustomerName IS NULL OR o.CustomerName LIKE '%' + @CustomerName + '%')
    AND (@TableNumber IS NULL OR o.TableNumber = @TableNumber)
    AND (@CurrentDayOnly = 0 OR bd.OpenSlot = 1)
  ORDER BY o.CreatedAt DESC, o.OrderID DESC
  OFFSET @Skip ROWS FETCH NEXT @Take ROWS ONLY
  OPTION (RECOMPILE);
END
GO

CREATE OR ALTER PROCEDURE dbo.sp_GetOrderByID
  @OrderID INT
AS
BEGIN
  SELECT o.*, CancelledByName = cu.FullName, CreatedByName = tk.FullName, ConfirmedByName = cf.FullName,
         bd.BusinessDate, DayClosed = CASE WHEN bd.ClosedAt IS NOT NULL THEN 1 ELSE 0 END
  FROM dbo.Orders o
  LEFT JOIN dbo.Users cu        ON cu.UserID = o.CancelledBy
  LEFT JOIN dbo.Users tk        ON tk.UserID = o.CreatedBy
  LEFT JOIN dbo.Users cf        ON cf.UserID = o.ConfirmedBy
  LEFT JOIN dbo.BusinessDays bd ON bd.BusinessDayID = o.BusinessDayID
  WHERE o.OrderID = @OrderID;
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

-- ============================================================
--  6. BUSINESS DAY: summary, history, close
-- ============================================================

IF OBJECT_ID('dbo.sp_GetBusinessDaySummary', 'P') IS NULL EXEC('CREATE PROCEDURE dbo.sp_GetBusinessDaySummary AS SELECT 1');
GO
-- @BusinessDayID NULL = the open day. Result sets: 1 day, 2 totals, 3 by payment method, 4 by order taker.
ALTER PROCEDURE dbo.sp_GetBusinessDaySummary
  @BusinessDayID INT = NULL
AS
BEGIN
  SET NOCOUNT ON;
  IF @BusinessDayID IS NULL
    SET @BusinessDayID = (SELECT TOP 1 BusinessDayID FROM dbo.BusinessDays WHERE OpenSlot = 1);

  SELECT bd.BusinessDayID, bd.BusinessDate, bd.OpenedAt, bd.ClosedAt,
         IsOpen = CASE WHEN bd.OpenSlot = 1 THEN 1 ELSE 0 END,
         OpenedByName = ou.FullName, ClosedByName = cu.FullName
  FROM dbo.BusinessDays bd
  LEFT JOIN dbo.Users ou ON ou.UserID = bd.OpenedBy
  LEFT JOIN dbo.Users cu ON cu.UserID = bd.ClosedBy
  WHERE bd.BusinessDayID = @BusinessDayID;

  SELECT Orders          = COUNT(CASE WHEN Status <> 'Cancelled' THEN 1 END),
         ConfirmedOrders = COUNT(CASE WHEN Status = 'Confirmed' THEN 1 END),
         PendingOrders   = COUNT(CASE WHEN Status = 'Pending' THEN 1 END),
         CancelledOrders = COUNT(CASE WHEN Status = 'Cancelled' THEN 1 END),
         SubTotal        = ISNULL(SUM(CASE WHEN Status = 'Confirmed' THEN SubTotal END), 0),
         Discount        = ISNULL(SUM(CASE WHEN Status = 'Confirmed' THEN DiscountAmount END), 0),
         Tax             = ISNULL(SUM(CASE WHEN Status = 'Confirmed' THEN TaxAmount END), 0),
         Sales           = ISNULL(SUM(CASE WHEN Status = 'Confirmed' THEN TotalAmount END), 0),
         CancelledAmount = ISNULL(SUM(CASE WHEN Status = 'Cancelled' THEN TotalAmount END), 0)
  FROM dbo.Orders WHERE BusinessDayID = @BusinessDayID;

  SELECT PaymentMethod, Orders = COUNT(*), Amount = SUM(TotalAmount)
  FROM dbo.Orders WHERE BusinessDayID = @BusinessDayID AND Status = 'Confirmed'
  GROUP BY PaymentMethod ORDER BY SUM(TotalAmount) DESC;

  SELECT OrderTaker = ISNULL(u.FullName, '(unknown)'), Orders = COUNT(*), Sales = SUM(o.TotalAmount)
  FROM dbo.Orders o LEFT JOIN dbo.Users u ON u.UserID = o.CreatedBy
  WHERE o.BusinessDayID = @BusinessDayID AND o.Status = 'Confirmed'
  GROUP BY u.FullName ORDER BY SUM(o.TotalAmount) DESC;
END
GO

IF OBJECT_ID('dbo.sp_GetBusinessDays', 'P') IS NULL EXEC('CREATE PROCEDURE dbo.sp_GetBusinessDays AS SELECT 1');
GO
-- Closed days, newest first (the snapshot taken at close).
ALTER PROCEDURE dbo.sp_GetBusinessDays
  @Top INT = 30
AS
BEGIN
  SET NOCOUNT ON;
  -- OpenedAt/ClosedAt are returned in local time (UTC+5), like the rest of the reports.
  SELECT TOP (@Top) bd.BusinessDayID, bd.BusinessDate, OpenedAt = DATEADD(HOUR, 5, bd.OpenedAt),
         ClosedAt = DATEADD(HOUR, 5, bd.ClosedAt), ClosedByName = cu.FullName,
         bd.TotalOrders, bd.SalesAmount, bd.CancelledOrders, bd.CancelledAmount, bd.Notes
  FROM dbo.BusinessDays bd
  LEFT JOIN dbo.Users cu ON cu.UserID = bd.ClosedBy
  WHERE bd.OpenSlot IS NULL
  ORDER BY bd.ClosedAt DESC, bd.BusinessDayID DESC;
END
GO

IF OBJECT_ID('dbo.sp_CloseBusinessDay', 'P') IS NULL EXEC('CREATE PROCEDURE dbo.sp_CloseBusinessDay AS SELECT 1');
GO
-- Closes the open day and snapshots its totals. A second call finds nothing open and fails, so a
-- double click or two cashiers cannot close the same day twice. The next order opens a new day.
ALTER PROCEDURE dbo.sp_CloseBusinessDay
  @ClosedBy INT
AS
BEGIN
  SET NOCOUNT ON;
  SET XACT_ABORT ON;

  IF @ClosedBy IS NULL OR NOT EXISTS (SELECT 1 FROM dbo.Users WHERE UserID = @ClosedBy)
    THROW 50040, 'The user could not be identified. Please sign in again.', 1;

  BEGIN TRANSACTION;

  DECLARE @Day INT = (SELECT TOP 1 BusinessDayID FROM dbo.BusinessDays WITH (UPDLOCK, HOLDLOCK) WHERE OpenSlot = 1);
  IF @Day IS NULL
    THROW 50041, 'There is no open business day to close (it may already have been closed).', 1;

  DECLARE @Pending INT = (SELECT COUNT(*) FROM dbo.Orders WHERE BusinessDayID = @Day AND Status = 'Pending');
  IF @Pending > 0
  BEGIN
    DECLARE @msg NVARCHAR(300) = CONCAT('Cannot close the day: ', @Pending,
        ' order(s) are still Pending (unpaid). Confirm payment or cancel them first.');
    THROW 50042, @msg, 1;
  END

  UPDATE bd SET
    ClosedAt = SYSUTCDATETIME(), ClosedBy = @ClosedBy, OpenSlot = NULL,
    TotalOrders     = x.Ord,
    SalesAmount     = x.Sales,
    CancelledOrders = x.Canc,
    CancelledAmount = x.CancAmt
  FROM dbo.BusinessDays bd
  CROSS APPLY (SELECT Ord     = COUNT(CASE WHEN o.Status <> 'Cancelled' THEN 1 END),
                      Sales   = ISNULL(SUM(CASE WHEN o.Status = 'Confirmed' THEN o.TotalAmount END), 0),
                      Canc    = COUNT(CASE WHEN o.Status = 'Cancelled' THEN 1 END),
                      CancAmt = ISNULL(SUM(CASE WHEN o.Status = 'Cancelled' THEN o.TotalAmount END), 0)
               FROM dbo.Orders o WHERE o.BusinessDayID = bd.BusinessDayID) x
  WHERE bd.BusinessDayID = @Day;

  DECLARE @Desc NVARCHAR(500) = (SELECT CONCAT('Closed business day ', CONVERT(VARCHAR(10), BusinessDate, 120),
                                    ': ', TotalOrders, ' orders, sales ', SalesAmount) FROM dbo.BusinessDays WHERE BusinessDayID = @Day);
  EXEC dbo.sp_LogActivity @ClosedBy, 'CloseBusinessDay', @Desc, NULL;

  COMMIT TRANSACTION;

  SELECT BusinessDayID, BusinessDate, TotalOrders, SalesAmount, CancelledOrders, CancelledAmount
  FROM dbo.BusinessDays WHERE BusinessDayID = @Day;
END
GO

-- ============================================================
--  7. REPORTS / DASHBOARD: group by business date; sales = Confirmed
-- ============================================================

CREATE OR ALTER PROCEDURE dbo.sp_GetItemsSoldCount
AS
BEGIN
  SELECT ISNULL(SUM(oi.Quantity), 0) AS ItemsSold
  FROM dbo.OrderItems oi
  INNER JOIN dbo.Orders o ON o.OrderID = oi.OrderID
  WHERE o.Status = 'Confirmed';
END
GO

-- Today = the open business day; Yesterday = the most recently closed one.
CREATE OR ALTER PROCEDURE dbo.sp_GetDashboardSummary
  @Date DATE
AS
BEGIN
  SET NOCOUNT ON;
  DECLARE @Open INT = (SELECT TOP 1 BusinessDayID FROM dbo.BusinessDays WHERE OpenSlot = 1);
  DECLARE @Prev INT = (SELECT TOP 1 BusinessDayID FROM dbo.BusinessDays WHERE OpenSlot IS NULL ORDER BY ClosedAt DESC, BusinessDayID DESC);

  SELECT
    TodayOrders     = COUNT(CASE WHEN BusinessDayID = @Open AND Status <> 'Cancelled' THEN 1 END),
    YesterdayOrders = COUNT(CASE WHEN BusinessDayID = @Prev AND Status <> 'Cancelled' THEN 1 END),
    TodayRevenue    = ISNULL(SUM(CASE WHEN BusinessDayID = @Open AND Status = 'Confirmed' THEN TotalAmount END), 0),
    PendingOrders   = COUNT(CASE WHEN Status = 'Pending' THEN 1 END)
  FROM dbo.Orders;

  SELECT TOP 1 mi.Name, SUM(oi.Quantity) AS OrderCount
  FROM dbo.OrderItems oi
  INNER JOIN dbo.MenuItems mi ON oi.ItemID = mi.ItemID
  INNER JOIN dbo.vw_OrdersBiz o ON oi.OrderID = o.OrderID
  WHERE o.Status = 'Confirmed' AND o.BizDate >= DATEADD(DAY, -6, @Date)
  GROUP BY mi.Name
  ORDER BY SUM(oi.Quantity) DESC;
END
GO

CREATE OR ALTER PROCEDURE dbo.sp_GetTwoMonthDailySales
  @Today DATE
AS
BEGIN
  SET NOCOUNT ON;

  DECLARE @thisMonthStart DATE = DATEFROMPARTS(YEAR(@Today), MONTH(@Today), 1);
  DECLARE @lastMonthStart DATE = DATEADD(MONTH, -1, @thisMonthStart);
  DECLARE @nextMonthStart DATE = DATEADD(MONTH,  1, @thisMonthStart);

  ;WITH Days AS (
    SELECT TOP (31) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS DayNo
    FROM sys.all_objects
  ),
  Sales AS (
    SELECT LocalDate = BizDate, TotalAmount
    FROM dbo.vw_OrdersBiz
    WHERE Status = 'Confirmed'
  )
  SELECT
    d.DayNo,
    ThisMonth = ISNULL(SUM(CASE WHEN l.LocalDate >= @thisMonthStart AND l.LocalDate < @nextMonthStart
                                 AND DAY(l.LocalDate) = d.DayNo THEN l.TotalAmount END), 0),
    LastMonth = ISNULL(SUM(CASE WHEN l.LocalDate >= @lastMonthStart AND l.LocalDate < @thisMonthStart
                                 AND DAY(l.LocalDate) = d.DayNo THEN l.TotalAmount END), 0)
  FROM Days d
  LEFT JOIN Sales l ON DAY(l.LocalDate) = d.DayNo
  WHERE d.DayNo <= DAY(EOMONTH(@thisMonthStart))
  GROUP BY d.DayNo
  ORDER BY d.DayNo;
END
GO

CREATE OR ALTER PROCEDURE dbo.sp_GetDailyOrdersByType
  @MonthStart DATE
AS
BEGIN
  SET NOCOUNT ON;
  DECLARE @NextMonthStart DATE = DATEADD(MONTH, 1, @MonthStart);
  ;WITH Days AS (
    SELECT TOP (31) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS DayNo
    FROM sys.all_objects
  )
  SELECT
    d.DayNo,
    DineIn           = ISNULL(SUM(CASE WHEN o.OrderType = 'DineIn'
                                        AND DAY(o.BizDate) = d.DayNo THEN 1 END), 0),
    TakeawayDelivery = ISNULL(SUM(CASE WHEN o.OrderType IN ('Takeaway','Delivery')
                                        AND DAY(o.BizDate) = d.DayNo THEN 1 END), 0)
  FROM Days d
  LEFT JOIN dbo.vw_OrdersBiz o
    ON  o.BizDate >= @MonthStart AND o.BizDate < @NextMonthStart
    AND o.Status <> 'Cancelled'
  WHERE d.DayNo <= DAY(EOMONTH(@MonthStart))
  GROUP BY d.DayNo
  ORDER BY d.DayNo;
END
GO

-- Radar axes: Dine In, Takeaway, Delivery, Pending, Confirmed, Cancelled.
CREATE OR ALTER PROCEDURE dbo.sp_GetRevenueByOrderType
  @Today DATE
AS
BEGIN
  SET NOCOUNT ON;
  DECLARE @ThisStart DATE = DATEFROMPARTS(YEAR(@Today), MONTH(@Today), 1);
  DECLARE @LastStart DATE = DATEADD(MONTH, -1, @ThisStart);
  DECLARE @NextStart DATE = DATEADD(MONTH,  1, @ThisStart);
  SELECT
    ThisDineIn    = ISNULL(SUM(CASE WHEN LocalDate >= @ThisStart AND LocalDate < @NextStart AND Status <> 'Cancelled' AND OrderType = 'DineIn'   THEN 1 END), 0),
    ThisTakeaway  = ISNULL(SUM(CASE WHEN LocalDate >= @ThisStart AND LocalDate < @NextStart AND Status <> 'Cancelled' AND OrderType = 'Takeaway' THEN 1 END), 0),
    ThisDelivery  = ISNULL(SUM(CASE WHEN LocalDate >= @ThisStart AND LocalDate < @NextStart AND Status <> 'Cancelled' AND OrderType = 'Delivery' THEN 1 END), 0),
    ThisPending   = ISNULL(SUM(CASE WHEN LocalDate >= @ThisStart AND LocalDate < @NextStart AND Status = 'Pending'   THEN 1 END), 0),
    ThisConfirmed = ISNULL(SUM(CASE WHEN LocalDate >= @ThisStart AND LocalDate < @NextStart AND Status = 'Confirmed' THEN 1 END), 0),
    ThisCancelled = ISNULL(SUM(CASE WHEN LocalDate >= @ThisStart AND LocalDate < @NextStart AND Status = 'Cancelled' THEN 1 END), 0),
    LastDineIn    = ISNULL(SUM(CASE WHEN LocalDate >= @LastStart AND LocalDate < @ThisStart AND Status <> 'Cancelled' AND OrderType = 'DineIn'   THEN 1 END), 0),
    LastTakeaway  = ISNULL(SUM(CASE WHEN LocalDate >= @LastStart AND LocalDate < @ThisStart AND Status <> 'Cancelled' AND OrderType = 'Takeaway' THEN 1 END), 0),
    LastDelivery  = ISNULL(SUM(CASE WHEN LocalDate >= @LastStart AND LocalDate < @ThisStart AND Status <> 'Cancelled' AND OrderType = 'Delivery' THEN 1 END), 0),
    LastPending   = ISNULL(SUM(CASE WHEN LocalDate >= @LastStart AND LocalDate < @ThisStart AND Status = 'Pending'   THEN 1 END), 0),
    LastConfirmed = ISNULL(SUM(CASE WHEN LocalDate >= @LastStart AND LocalDate < @ThisStart AND Status = 'Confirmed' THEN 1 END), 0),
    LastCancelled = ISNULL(SUM(CASE WHEN LocalDate >= @LastStart AND LocalDate < @ThisStart AND Status = 'Cancelled' THEN 1 END), 0)
  FROM (SELECT LocalDate = BizDate, OrderType, Status FROM dbo.vw_OrdersBiz) s;
END
GO

CREATE OR ALTER PROCEDURE dbo.sp_GetRevenueByDay
  @StartDate DATE,
  @EndDate   DATE
AS
BEGIN
  SET NOCOUNT ON;
  SELECT BizDate AS SaleDate,
         COUNT(*)                    AS OrderCount,
         ISNULL(SUM(TotalAmount), 0) AS Revenue
  FROM dbo.vw_OrdersBiz
  WHERE Status = 'Confirmed' AND BizDate BETWEEN @StartDate AND @EndDate
  GROUP BY BizDate
  ORDER BY SaleDate;
END
GO

CREATE OR ALTER PROCEDURE dbo.sp_GetOrdersByHour
  @Date    DATE,
  @EndDate DATE = NULL
AS
BEGIN
  SET NOCOUNT ON;
  DECLARE @end DATE = ISNULL(@EndDate, @Date);

  SELECT HourLabel =
           RIGHT('0' + CAST(DATEPART(HOUR, DATEADD(HOUR,5,CreatedAt)) AS VARCHAR(2)), 2) + ':00'
           + ' - '
           + RIGHT('0' + CAST((DATEPART(HOUR, DATEADD(HOUR,5,CreatedAt)) + 1) % 24 AS VARCHAR(2)), 2) + ':00',
         OrderCount = COUNT(*),
         Revenue    = ISNULL(SUM(TotalAmount), 0)
  FROM dbo.vw_OrdersBiz
  WHERE Status = 'Confirmed' AND BizDate BETWEEN @Date AND @end
  GROUP BY DATEPART(HOUR, DATEADD(HOUR, 5, CreatedAt))
  ORDER BY DATEPART(HOUR, DATEADD(HOUR, 5, CreatedAt));
END
GO

CREATE OR ALTER PROCEDURE dbo.sp_GetTopMenuItems
  @StartDate DATE,
  @EndDate   DATE,
  @TopN INT = 5
AS
BEGIN
  SET NOCOUNT ON;
  SELECT TOP (@TopN)
         mi.Name           AS ItemName,
         SUM(oi.Quantity)  AS OrderCount,
         SUM(oi.LineTotal) AS Revenue
  FROM dbo.OrderItems oi
  INNER JOIN dbo.MenuItems mi ON oi.ItemID  = mi.ItemID
  INNER JOIN dbo.vw_OrdersBiz o ON oi.OrderID = o.OrderID
  WHERE o.Status = 'Confirmed' AND o.BizDate BETWEEN @StartDate AND @EndDate
  GROUP BY mi.ItemID, mi.Name
  ORDER BY SUM(oi.Quantity) DESC;
END
GO

CREATE OR ALTER PROCEDURE dbo.sp_GetPaymentAnalytics
  @StartDate DATE,
  @EndDate   DATE
AS
BEGIN
  SET NOCOUNT ON;
  SELECT PaymentMethod,
         Orders  = COUNT(*),
         Revenue = ISNULL(SUM(TotalAmount), 0)
  FROM dbo.vw_OrdersBiz
  WHERE Status = 'Confirmed' AND BizDate BETWEEN @StartDate AND @EndDate
  GROUP BY PaymentMethod;
END
GO

-- Revenue = Confirmed (paid) orders. TotalOrders = all non-cancelled. Completed = Confirmed, Active =
-- Pending (unpaid). Cancelled are reported on their own.
CREATE OR ALTER PROCEDURE dbo.sp_GetAnalyticsSummary
  @StartDate DATE,
  @EndDate   DATE
AS
BEGIN
  SET NOCOUNT ON;

  DECLARE @days INT = DATEDIFF(DAY, @StartDate, @EndDate) + 1;
  DECLARE @prevStart DATE = DATEADD(DAY, -@days, @StartDate);
  DECLARE @prevEnd   DATE = DATEADD(DAY, -1, @StartDate);

  SELECT
    TotalRevenue    = ISNULL(SUM(CASE WHEN Status = 'Confirmed' THEN TotalAmount END), 0),
    TotalOrders     = COUNT(CASE WHEN Status <> 'Cancelled' THEN 1 END),
    CompletedOrders = COUNT(CASE WHEN Status = 'Confirmed' THEN 1 END),
    ActiveOrders    = COUNT(CASE WHEN Status = 'Pending' THEN 1 END),
    AvgOrderValue   = CASE WHEN COUNT(CASE WHEN Status = 'Confirmed' THEN 1 END) = 0 THEN 0
                           ELSE ISNULL(SUM(CASE WHEN Status = 'Confirmed' THEN TotalAmount END), 0)
                                / COUNT(CASE WHEN Status = 'Confirmed' THEN 1 END) END,
    CancelledOrders = COUNT(CASE WHEN Status = 'Cancelled' THEN 1 END),
    CancelledAmount = ISNULL(SUM(CASE WHEN Status = 'Cancelled' THEN TotalAmount END), 0)
  FROM dbo.vw_OrdersBiz
  WHERE BizDate BETWEEN @StartDate AND @EndDate;

  SELECT
    PrevRevenue = ISNULL(SUM(CASE WHEN Status = 'Confirmed' THEN TotalAmount END), 0),
    PrevOrders  = COUNT(CASE WHEN Status <> 'Cancelled' THEN 1 END)
  FROM dbo.vw_OrdersBiz
  WHERE BizDate BETWEEN @prevStart AND @prevEnd;
END
GO

-- ============================================================
--  8. NAV: "Day Close" under Orders, Cashier + Admin only
-- ============================================================
IF NOT EXISTS (SELECT 1 FROM dbo.NavItems WHERE Url = '~/Orders/DayClose.aspx')
BEGIN
  DECLARE @grpOrders INT = (SELECT TOP 1 GroupID FROM dbo.NavGroups WHERE GroupName = 'Orders' ORDER BY GroupID);
  IF @grpOrders IS NOT NULL
    INSERT INTO dbo.NavItems (GroupID, ItemName, Url, SortOrder)
    VALUES (@grpOrders, 'Day Close', '~/Orders/DayClose.aspx',
            ISNULL((SELECT MAX(SortOrder) FROM dbo.NavItems WHERE GroupID = @grpOrders), 0) + 1);
END
GO

DECLARE @dc INT = (SELECT TOP 1 ItemID FROM dbo.NavItems WHERE Url = '~/Orders/DayClose.aspx');
IF @dc IS NOT NULL
BEGIN
  IF NOT EXISTS (SELECT 1 FROM dbo.NavItemRoles WHERE ItemID = @dc AND RoleName = 'Cashier')
    INSERT INTO dbo.NavItemRoles (ItemID, RoleName) VALUES (@dc, 'Cashier');
  IF NOT EXISTS (SELECT 1 FROM dbo.NavItemRoles WHERE ItemID = @dc AND RoleName = 'Admin')
    INSERT INTO dbo.NavItemRoles (ItemID, RoleName) VALUES (@dc, 'Admin');
END
GO

PRINT 'Order workflow applied: two statuses, payment confirmation, business days.';
GO
