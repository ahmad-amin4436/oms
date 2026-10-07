using System;
using System.Data;
using OMS.Common.DAL;
using OMS.Common.Helpers;

namespace OMS.Orders
{
    /// <summary>
    /// Close the open business day (Cashier / Admin). The summary and the close both come from the
    /// database (sp_GetBusinessDaySummary / sp_CloseBusinessDay), which also refuses a duplicate
    /// close and a close while unpaid (Pending) orders remain.
    /// </summary>
    public partial class DayClose : System.Web.UI.Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {
            SecurityHelper.RequireRoles("Cashier", "Admin");
            if (!SecurityHelper.IsInRole("Cashier", "Admin")) return;
            if (!IsPostBack) BindAll();
        }

        protected void btnClose_Click(object sender, EventArgs e)
        {
            // Server-side authorization: the button being visible proves nothing.
            SecurityHelper.RequireRoles("Cashier", "Admin");
            if (!SecurityHelper.IsInRole("Cashier", "Admin")) return;

            int userId = SecurityHelper.UserID;
            if (userId == 0) { SecurityHelper.RequireLogin(); return; }

            try
            {
                var ds = DBHelper.ExecuteDataSet("sp_CloseBusinessDay", DBHelper.Parameter("@ClosedBy", userId));
                if (ds.Tables.Count > 0 && ds.Tables[0].Rows.Count > 0)
                {
                    DataRow r = ds.Tables[0].Rows[0];
                    lblMsg.Text = "Business day " + Convert.ToDateTime(r["BusinessDate"]).ToString("dd MMM yyyy") +
                                  " is closed: " + Convert.ToInt32(r["TotalOrders"]) + " orders, sales Rs. " +
                                  Convert.ToDecimal(r["SalesAmount"]).ToString("N0") +
                                  ". The next order starts a new business day.";
                    lblMsg.Visible = true;
                }
            }
            catch (Exception ex)
            {
                lblError.Text    = ex.Message;   // e.g. "N order(s) are still Pending" / "already closed"
                lblError.Visible = true;
            }

            BindAll();
        }

        private void BindAll()
        {
            DataSet ds = DBHelper.ExecuteDataSet("sp_GetBusinessDaySummary", DBHelper.Parameter("@BusinessDayID", DBNull.Value));
            bool hasOpen = ds.Tables.Count > 3 && ds.Tables[0].Rows.Count > 0 && Convert.ToInt32(ds.Tables[0].Rows[0]["IsOpen"]) == 1;

            pnlOpen.Visible   = hasOpen;
            pnlNoOpen.Visible = !hasOpen;

            if (hasOpen)
            {
                DataRow day = ds.Tables[0].Rows[0];
                DataRow t   = ds.Tables[1].Rows[0];

                lblDay.Text    = Convert.ToDateTime(day["BusinessDate"]).ToString("dddd, dd MMM yyyy");
                lblOpened.Text = "Opened " + Convert.ToDateTime(day["OpenedAt"]).AddHours(5).ToString("dd MMM, hh:mm tt") +
                                 (string.IsNullOrEmpty(Convert.ToString(day["OpenedByName"])) ? "" : " by " + Server.HtmlEncode(Convert.ToString(day["OpenedByName"])));

                int pending = Convert.ToInt32(t["PendingOrders"]);
                lblSales.Text        = Fmt(t["Sales"]);
                lblOrders.Text       = Convert.ToInt32(t["Orders"]).ToString("N0");
                lblPaidCount.Text    = Convert.ToInt32(t["ConfirmedOrders"]).ToString("N0");
                lblPending.Text      = pending.ToString("N0");
                lblCancelled.Text    = Convert.ToInt32(t["CancelledOrders"]).ToString("N0");
                lblCancelledAmt.Text = Fmt(t["CancelledAmount"]) + " not counted";
                lblSubtotal.Text     = Fmt(t["SubTotal"]);
                lblDiscount.Text     = Fmt(t["Discount"]);
                lblTax.Text          = Fmt(t["Tax"]);

                rptPayments.DataSource = ds.Tables[2];  rptPayments.DataBind();
                rptTakers.DataSource   = ds.Tables[3];  rptTakers.DataBind();
                lblNoPayments.Visible = ds.Tables[2].Rows.Count == 0;
                lblNoTakers.Visible   = ds.Tables[3].Rows.Count == 0;

                // Unpaid orders block the close (the database enforces it too).
                pnlBlocked.Visible = pending > 0;
                btnClose.Enabled   = pending == 0;
                if (pending > 0)
                    lblBlocked.Text = pending + " order(s) are still Pending (unpaid) and must be confirmed or cancelled before closing. ";
            }

            gvDays.DataSource = DBHelper.ExecuteDataTable("sp_GetBusinessDays", DBHelper.Parameter("@Top", 30));
            gvDays.DataBind();
        }

        private static string Fmt(object v) { return "Rs. " + Convert.ToDecimal(v).ToString("N0"); }
    }
}
