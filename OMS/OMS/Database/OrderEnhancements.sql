/*
  OMS - Order enhancements (idempotent; safe to re-run, run AFTER DatabaseSetup.sql
  and UsersRolesSetup.sql)

    1. Dynamic tax  : Orders.TaxPercent snapshot, sp_CreateOrder stores it,
                      sp_GetSetting / sp_SetSetting, "Settings" admin nav item.
    2. Cancellation : Orders.CancelledAt/CancelledBy/CancelReason, hardened
                      sp_CancelOrder, sp_UpdateOrderStatus no longer cancels.
*/

SET NOCOUNT ON;
GO

-- ============================================================
--  1. TAX
-- ============================================================

-- Rate in force when the order was placed. NULL on orders created before this
-- column existed (they keep their stored TaxAmount; the UI derives the rate).
IF COL_LENGTH('dbo.Orders', 'TaxPercent') IS NULL
  ALTER TABLE dbo.Orders ADD TaxPercent DECIMAL(5,2) NULL;
GO

IF NOT EXISTS (SELECT 1 FROM dbo.AppSettings WHERE SettingKey = 'TaxPercent')
  INSERT INTO dbo.AppSettings (SettingKey, SettingValue) VALUES ('TaxPercent', '16');
GO

CREATE OR ALTER PROCEDURE dbo.sp_GetSetting
  @SettingKey NVARCHAR(80)
AS
BEGIN
  SET NOCOUNT ON;
  SELECT SettingValue FROM dbo.AppSettings WHERE SettingKey = @SettingKey;
END
GO

CREATE OR ALTER PROCEDURE dbo.sp_SetSetting
  @SettingKey NVARCHAR(80),
  @SettingValue NVARCHAR(500),
  @UpdatedBy INT = NULL
AS
BEGIN
  SET NOCOUNT ON;
  IF EXISTS (SELECT 1 FROM dbo.AppSettings WHERE SettingKey = @SettingKey)
    UPDATE dbo.AppSettings SET SettingValue = @SettingValue, UpdatedAt = SYSUTCDATETIME() WHERE SettingKey = @SettingKey;
  ELSE
    INSERT INTO dbo.AppSettings (SettingKey, SettingValue) VALUES (@SettingKey, @SettingValue);

  DECLARE @Desc NVARCHAR(500) = CONCAT(@SettingKey, ' = ', @SettingValue);
  EXEC dbo.sp_LogActivity @UpdatedBy, 'UpdateSetting', @Desc, NULL;
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
  @OrderID INT OUTPUT,
  @TaxPercent DECIMAL(5,2) = NULL
AS
BEGIN
  DECLARE @Today CHAR(8) = CONVERT(CHAR(8), GETUTCDATE(), 112);
  DECLARE @Next INT = (SELECT COUNT(*) + 1 FROM dbo.Orders WHERE CONVERT(CHAR(8), CreatedAt, 112) = @Today);
  DECLARE @OrderNumber NVARCHAR(20) = CONCAT('ORD-', @Today, '-', RIGHT(CONCAT('0000', @Next), 4));

  INSERT INTO dbo.Orders (OrderNumber, CustomerName, CustomerPhone, CustomerAddress, TableNumber, OrderType, PaymentMethod, PaymentStatus,
                          SubTotal, DiscountAmount, TaxAmount, TaxPercent, TotalAmount, CouponID, Notes, CreatedBy)
  VALUES (@OrderNumber, @CustomerName, @Phone, @Address, @TableNumber, @OrderType, @PaymentMethod, @PaymentStatus,
          @SubTotal, @DiscountAmount, @TaxAmount, @TaxPercent, @TotalAmount, @CouponID, @Notes, @CreatedBy);
  SET @OrderID = SCOPE_IDENTITY();
END
GO

-- Nav item "Settings" under Admin Panel (Admin role only, like the rest of the group)
IF NOT EXISTS (SELECT 1 FROM dbo.NavItems WHERE Url = '~/Admin/Settings.aspx')
BEGIN
  DECLARE @grpAdmin INT =
    (SELECT TOP 1 GroupID FROM dbo.NavGroups WHERE GroupName = 'Admin Panel' ORDER BY GroupID);

  IF @grpAdmin IS NOT NULL
    INSERT INTO dbo.NavItems (GroupID, ItemName, Url, SortOrder)
    VALUES (@grpAdmin, 'Settings', '~/Admin/Settings.aspx',
            ISNULL((SELECT MAX(SortOrder) FROM dbo.NavItems WHERE GroupID = @grpAdmin), 0) + 1);
END
GO

