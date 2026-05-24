using System;
using OMS.Common.DAL;
using OMS.Common.Helpers;

namespace OMS.Orders
{
    public partial class OrderList : System.Web.UI.Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {
            SecurityHelper.RequireLogin();
            if (!IsPostBack)
            {
                BindFilters();
                BindOrders();
            }
        }

        protected void FiltersChanged(object sender, EventArgs e)
        {
            BindOrders();
        }

        private void BindFilters()
        {
            ddlStatus.Items.Add(new System.Web.UI.WebControls.ListItem("All Statuses", ""));
            foreach (var status in new[] { "Pending", "Confirmed", "Preparing", "Ready", "Delivered", "Cancelled" }) ddlStatus.Items.Add(status);
            ddlOrderType.Items.Add(new System.Web.UI.WebControls.ListItem("All Types", ""));
            foreach (var type in new[] { "DineIn", "Takeaway", "Delivery" }) ddlOrderType.Items.Add(type);
        }

        private void BindOrders()
        {
            DateTime start, end;
            gvOrders.DataSource = DBHelper.ExecuteDataTable("sp_GetOrders",
                DBHelper.Parameter("@Status", string.IsNullOrEmpty(ddlStatus.SelectedValue) ? (object)DBNull.Value : ddlStatus.SelectedValue),
                DBHelper.Parameter("@StartDate", DateTime.TryParse(txtStartDate.Text, out start) ? (object)start.Date : DBNull.Value),
                DBHelper.Parameter("@EndDate", DateTime.TryParse(txtEndDate.Text, out end) ? (object)end.Date : DBNull.Value),
                DBHelper.Parameter("@OrderType", string.IsNullOrEmpty(ddlOrderType.SelectedValue) ? (object)DBNull.Value : ddlOrderType.SelectedValue),
                DBHelper.Parameter("@PaymentMethod", DBNull.Value));
            gvOrders.DataBind();
        }
    }
}
