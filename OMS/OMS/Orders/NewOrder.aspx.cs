using System;
using System.Collections.Generic;
using System.Data;
using System.Linq;
using System.Web;
using System.Web.UI.WebControls;
using OMS.Common.DAL;
using OMS.Common.Helpers;

namespace OMS.Orders
{
    // Stored in ViewState — must be serializable
    [Serializable]
    public class CartItem
    {
        public int     ItemID    { get; set; }
        public string  Name      { get; set; }
        public decimal UnitPrice { get; set; }
        public int     Qty       { get; set; }
        public decimal LineTotal { get { return Math.Round(UnitPrice * Qty, 2); } }
    }

    public partial class NewOrder : System.Web.UI.Page
    {
        // ── ViewState helpers ────────────────────────────────────────

        private List<CartItem> Cart
        {
            get { return (ViewState["Cart"] as List<CartItem>) ?? new List<CartItem>(); }
            set { ViewState["Cart"] = value; }
        }

        private int? SelectedCategory
        {
            get { return ViewState["SelCat"] as int?; }
            set { ViewState["SelCat"] = value; }
        }

        // ── Lifecycle ────────────────────────────────────────────────

        protected void Page_Load(object sender, EventArgs e)
        {
            SecurityHelper.RequireRoles("Admin", "Manager", "Cashier", "Waiter");
            // Always bind so the Repeater control trees exist for event routing on postback
            BindAll();
        }

        // ── Bind helpers ─────────────────────────────────────────────

        private void BindAll()
        {
            BindCategories();
            BindMenuItems(SelectedCategory);
            BindCart();
            ApplyLayout();
        }

        private void BindCategories()
        {
            lbAllCat.CssClass = NavPillCss(!SelectedCategory.HasValue);
            try
            {
                var dt = DBHelper.ExecuteDataTable("sp_GetMenuCategories");
                rptCategories.DataSource = dt.Rows.Count > 0 ? (object)dt : null;
            }
            catch
            {
                rptCategories.DataSource = null;
            }
            rptCategories.DataBind();
        }

        private void BindMenuItems(int? categoryId)
        {
            var catParam = categoryId.HasValue
                ? DBHelper.Parameter("@CategoryID", categoryId.Value)
                : DBHelper.Parameter("@CategoryID", DBNull.Value);

            var dt = DBHelper.ExecuteDataTable(
                "sp_GetMenuItems",
                catParam,
                DBHelper.Parameter("@IsAvailable", true));

            pnlNoItems.Visible = (dt.Rows.Count == 0);
            rptMenu.DataSource = dt.Rows.Count > 0 ? (object)dt : null;
            rptMenu.DataBind();
        }

        private void BindCart()
        {
            var cart     = Cart;
            bool hasItems = cart.Count > 0;

            pnlEmptyCart.Visible = !hasItems;
            pnlCart.Visible      =  hasItems;

            rptCart.DataSource = hasItems ? (object)cart : null;
            rptCart.DataBind();

            CalcAndDisplayTotals(cart);
        }

        private void CalcAndDisplayTotals(List<CartItem> cart)
        {
            decimal subtotal = cart.Sum(c => c.LineTotal);

            decimal discPct = 0m;
            decimal.TryParse(txtDiscountPct.Text, out discPct);
            discPct = Math.Max(0m, Math.Min(100m, discPct));

            decimal discount = Math.Round(subtotal * discPct / 100m, 2);
            decimal taxable  = subtotal - discount;
            decimal tax      = Math.Round(taxable * 0.16m, 2);
            decimal total    = taxable + tax;

            lblSubtotal.Text    = Fmt(subtotal);
            lblDiscountAmt.Text = discount > 0 ? "- " + Fmt(discount) : Fmt(0);
            lblTax.Text         = Fmt(tax);
            lblTotal.Text       = Fmt(total);
        }

        private void ApplyLayout()
        {
            string type = ddlOrderType.SelectedValue;
            pnlTableNo.Visible = (type == "DineIn");
            pnlAddress.Visible = (type == "Delivery");
        }

        // ── ASPX binding helpers ─────────────────────────────────────

        protected string GetCatCss(object catId)
        {
            int id     = Convert.ToInt32(catId);
            bool active = SelectedCategory.HasValue && SelectedCategory.Value == id;
            return NavPillCss(active);
        }

        private static string NavPillCss(bool active)
            => "nav-link py-1 px-2 fs--1" + (active ? " active" : "");

        // Encodes ItemID|BasePrice|URLEncodedName into a single CommandArgument string
        protected string EncodeArg(object itemId, object price, object name)
            => itemId + "|" + price + "|" + HttpUtility.UrlEncode(name?.ToString() ?? "");

        private static string Fmt(decimal v) => "Rs. " + v.ToString("N0");

        // ── Category filter events ───────────────────────────────────

        protected void lbAllCat_Click(object sender, EventArgs e)
        {
            SelectedCategory = null;
            BindAll();
        }

        protected void rptCategories_ItemCommand(object source, RepeaterCommandEventArgs e)
        {
            if (e.CommandName == "Filter")
            {
                SelectedCategory = Convert.ToInt32(e.CommandArgument);
                BindAll();
            }
        }