-- ============================================================
--  2. CANCELLATION
-- ============================================================

IF COL_LENGTH('dbo.Orders', 'CancelledAt') IS NULL
  ALTER TABLE dbo.Orders ADD CancelledAt DATETIME2 NULL;
IF COL_LENGTH('dbo.Orders', 'CancelledBy') IS NULL
  ALTER TABLE dbo.Orders ADD CancelledBy INT NULL;
IF COL_LENGTH('dbo.Orders', 'CancelReason') IS NULL
  ALTER TABLE dbo.Orders ADD CancelReason NVARCHAR(500) NULL;
GO

-- Status changes keep going through this one procedure. Cancelling is a
-- separate, privileged action (sp_CancelOrder); a cancelled order is final.
CREATE OR ALTER PROCEDURE dbo.sp_UpdateOrderStatus
  @OrderID INT,
  @Status NVARCHAR(20),
  @UpdatedBy INT = NULL
AS
BEGIN
  DECLARE @Current NVARCHAR(20) = (SELECT Status FROM dbo.Orders WHERE OrderID = @OrderID);

  IF @Current IS NULL
    THROW 50001, 'Order not found.', 1;
  IF @Current = 'Cancelled'
    THROW 50002, 'A cancelled order cannot be changed.', 1;
  IF @Status = 'Cancelled'
    THROW 50003, 'Use the Cancel Order action to cancel an order.', 1;

  UPDATE dbo.Orders SET Status = @Status, UpdatedAt = SYSUTCDATETIME() WHERE OrderID = @OrderID;

  DECLARE @Desc NVARCHAR(500) = CONCAT('Order #', @OrderID, ': ', @Current, ' -> ', @Status);
  EXEC dbo.sp_LogActivity @UpdatedBy, 'UpdateOrderStatus', @Desc, NULL;
END
GO

-- Keeps the original Notes untouched; the audit trail lives in the dedicated
-- columns plus ActivityLog.
CREATE OR ALTER PROCEDURE dbo.sp_CancelOrder
  @OrderID INT,
  @CancelledBy INT = NULL,
  @Reason NVARCHAR(500) = NULL
AS
BEGIN
  DECLARE @Current NVARCHAR(20) = (SELECT Status FROM dbo.Orders WHERE OrderID = @OrderID);

  IF @Current IS NULL
    THROW 50001, 'Order not found.', 1;
  IF @Current = 'Cancelled'
    THROW 50004, 'Order is already cancelled.', 1;
  IF @Current = 'Delivered'
    THROW 50005, 'A delivered order cannot be cancelled.', 1;

  UPDATE dbo.Orders
  SET Status = 'Cancelled', CancelledAt = SYSUTCDATETIME(), CancelledBy = @CancelledBy,
      CancelReason = @Reason, UpdatedAt = SYSUTCDATETIME()
  WHERE OrderID = @OrderID;

  DECLARE @Desc NVARCHAR(500) = LEFT(CONCAT('Order #', @OrderID, ' (was ', @Current, '): ', ISNULL(@Reason, 'no reason given')), 500);
  EXEC dbo.sp_LogActivity @CancelledBy, 'CancelOrder', @Desc, NULL;
END
GO

-- Same three result sets as before; first set gains CancelledByName.
CREATE OR ALTER PROCEDURE dbo.sp_GetOrderByID
  @OrderID INT
AS
BEGIN
  SELECT o.*, cu.FullName AS CancelledByName
  FROM dbo.Orders o
  LEFT JOIN dbo.Users cu ON cu.UserID = o.CancelledBy
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

PRINT 'Order enhancements applied.';
GO

-- ============================================================
--  3. NOTIFICATIONS (nav bell)
-- ============================================================

-- Unread customer messages (staff only) + orders still Pending, newest first.
IF OBJECT_ID('dbo.sp_GetNotifications', 'P') IS NULL EXEC('CREATE PROCEDURE dbo.sp_GetNotifications AS SELECT 1');
GO

ALTER PROCEDURE dbo.sp_GetNotifications
  @IncludeMessages BIT = 0
AS
BEGIN
  SET NOCOUNT ON;
  SELECT TOP 15 Kind, RefID, Title, Detail, CreatedAt
  FROM (
    SELECT 'Message' AS Kind, MessageID AS RefID, CustomerName AS Title,
           CONCAT('sent a message: ', Subject) AS Detail, CreatedAt
    FROM dbo.Messages WHERE @IncludeMessages = 1 AND IsRead = 0
    UNION ALL
    SELECT 'Order', OrderID, OrderNumber,
           CONCAT('is pending - Rs. ', CONVERT(VARCHAR(20), CAST(TotalAmount AS DECIMAL(12,0)))), CreatedAt
    FROM dbo.Orders WHERE Status = 'Pending'
  ) n
  ORDER BY CreatedAt DESC;
