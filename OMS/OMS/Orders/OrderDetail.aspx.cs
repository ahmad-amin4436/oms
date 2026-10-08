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
                // Status follows payment (Pending/Confirmed); cancelling is the admin-only Cancel Order.
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
        // The cashier picks how the customer is paying: show the tax and total at THAT method's rate
        // right away. Nothing is saved until Confirm Payment is pressed (which uses the same rate).
        protected void ddlPayMethod_Changed(object sender, EventArgs e)
        {
            if (!SecurityHelper.IsInRole("Cashier", "Admin")) return;

            var ds = DBHelper.ExecuteDataSet("sp_GetOrderByID", DBHelper.Parameter("@OrderID", OrderID));
            if (ds.Tables.Count == 0 || ds.Tables[0].Rows.Count == 0) return;
            DataRow row = ds.Tables[0].Rows[0];
            if (Convert.ToString(row["Status"]) != "Pending") return;

            string method = ddlPayMethod.SelectedValue;
            lblPayHint.Text = "";
            if (method == Convert.ToString(row["PaymentMethod"]))
            {
                BindOrder();                          // back to the order's own saved tax
                return;
            }

            decimal sub  = Convert.ToDecimal(row["SubTotal"]);
            decimal disc = Convert.ToDecimal(row["DiscountAmount"]);
            decimal pct  = SettingsHelper.TaxPercentFor(method);
            decimal tax  = SettingsHelper.CalcTax(sub - disc, pct);
            decimal total = sub - disc + tax;

            lblTaxLabel.Text = "Tax (" + pct.ToString("0.##") + "%)";
            lblTax.Text      = Fmt(tax);
            lblTotal.Text    = Fmt(total);
            btnConfirmPayment.OnClientClick = "return confirm('Confirm that " + Fmt(total) + " was received?');";
            lblPayHint.Text  = "Tax shown at the " + ddlPayMethod.SelectedItem.Text + " rate (" + pct.ToString("0.##") + "%). It is saved when you confirm payment.";
        }

        protected void btnAddDish_Click(object sender, EventArgs e)
        {
            Page.Validate("AddDish");
            if (!Page.IsValid) return;

            int itemId, qty;
            if (!int.TryParse(txtAddQty.Text, out qty)) return;
            if (!int.TryParse(hfAddItem.Value, out itemId))   // the page script also checks this
            {
                lblError.Text    = "Pick a dish from the list.";
                lblError.Visible = true;
                return;
            }

            try
            {
                DBHelper.ExecuteNonQuery("sp_AddOrderItem",
                    DBHelper.Parameter("@OrderID",  OrderID),
                    DBHelper.Parameter("@ItemID",   itemId),
                    DBHelper.Parameter("@Quantity", qty),
                    DBHelper.Parameter("@AddedBy",  SecurityHelper.UserID == 0 ? (object)DBNull.Value : SecurityHelper.UserID));

                // Partial-page update: refresh the order in place (no reload). A browser refresh cannot
                // re-post this, because the document itself is never replaced by a partial postback.
                hfAddItem.Value = "";
                txtAddQty.Text  = "1";
                BindOrder();
                lblAddMsg.Text    = "Dish added. Totals updated.";
                lblAddMsg.Visible = true;
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

            if (string.IsNullOrEmpty(litDishList.Text))
            {
                var items = DBHelper.ExecuteDataTable("sp_GetMenuItems",
                    DBHelper.Parameter("@CategoryID", DBNull.Value),
                    DBHelper.Parameter("@IsAvailable", true));
                // Whole menu, grouped by category (sp_GetMenuItems already returns it in menu order).
                var sb = new System.Text.StringBuilder();
                string lastCat = null;
                foreach (DataRow r in items.Rows)
                {
                    string cat = Convert.ToString(r["CategoryName"]);
                    if (cat != lastCat)
                    {
                        sb.Append("<div data-header=\"1\" class=\"list-group-item bg-200 text-600 fs--2 text-uppercase py-1\">")
                          .Append(Server.HtmlEncode(cat)).Append("</div>");
                        lastCat = cat;
                    }
                    string price = Convert.ToDecimal(r["BasePrice"]).ToString("N0");
                    string label = Convert.ToString(r["Name"]) + " (Rs. " + price + ")";
                    sb.Append("<button type=\"button\" class=\"list-group-item list-group-item-action d-flex justify-content-between py-1 fs--1\" data-id=\"")
                      .Append(r["ItemID"]).Append("\" data-label=\"").Append(Server.HtmlEncode(label)).Append("\">")
                      .Append("<span>").Append(Server.HtmlEncode(Convert.ToString(r["Name"]))).Append("</span>")
                      .Append("<span class=\"text-600\">Rs. ").Append(price).Append("</span></button>");
                }
                litDishList.Text = sb.ToString();
            }

            if (Request.QueryString["added"] != null && !IsPostBack)
            {
                lblAddMsg.Text    = "Dish added. Totals updated.";
                lblAddMsg.Visible = true;
            }
        }

        // Pending -> Confirmed (paid). Server-side role check: hiding the panel is only a convenience,
        // and Order Takers/other roles must never be able to mark an order paid.
        protected void btnConfirmPayment_Click(object sender, EventArgs e)
        {
            if (!SecurityHelper.IsInRole("Cashier", "Admin"))
            {
                Response.Redirect("~/AccessDenied.aspx", false);
                Context.ApplicationInstance.CompleteRequest();
                return;
            }

            int cashierId = SecurityHelper.UserID;
            if (cashierId == 0) { SecurityHelper.RequireLogin(); return; }

            string method = ddlPayMethod.SelectedValue;
            try
            {
                // If the customer pays differently than the order was taken, re-price tax at that
                // method's rate (the order's stored rate is kept when the method is unchanged).
                var cur = DBHelper.ExecuteDataSet("sp_GetOrderByID", DBHelper.Parameter("@OrderID", OrderID));
                string orderMethod = cur.Tables[0].Rows.Count > 0 ? Convert.ToString(cur.Tables[0].Rows[0]["PaymentMethod"]) : "";
                object taxPct = method != orderMethod ? (object)SettingsHelper.TaxPercentFor(method) : DBNull.Value;

                DBHelper.ExecuteNonQuery("sp_ConfirmOrder",
                    DBHelper.Parameter("@OrderID",       OrderID),
                    DBHelper.Parameter("@ConfirmedBy",   cashierId),
                    DBHelper.Parameter("@PaymentMethod", method),
                    DBHelper.Parameter("@TaxPercent",    taxPct));

                lblStatusMsg.Text    = "Payment confirmed. The order is now Confirmed (paid).";
                lblStatusMsg.Visible = true;
                BindOrder();
            }
            catch (Exception ex)
            {
                lblError.Text    = "Could not confirm payment: " + ex.Message;
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

            // Order taker and business day (the order's day, not today's).
            lblTaker.Text = NullDash(row["CreatedByName"]);
            lblBusinessDay.Text = row["BusinessDate"] == DBNull.Value ? "&mdash;"
                : Convert.ToDateTime(row["BusinessDate"]).ToString("dd MMM yyyy");

            bool cancelled = status == "Cancelled";
            bool pending   = status == "Pending";
            bool confirmed = status == "Confirmed";
            bool dayClosed = Convert.ToInt32(row["DayClosed"]) == 1;
            bool canConfirm = SecurityHelper.IsInRole("Cashier", "Admin");

            // Payment panel: Cashier/Admin can confirm an unpaid order; others see its state.
            pnlPayment.Visible  = !cancelled;
            pnlConfirm.Visible  = pending && canConfirm;   // an order from a closed day is settled into the current day
            pnlAwaiting.Visible = pending && !canConfirm;
            pnlPaidInfo.Visible = confirmed;
            if (pnlConfirm.Visible)
            {
                try { ddlPayMethod.SelectedValue = Convert.ToString(row["PaymentMethod"]); } catch { }
                btnConfirmPayment.OnClientClick = "return confirm('Confirm that " + Fmt(total) + " was received?');";
            }
            if (confirmed)
            {
                string when = row["PaidAt"] == DBNull.Value ? "" : " on " + Convert.ToDateTime(row["PaidAt"]).ToString("dd MMM yyyy, hh:mm tt");
                string who  = string.IsNullOrEmpty(Convert.ToString(row["ConfirmedByName"])) ? "" : " - confirmed by " + Server.HtmlEncode(Convert.ToString(row["ConfirmedByName"]));
                lblPaidInfo.Text = "Paid" + when + who;
            }

            // Cancel: Admin only; paid orders of a closed business day are final.
            pnlCancel.Visible       = !cancelled && SecurityHelper.IsInRole("Admin") && !(confirmed && dayClosed);
            pnlCancelInfo.Visible   = cancelled;
            // Dishes can only be added while the order is unpaid and its day is open.
            BindAddDish(pending && !dayClosed);
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
