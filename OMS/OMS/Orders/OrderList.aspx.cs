using System;
using OMS.Common.DAL;
using OMS.Common.Helpers;

namespace OMS.Orders
{
    public partial class OrderList : System.Web.UI.Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {
            SecurityHelper.RequireUrlAccess();
            lnkNewOrder.Visible = SecurityHelper.CanOpen("~/Orders/NewOrder.aspx");
            if (!IsPostBack)
            {
                BindFilters();
                BindOrders();
            }
        }

        private const int PageSize = 25;

        private int PageNo
        {
            get { return ViewState["PageNo"] is int ? (int)ViewState["PageNo"] : 1; }
            set { ViewState["PageNo"] = value; }
        }

        protected void FiltersChanged(object sender, EventArgs e)
        {
            PageNo = 1;
            BindOrders();
        }

        protected void btnClear_Click(object sender, EventArgs e)
        {
            txtOrderRef.Text = txtCustomer.Text = txtTable.Text = txtStartDate.Text = txtEndDate.Text = "";
            ddlStatus.SelectedIndex = 0;
            ddlOrderType.SelectedIndex = 0;
            FiltersChanged(sender, e);
        }

        protected void btnPrev_Click(object sender, EventArgs e) { if (PageNo > 1) PageNo--; BindOrders(); }
        protected void btnNext_Click(object sender, EventArgs e) { PageNo++; BindOrders(); }

        private static object OrNull(string s)
        {
            s = (s ?? "").Trim();
            return s.Length == 0 ? (object)DBNull.Value : s;
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
            // Ask for one row more than a page: the extra row only tells us a next page exists.
            var dt = DBHelper.ExecuteDataTable("sp_GetOrders",
                DBHelper.Parameter("@Status", string.IsNullOrEmpty(ddlStatus.SelectedValue) ? (object)DBNull.Value : ddlStatus.SelectedValue),
                DBHelper.Parameter("@StartDate", DateTime.TryParse(txtStartDate.Text, out start) ? (object)start.Date : DBNull.Value),
                DBHelper.Parameter("@EndDate", DateTime.TryParse(txtEndDate.Text, out end) ? (object)end.Date : DBNull.Value),
                DBHelper.Parameter("@OrderType", string.IsNullOrEmpty(ddlOrderType.SelectedValue) ? (object)DBNull.Value : ddlOrderType.SelectedValue),
                DBHelper.Parameter("@PaymentMethod", DBNull.Value),
                DBHelper.Parameter("@OrderRef", OrNull(txtOrderRef.Text)),
                DBHelper.Parameter("@CustomerName", OrNull(txtCustomer.Text)),
                DBHelper.Parameter("@TableNumber", OrNull(txtTable.Text)),
                DBHelper.Parameter("@PageSize", PageSize),
                DBHelper.Parameter("@PageNumber", PageNo));

            bool hasNext = dt.Rows.Count > PageSize;
            if (hasNext) dt.Rows.RemoveAt(PageSize);

            gvOrders.DataSource = dt;
            gvOrders.DataBind();
            lblPage.Text       = PageNo.ToString();
            btnPrev.Enabled    = PageNo > 1;
            btnNext.Enabled    = hasNext;
        }
    }
}
