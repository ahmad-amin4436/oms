using System;
using System.Data;
using OMS.Common.DAL;
using OMS.Common.Models;

namespace OMS.Common.BLL
{
    public static class DashboardService
    {
        public static DashboardSummary GetSummary(DateTime localDate)
        {
            var dataSet = DBHelper.ExecuteDataSet("sp_GetDashboardSummary", DBHelper.Parameter("@Date", localDate.Date));
            var summary = new DashboardSummary();

            if (dataSet.Tables.Count > 0 && dataSet.Tables[0].Rows.Count > 0)
            {
                var row = dataSet.Tables[0].Rows[0];
                summary.TodayOrders = Convert.ToInt32(row["TodayOrders"]);
                summary.YesterdayOrders = Convert.ToInt32(row["YesterdayOrders"]);
                summary.TodayRevenue = Convert.ToDecimal(row["TodayRevenue"]);
                summary.PendingOrders = Convert.ToInt32(row["PendingOrders"]);
            }

            if (dataSet.Tables.Count > 1 && dataSet.Tables[1].Rows.Count > 0)
            {
                summary.PopularItemName = Convert.ToString(dataSet.Tables[1].Rows[0]["Name"]);
                summary.PopularItemCount = Convert.ToInt32(dataSet.Tables[1].Rows[0]["OrderCount"]);
            }

            return summary;
        }

        public static DataTable RevenueByDay(DateTime start, DateTime end)
        {
            return DBHelper.ExecuteDataTable("sp_GetRevenueByDay", DBHelper.Parameter("@StartDate", start.Date), DBHelper.Parameter("@EndDate", end.Date));
        }

        public static DataTable OrdersByHour(DateTime date)
        {
            return DBHelper.ExecuteDataTable("sp_GetOrdersByHour", DBHelper.Parameter("@Date", date.Date));
        }

        // Hourly distribution across a date range (inclusive).
        public static DataTable OrdersByHour(DateTime start, DateTime end)
        {
            return DBHelper.ExecuteDataTable("sp_GetOrdersByHour",
                DBHelper.Parameter("@Date", start.Date),
                DBHelper.Parameter("@EndDate", end.Date));
        }

        public static DataTable TopMenuItems(DateTime start, DateTime end, int top)
        {
            return DBHelper.ExecuteDataTable("sp_GetTopMenuItems", DBHelper.Parameter("@StartDate", start.Date), DBHelper.Parameter("@EndDate", end.Date), DBHelper.Parameter("@TopN", top));
        }

        public static DataTable TwoMonthDailySales(DateTime today)
        {
            return DBHelper.ExecuteDataTable("sp_GetTwoMonthDailySales",
                DBHelper.Parameter("@Today", today.Date));
        }

        public static DataTable DailyOrdersByType(DateTime monthStart)
        {
            return DBHelper.ExecuteDataTable("sp_GetDailyOrdersByType",
                DBHelper.Parameter("@MonthStart", new DateTime(monthStart.Year, monthStart.Month, 1)));
        }

        public static DataRow RevenueByOrderType(DateTime today)
        {
            DataTable dt = DBHelper.ExecuteDataTable("sp_GetRevenueByOrderType",
                DBHelper.Parameter("@Today", today.Date));
            return dt.Rows.Count > 0 ? dt.Rows[0] : null;
        }

        public static DataTable PaymentAnalytics(DateTime start, DateTime end)
        {
            return DBHelper.ExecuteDataTable("sp_GetPaymentAnalytics", DBHelper.Parameter("@StartDate", start.Date), DBHelper.Parameter("@EndDate", end.Date));
        }

        public static AnalyticsSummary AnalyticsSummary(DateTime start, DateTime end)
        {
            var ds = DBHelper.ExecuteDataSet("sp_GetAnalyticsSummary",
                DBHelper.Parameter("@StartDate", start.Date),
                DBHelper.Parameter("@EndDate", end.Date));

            var s = new AnalyticsSummary();
            if (ds.Tables.Count > 0 && ds.Tables[0].Rows.Count > 0)
            {
                var r = ds.Tables[0].Rows[0];
                s.TotalRevenue    = Convert.ToDecimal(r["TotalRevenue"]);
                s.TotalOrders     = Convert.ToInt32(r["TotalOrders"]);
                s.CompletedOrders = Convert.ToInt32(r["CompletedOrders"]);
                s.ActiveOrders    = Convert.ToInt32(r["ActiveOrders"]);
                s.AvgOrderValue   = Convert.ToDecimal(r["AvgOrderValue"]);
            }
            if (ds.Tables.Count > 1 && ds.Tables[1].Rows.Count > 0)
            {
                var r = ds.Tables[1].Rows[0];
                s.PrevRevenue = Convert.ToDecimal(r["PrevRevenue"]);
                s.PrevOrders  = Convert.ToInt32(r["PrevOrders"]);
            }
            return s;
        }
    }
}
