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

            // Browsers pre-fill a saved login (e.g. an email) into the first text box. Keeping the
            // search boxes read-only until they are clicked stops that; typing and posting work normally.
            foreach (var tb in new[] { txtOrderRef, txtCustomer, txtTable })
            {
                tb.Attributes["readonly"] = "readonly";
                tb.Attributes["onfocus"]  = "this.removeAttribute('readonly');";
                tb.Attributes["data-lpignore"] = "true";
            }
            lnkDayClose.Visible = SecurityHelper.IsInRole("Cashier", "Admin")
                                  && SecurityHelper.CanOpen("~/Orders/DayClose.aspx");
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
            chkCurrentDay.Checked = false;
            ddlStatus.SelectedIndex = 0;
            ddlOrderType.SelectedIndex = 0;
            FiltersChanged(sender, e);
        }

        // ── Settle (= confirm payment) straight from the list ────────────────
        // Only a Cashier/Admin, only for an unpaid (Pending) order. An order from an already-closed day can still be
        // settled: the payment is counted in the current business day (the closed day is not changed).
        protected bool ShowSettle(object status)
        {
            return SecurityHelper.IsInRole("Cashier", "Admin")
                   && Convert.ToString(status) == "Pending";
        }

        protected string SettleConfirm(object orderNumber, object total, object method, object dayClosed)
        {
            string text = "Settle " + Convert.ToString(orderNumber) + " - Rs. " + Convert.ToDecimal(total).ToString("N0") +
                          " (" + Convert.ToString(method) + ") as paid?";
            if (Convert.ToInt32(dayClosed) == 1)
                text += " It is from a closed business day, so the payment will count in the current business day.";
            return "return confirm('" + text.Replace("'", "") + "');";
        }

        protected void gvOrders_RowCommand(object sender, System.Web.UI.WebControls.GridViewCommandEventArgs e)
        {
            if (e.CommandName != "Settle") return;

            // Server-side authorization: the button being visible proves nothing.
            if (!SecurityHelper.IsInRole("Cashier", "Admin"))
            {
                Response.Redirect("~/AccessDenied.aspx", false);
                Context.ApplicationInstance.CompleteRequest();
                return;
            }

            int orderId, cashierId = SecurityHelper.UserID;
            if (cashierId == 0 || !int.TryParse(Convert.ToString(e.CommandArgument), out orderId)) return;

            try
            {
                // Settles with the order's own payment method and tax; use Order Detail to change the method.
                DBHelper.ExecuteNonQuery("sp_ConfirmOrder",
                    DBHelper.Parameter("@OrderID",       orderId),
                    DBHelper.Parameter("@ConfirmedBy",   cashierId),
                    DBHelper.Parameter("@PaymentMethod", DBNull.Value),
                    DBHelper.Parameter("@TaxPercent",    DBNull.Value));
                lblListMsg.Text    = "Order settled (paid).";
                lblListMsg.Visible = true;
            }
            catch (Exception ex)
            {
                lblListError.Text    = "Could not settle: " + ex.Message;
                lblListError.Visible = true;
            }
            BindOrders();
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
            foreach (var status in new[] { "Pending", "Confirmed", "Cancelled" }) ddlStatus.Items.Add(status);
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
                DBHelper.Parameter("@PageNumber", PageNo),
                DBHelper.Parameter("@CurrentDayOnly", chkCurrentDay.Checked));

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
