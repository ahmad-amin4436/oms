/*
  OMS - Admin dashboard (Default.aspx) supporting procedure.
  Run against the RMS database. Safe to re-run.
*/
SET NOCOUNT ON;
GO

-- Total quantity of menu items sold across all non-cancelled orders (all-time).
CREATE OR ALTER PROCEDURE dbo.sp_GetItemsSoldCount
AS
BEGIN
  SELECT ISNULL(SUM(oi.Quantity), 0) AS ItemsSold
  FROM dbo.OrderItems oi
  INNER JOIN dbo.Orders o ON o.OrderID = oi.OrderID
  WHERE o.Status <> 'Cancelled';
END
GO

-- @Date is the LOCAL business day. Orders.CreatedAt is UTC, so every comparison
-- converts to local time (UTC+5) first. Revenue is gross (excludes Cancelled).
CREATE OR ALTER PROCEDURE dbo.sp_GetDashboardSummary
  @Date DATE
AS
BEGIN
  DECLARE @Yesterday DATE = DATEADD(DAY, -1, @Date);

  SELECT
    TodayOrders     = COUNT(CASE WHEN CAST(DATEADD(HOUR,5,CreatedAt) AS DATE) = @Date THEN 1 END),
    YesterdayOrders = COUNT(CASE WHEN CAST(DATEADD(HOUR,5,CreatedAt) AS DATE) = @Yesterday THEN 1 END),
    TodayRevenue    = ISNULL(SUM(CASE WHEN CAST(DATEADD(HOUR,5,CreatedAt) AS DATE) = @Date
                                       AND Status <> 'Cancelled' THEN TotalAmount END), 0),
    PendingOrders   = COUNT(CASE WHEN Status NOT IN ('Delivered','Cancelled') THEN 1 END)
  FROM dbo.Orders;

  SELECT TOP 1 mi.Name, SUM(oi.Quantity) AS OrderCount
  FROM dbo.OrderItems oi
  INNER JOIN dbo.MenuItems mi ON oi.ItemID = mi.ItemID
  INNER JOIN dbo.Orders o ON oi.OrderID = o.OrderID
  WHERE CAST(DATEADD(HOUR,5,o.CreatedAt) AS DATE) >= DATEADD(DAY, -6, @Date)
  GROUP BY mi.Name
  ORDER BY SUM(oi.Quantity) DESC;
END
GO

-- Daily gross revenue for the current local month and the previous month,
-- aligned by day-of-month (1..31) so the two can be overlaid on one x-axis.
-- @Today is the local business day; revenue excludes cancelled orders.
CREATE OR ALTER PROCEDURE dbo.sp_GetTwoMonthDailySales
  @Today DATE
AS
BEGIN
  SET NOCOUNT ON;

  DECLARE @thisMonthStart DATE = DATEFROMPARTS(YEAR(@Today), MONTH(@Today), 1);
  DECLARE @lastMonthStart DATE = DATEADD(MONTH, -1, @thisMonthStart);
  DECLARE @nextMonthStart DATE = DATEADD(MONTH,  1, @thisMonthStart);

  -- Numbers 1..31 to guarantee a row per day even with no sales.
  ;WITH Days AS (
    SELECT TOP (31) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS DayNo
    FROM sys.all_objects
  ),
  Local AS (
    SELECT LocalDate = CAST(DATEADD(HOUR, 5, CreatedAt) AS DATE), TotalAmount
    FROM dbo.Orders
    WHERE Status <> 'Cancelled'
  )
  SELECT
    d.DayNo,
    ThisMonth = ISNULL(SUM(CASE WHEN l.LocalDate >= @thisMonthStart AND l.LocalDate < @nextMonthStart
                                 AND DAY(l.LocalDate) = d.DayNo THEN l.TotalAmount END), 0),
    LastMonth = ISNULL(SUM(CASE WHEN l.LocalDate >= @lastMonthStart AND l.LocalDate < @thisMonthStart
                                 AND DAY(l.LocalDate) = d.DayNo THEN l.TotalAmount END), 0)
  FROM Days d
  LEFT JOIN Local l ON DAY(l.LocalDate) = d.DayNo
  WHERE d.DayNo <= DAY(EOMONTH(@thisMonthStart))        -- cap to days in current month
  GROUP BY d.DayNo
  ORDER BY d.DayNo;
END
GO

PRINT 'sp_GetTwoMonthDailySales created.';
GO
