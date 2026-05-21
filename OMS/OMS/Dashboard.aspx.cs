using System;
using System.Data;
using OMS.App_Code.BLL;
using OMS.App_Code.DAL;
using OMS.App_Code.Helpers;

namespace OMS
{
    public partial class Dashboard : System.Web.UI.Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {
            SecurityHelper.RequireLogin();
            if (!IsPostBack) BindDashboard();
        }

        protected void tmrDashboard_Tick(object sender, EventArgs e)
        {
            BindDashboard();
        }

        private void BindDashboard()
        {
            var today = DateTime.UtcNow.AddHours(5).Date;
            var summary = DashboardService.GetSummary(today);
            lblTodayOrders.Text = summary.TodayOrders.ToString("N0");
            lblRevenue.Text = summary.TodayRevenue.ToString("N2");
            lblPendingOrders.Text = summary.PendingOrders.ToString("N0");
            lblPopularItem.Text = string.IsNullOrEmpty(summary.PopularItemName) ? "No sales yet" : summary.PopularItemName;
            lblPopularCount.Text = summary.PopularItemCount.ToString("N0");

            var change = summary.YesterdayOrders == 0 ? 0 : ((summary.TodayOrders - summary.YesterdayOrders) * 100.0 / summary.YesterdayOrders);
            lblOrderChange.Text = change.ToString("0.#") + "% vs yesterday";

            gvRecentOrders.DataSource = DBHelper.ExecuteDataTable("sp_GetOrders",
                DBHelper.Parameter("@Status", DBNull.Value),
                DBHelper.Parameter("@StartDate", today.AddDays(-7)),
                DBHelper.Parameter("@EndDate", today),
                DBHelper.Parameter("@OrderType", DBNull.Value),
                DBHelper.Parameter("@PaymentMethod", DBNull.Value));
            gvRecentOrders.DataBind();

            var unavailable = DBHelper.ExecuteDataTable("sp_GetMenuItems",
                DBHelper.Parameter("@CategoryID", DBNull.Value),
                DBHelper.Parameter("@IsAvailable", false));
            rptUnavailable.DataSource = unavailable;
            rptUnavailable.DataBind();
            pnlNoUnavailable.Visible = unavailable.Rows.Count == 0;
        }
    }
}
