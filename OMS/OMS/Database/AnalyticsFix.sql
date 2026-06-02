/*
  OMS - Analytics accuracy fix
  --------------------------------------------------------------
  Three corrections applied consistently across the analytics SPs:

  1. Timezone: Orders.CreatedAt is stored in UTC (SYSUTCDATETIME()), but the
     business day is UTC+5. All date filtering/grouping now converts to local
     time first  ->  DATEADD(HOUR, 5, CreatedAt)  so orders land in the correct
     local day (no more midnight-boundary leakage).

  2. Revenue basis: "gross" everywhere = SUM(TotalAmount) over every order,
     no PaymentStatus filter, so KPI / Revenue-by-Day / Payment Mix / Hourly
     all agree.

  3. sp_GetOrdersByHour is range-aware (optional @EndDate); when @EndDate is
     NULL it behaves as a single-day report on @Date.

  Run against the RMS database. Safe to re-run (CREATE OR ALTER).
*/

SET NOCOUNT ON;
GO

-- Local business date for an order (UTC + 5h), as a DATE.
-- Used implicitly below via DATEADD(HOUR,5,CreatedAt).

CREATE OR ALTER PROCEDURE dbo.sp_GetRevenueByDay
  @StartDate DATE,
  @EndDate   DATE
AS
BEGIN
  SET NOCOUNT ON;
  SELECT CAST(DATEADD(HOUR, 5, CreatedAt) AS DATE) AS SaleDate,
         COUNT(*)                                  AS OrderCount,
         ISNULL(SUM(TotalAmount), 0)               AS Revenue
  FROM dbo.Orders
  WHERE CAST(DATEADD(HOUR, 5, CreatedAt) AS DATE) BETWEEN @StartDate AND @EndDate
  GROUP BY CAST(DATEADD(HOUR, 5, CreatedAt) AS DATE)
  ORDER BY SaleDate;
END
GO

CREATE OR ALTER PROCEDURE dbo.sp_GetOrdersByHour
  @Date    DATE,
  @EndDate DATE = NULL          -- NULL => single day (@Date)
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
  FROM dbo.Orders
  WHERE CAST(DATEADD(HOUR, 5, CreatedAt) AS DATE) BETWEEN @Date AND @end
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
  INNER JOIN dbo.Orders    o  ON oi.OrderID = o.OrderID
  WHERE CAST(DATEADD(HOUR, 5, o.CreatedAt) AS DATE) BETWEEN @StartDate AND @EndDate
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
  FROM dbo.Orders
  WHERE CAST(DATEADD(HOUR, 5, CreatedAt) AS DATE) BETWEEN @StartDate AND @EndDate
  GROUP BY PaymentMethod;
END
GO

-- KPI summary: gross revenue + local-time range, with the preceding equal-length
-- range for period-over-period deltas.
CREATE OR ALTER PROCEDURE dbo.sp_GetAnalyticsSummary
  @StartDate DATE,
  @EndDate   DATE
AS
BEGIN
  SET NOCOUNT ON;

  DECLARE @days INT = DATEDIFF(DAY, @StartDate, @EndDate) + 1;
  DECLARE @prevStart DATE = DATEADD(DAY, -@days, @StartDate);
  DECLARE @prevEnd   DATE = DATEADD(DAY, -1, @StartDate);

  -- Current range (gross revenue across all orders in range).
  -- Completed = Delivered; Active = anything still in progress (not Delivered,
  -- not Cancelled). Based on order Status, not payment status.
  SELECT
    TotalRevenue    = ISNULL(SUM(TotalAmount), 0),
    TotalOrders     = COUNT(*),
    CompletedOrders = COUNT(CASE WHEN Status = 'Delivered' THEN 1 END),
    ActiveOrders    = COUNT(CASE WHEN Status NOT IN ('Delivered', 'Cancelled') THEN 1 END),
    AvgOrderValue   = CASE WHEN COUNT(*) = 0 THEN 0
                           ELSE ISNULL(SUM(TotalAmount), 0) / COUNT(*) END
  FROM dbo.Orders
  WHERE CAST(DATEADD(HOUR, 5, CreatedAt) AS DATE) BETWEEN @StartDate AND @EndDate;

  -- Previous (comparison) range
  SELECT
    PrevRevenue = ISNULL(SUM(TotalAmount), 0),
    PrevOrders  = COUNT(*)
  FROM dbo.Orders
  WHERE CAST(DATEADD(HOUR, 5, CreatedAt) AS DATE) BETWEEN @prevStart AND @prevEnd;
END
GO

PRINT 'Analytics SPs updated: gross revenue + local-time (UTC+5) date handling + range-aware hourly.';
GO