END
GO

IF OBJECT_ID('dbo.sp_MarkAllMessagesRead', 'P') IS NULL EXEC('CREATE PROCEDURE dbo.sp_MarkAllMessagesRead AS SELECT 1');
GO

ALTER PROCEDURE dbo.sp_MarkAllMessagesRead
AS
BEGIN
  SET NOCOUNT ON;
  UPDATE dbo.Messages SET IsRead = 1 WHERE IsRead = 0;
END
GO

-- ============================================================
--  4. ORDER LIST SEARCH + PAGING
-- ============================================================

-- Backwards compatible: with no new arguments it behaves as before (newest 500).
-- With @PageSize it returns one page plus one extra row, so the UI can tell
-- whether a next page exists without a COUNT(*) over the table.
CREATE OR ALTER PROCEDURE dbo.sp_GetOrders
  @Status NVARCHAR(20) = NULL,
  @StartDate DATE = NULL,
  @EndDate DATE = NULL,
  @OrderType NVARCHAR(20) = NULL,
  @PaymentMethod NVARCHAR(20) = NULL,
  @OrderRef NVARCHAR(30) = NULL,        -- O.ID: numeric OrderID or part of OrderNumber
  @CustomerName NVARCHAR(120) = NULL,   -- C.Name
  @TableNumber NVARCHAR(20) = NULL,     -- T.B.
  @PageSize INT = NULL,
  @PageNumber INT = 1
AS
BEGIN
  SET NOCOUNT ON;
  DECLARE @OrderID INT = TRY_CONVERT(INT, @OrderRef);
  DECLARE @Take INT = CASE WHEN @PageSize IS NULL THEN 500 ELSE @PageSize + 1 END;
  DECLARE @Skip INT = CASE WHEN @PageSize IS NULL THEN 0 ELSE (CASE WHEN @PageNumber < 1 THEN 0 ELSE @PageNumber - 1 END) * @PageSize END;

  SELECT *
  FROM dbo.Orders
  WHERE (@Status IS NULL OR Status = @Status)
    AND (@OrderType IS NULL OR OrderType = @OrderType)
    AND (@PaymentMethod IS NULL OR PaymentMethod = @PaymentMethod)
    AND (@StartDate IS NULL OR CreatedAt >= @StartDate)
    AND (@EndDate IS NULL OR CreatedAt < DATEADD(DAY, 1, @EndDate))
    AND (@OrderRef IS NULL OR OrderID = @OrderID OR OrderNumber LIKE '%' + @OrderRef + '%')
    AND (@CustomerName IS NULL OR CustomerName LIKE '%' + @CustomerName + '%')
    AND (@TableNumber IS NULL OR TableNumber = @TableNumber)
  ORDER BY CreatedAt DESC, OrderID DESC
  OFFSET @Skip ROWS FETCH NEXT @Take ROWS ONLY
  OPTION (RECOMPILE);
END
GO

-- Newest-first listing + filters. OrderNumber already has a unique index.
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Orders_CreatedAt' AND object_id = OBJECT_ID('dbo.Orders'))
  CREATE INDEX IX_Orders_CreatedAt ON dbo.Orders (CreatedAt DESC, OrderID DESC)
    INCLUDE (Status, OrderType, TableNumber, CustomerName);
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Orders_TableNumber' AND object_id = OBJECT_ID('dbo.Orders'))
  CREATE INDEX IX_Orders_TableNumber ON dbo.Orders (TableNumber, CreatedAt DESC);
GO

-- ============================================================
--  5. DASHBOARD IS ADMIN-ONLY (nav visibility; the pages also enforce it)
-- ============================================================

DELETE ngr
FROM dbo.NavGroupRoles ngr
INNER JOIN dbo.NavGroups g ON g.GroupID = ngr.GroupID
WHERE g.Url = '~/Default.aspx' AND ngr.RoleName <> 'Admin';

INSERT INTO dbo.NavGroupRoles (GroupID, RoleName)
SELECT g.GroupID, 'Admin' FROM dbo.NavGroups g
WHERE g.Url = '~/Default.aspx'
  AND NOT EXISTS (SELECT 1 FROM dbo.NavGroupRoles r WHERE r.GroupID = g.GroupID AND r.RoleName = 'Admin');
GO

PRINT 'Order list search, dashboard access applied.';
GO
