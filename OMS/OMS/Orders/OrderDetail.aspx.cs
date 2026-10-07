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
            SecurityHelper.RequireUrlAccess();
            lnkPrint.HRef = "~/Reports/PrintInvoice.aspx?id=" + OrderID;
            lnkPrint.Visible     = SecurityHelper.CanOpen("~/Reports/PrintInvoice.aspx");
            lnkAllOrders.Visible = SecurityHelper.CanOpen("~/Orders/OrderList.aspx");

            if (!IsPostBack)
            {
                // "Cancelled" is deliberately absent: cancelling is the admin-only
                // Cancel Order action (sp_CancelOrder), not a plain status change.
                foreach (var s in new[] { "Pending", "Confirmed", "Preparing", "Ready", "Delivered" })
                    ddlStatus.Items.Add(s);
                BindOrder();
            }
        }

        protected void btnCancelOrder_Click(object sender, EventArgs e)
        {
            // Server-side authorization — hiding the panel is only a convenience.
            if (!SecurityHelper.IsInRole("Admin"))
            {
                Response.Redirect("~/AccessDenied.aspx", false);
                return;
            }

            Page.Validate("CancelOrder");
            if (!Page.IsValid) return;

            try
            {
                DBHelper.ExecuteNonQuery("sp_CancelOrder",
                    DBHelper.Parameter("@OrderID",     OrderID),
                    DBHelper.Parameter("@CancelledBy", SecurityHelper.UserID == 0 ? (object)DBNull.Value : SecurityHelper.UserID),
                    DBHelper.Parameter("@Reason",      txtCancelReason.Text.Trim()));

                txtCancelReason.Text = "";
                lblStatusMsg.Text    = "Order cancelled.";
                lblStatusMsg.Visible = true;
                BindOrder();
            }
            catch (Exception ex)
            {
                lblError.Text    = "Failed to cancel order: " + ex.Message;
                lblError.Visible = true;
            }
        }

        // Dishes can be added to an open order but never removed. The price and the
        // status rule are enforced in sp_AddOrderItem, not trusted from the page.
        protected void btnAddDish_Click(object sender, EventArgs e)
        {
            Page.Validate("AddDish");
            if (!Page.IsValid) return;

            int itemId, qty;
            if (!int.TryParse(ddlAddItem.SelectedValue, out itemId) || !int.TryParse(txtAddQty.Text, out qty))
                return;

            try
            {
                DBHelper.ExecuteNonQuery("sp_AddOrderItem",
                    DBHelper.Parameter("@OrderID",  OrderID),
                    DBHelper.Parameter("@ItemID",   itemId),
                    DBHelper.Parameter("@Quantity", qty),
                    DBHelper.Parameter("@AddedBy",  SecurityHelper.UserID == 0 ? (object)DBNull.Value : SecurityHelper.UserID));

                // Redirect so a browser refresh cannot add the dish twice.
                Response.Redirect("~/Orders/OrderDetail.aspx?id=" + OrderID + "&added=1", false);
                Context.ApplicationInstance.CompleteRequest();
            }
            catch (Exception ex)
            {
                lblError.Text    = "Could not add the dish: " + ex.Message;
                lblError.Visible = true;
            }
        }

        private void BindAddDish(bool open)
        {
            pnlAddDish.Visible = open;
            if (!open) return;

            if (ddlAddItem.Items.Count == 0)
            {
                ddlAddItem.Items.Add(new System.Web.UI.WebControls.ListItem("Select a dish...", ""));
                var items = DBHelper.ExecuteDataTable("sp_GetMenuItems",
                    DBHelper.Parameter("@CategoryID", DBNull.Value),
                    DBHelper.Parameter("@IsAvailable", true));
                foreach (DataRow r in items.Rows)
                    ddlAddItem.Items.Add(new System.Web.UI.WebControls.ListItem(
                        Convert.ToString(r["CategoryName"]) + " - " + Convert.ToString(r["Name"]) +
                        "  (Rs. " + Convert.ToDecimal(r["BasePrice"]).ToString("N0") + ")",
                        Convert.ToString(r["ItemID"])));
            }

            if (Request.QueryString["added"] != null && !IsPostBack)
            {
                lblAddMsg.Text    = "Dish added. Totals updated.";
                lblAddMsg.Visible = true;
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

            // Rate is the one stored with the order, never the current setting.
            string taxLabel  = SettingsHelper.TaxLabel(row["TaxPercent"], subtotal, discount, tax);
            lblTaxLabel.Text = taxLabel.Length > 0 ? "Tax (" + taxLabel + ")" : "Tax";

            // Status
            string status        = Convert.ToString(row["Status"]);
            lblStatusBadge.Text  = status;
            _statusBadgeClass    = UiHelper.StatusBadgeClass(status);
            _statusBadgeIcon     = UiHelper.StatusBadgeIcon(status);
            try { ddlStatus.SelectedValue = status; } catch { }

            bool cancelled = status == "Cancelled";
            pnlUpdateStatus.Visible = !cancelled;
            pnlCancel.Visible       = !cancelled && status != "Delivered" && SecurityHelper.IsInRole("Admin");
            pnlCancelInfo.Visible   = cancelled;
            BindAddDish(!cancelled && status != "Delivered");
            if (cancelled)
            {
                lblCancelledAt.Text = row["CancelledAt"] == DBNull.Value ? "&mdash;"
                    : Convert.ToDateTime(row["CancelledAt"]).ToString("dd MMM yyyy, hh:mm tt");
                lblCancelledBy.Text = NullDash(row["CancelledByName"]);
                lblCancelReason.Text = Server.HtmlEncode(Convert.ToString(row["CancelReason"]));
            }

            // Items
            gvItems.DataSource = ds.Tables.Count > 1 ? (object)ds.Tables[1] : null;
            gvItems.DataBind();
        }

        private static string Fmt(decimal v)    => "Rs. " + v.ToString("N0");
        private static string NullDash(object v) => string.IsNullOrEmpty(Convert.ToString(v)) ? "&mdash;" : Convert.ToString(v);
    }
}
