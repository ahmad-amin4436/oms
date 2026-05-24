using System;
using OMS.Common.BLL;
using OMS.Common.DAL;
using OMS.Common.Helpers;

namespace OMS.Analytics
{
    public partial class Analytics : System.Web.UI.Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {
            SecurityHelper.RequireRoles("Admin", "Manager");
            if (!IsPostBack)
            {
                var today = DateTime.UtcNow.AddHours(5).Date;
                txtStart.Text = today.AddDays(-29).ToString("yyyy-MM-dd");
                txtEnd.Text   = today.ToString("yyyy-MM-dd");
                BindAll();
            }
        }

        protected void btnApply_Click(object sender, EventArgs e)
        {
            BindAll();
        }

        private void BindAll()
        {
            DateTime start, end;
            var today = DateTime.UtcNow.AddHours(5).Date;

            start = DateTime.TryParse(txtStart.Text, out start) ? start.Date : today.AddDays(-29);
            end   = DateTime.TryParse(txtEnd.Text,   out end)   ? end.Date   : today;

            gvRevenue.DataSource = DashboardService.RevenueByDay(start, end);
            gvRevenue.DataBind();

            gvTopItems.DataSource = DashboardService.TopMenuItems(start, end, 10);
            gvTopItems.DataBind();

            gvHourly.DataSource = DashboardService.OrdersByHour(today);
            gvHourly.DataBind();
        }
    }
}