        // ── Menu item add event ──────────────────────────────────────

        protected void rptMenu_ItemCommand(object source, RepeaterCommandEventArgs e)
        {
            if (e.CommandName != "Add") return;

            // CommandArgument = "ItemID|BasePrice|URLEncodedName"
            var parts = e.CommandArgument.ToString().Split(new[] { '|' }, 3);
            if (parts.Length < 3) return;

            int     itemId = Convert.ToInt32(parts[0]);
            decimal price  = Convert.ToDecimal(parts[1]);
            string  name   = HttpUtility.UrlDecode(parts[2]);

            var cart     = Cart;
            var existing = cart.FirstOrDefault(c => c.ItemID == itemId);
            if (existing != null)
                existing.Qty++;
            else
                cart.Add(new CartItem { ItemID = itemId, Name = name, UnitPrice = price, Qty = 1 });

            Cart = cart;
            BindCart();
        }

        // ── Cart events ──────────────────────────────────────────────

        protected void rptCart_ItemCommand(object source, RepeaterCommandEventArgs e)
        {
            int itemId = Convert.ToInt32(e.CommandArgument);
            var cart   = Cart;
            var item   = cart.FirstOrDefault(c => c.ItemID == itemId);
            if (item == null) return;

            switch (e.CommandName)
            {
                case "Plus":   item.Qty++;                          break;
                case "Minus":  item.Qty--; if (item.Qty <= 0) cart.Remove(item); break;
                case "Remove": cart.Remove(item);                   break;
            }

            Cart = cart;
            BindCart();
        }

        protected void lbClearCart_Click(object sender, EventArgs e)
        {
            Cart = new List<CartItem>();
            BindCart();
        }

        protected void ddlOrderType_Changed(object sender, EventArgs e)
        {
            ApplyLayout();
        }

        protected void txtDiscountPct_Changed(object sender, EventArgs e)
        {
            BindCart();
        }

        // ── Place Order ──────────────────────────────────────────────

        protected void btnPlaceOrder_Click(object sender, EventArgs e)
        {
            var cart = Cart;

            if (cart.Count == 0)
            {
                ShowError("Please add at least one item to the order.");
                return;
            }

            decimal discPct = 0m;
            decimal.TryParse(txtDiscountPct.Text, out discPct);
            discPct = Math.Max(0m, Math.Min(100m, discPct));

            decimal subtotal  = cart.Sum(c => c.LineTotal);
            decimal discount  = Math.Round(subtotal * discPct / 100m, 2);
            decimal taxable   = subtotal - discount;
            decimal tax       = Math.Round(taxable * 0.16m, 2);
            decimal total     = taxable + tax;

            string tableNo  = txtTableNo.Text.Trim();
            object tableNum = string.IsNullOrEmpty(tableNo) ? (object)DBNull.Value : tableNo;

            try
            {
                var outId = DBHelper.OutputParameter("@OrderID", SqlDbType.Int);

                DBHelper.ExecuteNonQuery("sp_CreateOrder",
                    DBHelper.Parameter("@CustomerName",   txtCustomerName.Text.Trim()),
                    DBHelper.Parameter("@Phone",          txtPhone.Text.Trim()),
                    DBHelper.Parameter("@Address",        txtAddress.Text.Trim()),
                    DBHelper.Parameter("@TableNumber",    tableNum),
                    DBHelper.Parameter("@OrderType",      ddlOrderType.SelectedValue),
                    DBHelper.Parameter("@PaymentMethod",  ddlPaymentMethod.SelectedValue),
                    DBHelper.Parameter("@PaymentStatus",  "Pending"),
                    DBHelper.Parameter("@SubTotal",       subtotal),
                    DBHelper.Parameter("@DiscountAmount", discount),
                    DBHelper.Parameter("@TaxAmount",      tax),
                    DBHelper.Parameter("@TotalAmount",    total),
                    DBHelper.Parameter("@CouponID",       DBNull.Value),
                    DBHelper.Parameter("@Notes",          string.IsNullOrEmpty(txtNotes.Text) ? (object)DBNull.Value : txtNotes.Text),
                    DBHelper.Parameter("@CreatedBy",      SecurityHelper.UserID == 0 ? (object)DBNull.Value : SecurityHelper.UserID),
                    outId);

                int orderId = Convert.ToInt32(outId.Value);

                foreach (var item in cart)
                    DBHelper.ExecuteNonQuery("sp_InsertOrderItem",
                        DBHelper.Parameter("@OrderID",   orderId),
                        DBHelper.Parameter("@ItemID",    item.ItemID),
                        DBHelper.Parameter("@Quantity",  item.Qty),
                        DBHelper.Parameter("@UnitPrice", item.UnitPrice),
                        DBHelper.Parameter("@LineTotal", item.LineTotal));

                Cart = new List<CartItem>();
                Response.Redirect("~/Orders/OrderDetail.aspx?id=" + orderId, false);
                Context.ApplicationInstance.CompleteRequest();
            }
            catch (Exception ex)
            {
                ShowError("Failed to place order: " + ex.Message);
            }
        }

        private void ShowError(string msg)
        {
            lblError.Text    = msg;
            lblError.Visible = true;
        }
    }
}
