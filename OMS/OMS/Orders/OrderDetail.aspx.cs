using System;
using System.Data;
using OMS.Common.DAL;
using OMS.Common.Helpers;

namespace OMS.Orders
{
    public partial class OrderDetail : System.Web.UI.Page
    {
        protected string _statusBadgeClass = "badge-subtle-secondary";
        protected string _statusBadgeIcon = "fas fa-stream";

        private int OrderID
        {
            get { int id; return int.TryParse(Request.QueryString["id"], out id) ? id : 0; }
        }

        protected void Page_Load(object sender, EventArgs e)
        {
            SecurityHelper.RequireLogin();
            lnkPrint.HRef = "~/Reports/PrintInvoice.aspx?id=" + OrderID;

            if (!IsPostBack)
            {
                foreach (var s in new[] { "Pending", "Confirmed", "Preparing", "Ready", "Delivered", "Cancelled" })
                    ddlStatus.Items.Add(s);
                BindOrder();
            }
        }

        protected void btnUpdateStatus_Click(object sender, EventArgs e)
        {
            try
            {
                DBHelper.ExecuteNonQuery("sp_UpdateOrderStatus",
                    DBHelper.Parameter("@OrderID",   OrderID),
                    DBHelper.Parameter("@Status",    ddlStatus.SelectedValue),
                    DBHelper.Parameter("@UpdatedBy", SecurityHelper.UserID));

                lblStatusMsg.Text    = "Status updated to \"" + ddlStatus.SelectedValue + "\".";
                lblStatusMsg.Visible = true;
                BindOrder();
            }
            catch (Exception ex)
            {
                lblError.Text    = "Failed to update status: " + ex.Message;
                lblError.Visible = true;
            }
        }

        private void BindOrder()
        {
            if (OrderID == 0)
            {
                pnlNotFound.Visible = true;
                pnlContent.Visible  = false;
                return;
            }

            var ds = DBHelper.ExecuteDataSet("sp_GetOrderByID",
                DBHelper.Parameter("@OrderID", OrderID));

            if (ds.Tables.Count == 0 || ds.Tables[0].Rows.Count == 0)
            {
                pnlNotFound.Visible = true;
                pnlContent.Visible  = false;
                return;
            }

            DataRow row = ds.Tables[0].Rows[0];

            // Header
            lblOrderNumber.Text     = Convert.ToString(row["OrderNumber"]);
            lblOrderNumberCard.Text = Convert.ToString(row["OrderNumber"]);

            // Customer info
            lblCustomer.Text = NullDash(row["CustomerName"]);
            lblPhone.Text    = NullDash(row["CustomerPhone"]);

            string orderType = Convert.ToString(row["OrderType"]);
            lblOrderType.Text = orderType;

            if (orderType == "DineIn")
            {
                string tableNo = Convert.ToString(row["TableNumber"]);
                if (!string.IsNullOrEmpty(tableNo))
                {
                    pnlTableRow.Visible = true;
                    lblTableNo.Text     = tableNo;
                }
            }
            else if (orderType == "Delivery")
            {
                string addr = Convert.ToString(row["CustomerAddress"]);
                if (!string.IsNullOrEmpty(addr))
                {
                    pnlAddressRow.Visible = true;
                    lblAddress.Text       = addr;
                }
            }

            lblPaymentMethod.Text = Convert.ToString(row["PaymentMethod"]);
            lblPaymentStatus.Text = Convert.ToString(row["PaymentStatus"]);

            string notes = Convert.ToString(row["Notes"]);
            if (!string.IsNullOrEmpty(notes))
            {
                pnlNotes.Visible = true;
                lblNotes.Text    = notes;
            }

            string createdAt  = Convert.ToDateTime(row["CreatedAt"]).ToString("dd MMM yyyy, hh:mm tt");
            lblCreatedAt.Text     = createdAt;
            lblCreatedAtCard.Text = createdAt;

            // Totals
            decimal subtotal = Convert.ToDecimal(row["SubTotal"]);
            decimal discount = Convert.ToDecimal(row["DiscountAmount"]);
            decimal tax      = Convert.ToDecimal(row["TaxAmount"]);
            decimal total    = Convert.ToDecimal(row["TotalAmount"]);

            lblSubtotal.Text = Fmt(subtotal);
            lblDiscount.Text = discount > 0 ? "- " + Fmt(discount) : Fmt(0m);
            lblTax.Text      = Fmt(tax);
            lblTotal.Text    = Fmt(total);

            // Status
            string status        = Convert.ToString(row["Status"]);
            lblStatusBadge.Text  = status;
            _statusBadgeClass    = UiHelper.StatusBadgeClass(status);
            _statusBadgeIcon     = UiHelper.StatusBadgeIcon(status);
            try { ddlStatus.SelectedValue = status; } catch { }

            // Items
            gvItems.DataSource = ds.Tables.Count > 1 ? (object)ds.Tables[1] : null;
            gvItems.DataBind();
        }

        private static string Fmt(decimal v)    => "Rs. " + v.ToString("N0");
        private static string NullDash(object v) => string.IsNullOrEmpty(Convert.ToString(v)) ? "&mdash;" : Convert.ToString(v);
    }
}
