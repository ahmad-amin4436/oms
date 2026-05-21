using System;
using System.Data;
using OMS.App_Code.DAL;
using OMS.App_Code.Models;

namespace OMS.App_Code.BLL
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

        public static DataTable TopMenuItems(DateTime start, DateTime end, int top)
        {
            return DBHelper.ExecuteDataTable("sp_GetTopMenuItems", DBHelper.Parameter("@StartDate", start.Date), DBHelper.Parameter("@EndDate", end.Date), DBHelper.Parameter("@TopN", top));
        }
    }
}
