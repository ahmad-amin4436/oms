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
        // Unique per cart line so deal lines never collide with à-la-carte lines
        // that reference the same MenuItem.ItemID.
        public string  Key       { get; set; }
        public int     ItemID    { get; set; }
        public string  Name      { get; set; }
        public decimal UnitPrice { get; set; }
        public int     Qty       { get; set; }
        // Non-empty when this line came from a deal (shown as a badge, not merged).
        public string  DealName  { get; set; }
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

        private string SearchTerm
        {
            get { return (ViewState["Search"] as string) ?? string.Empty; }
            set { ViewState["Search"] = value; }
        }

        // ── Lifecycle ────────────────────────────────────────────────

        protected void Page_Load(object sender, EventArgs e)
        {
            SecurityHelper.RequireUrlAccess();

            // Bind only on first load. On postback the Repeater control trees are
            // rebuilt from ViewState, which is what lets ItemCommand events route to
            // their handlers. Re-binding (DataBind) here would recreate the child
            // controls and swallow the click — that is why the category tabs, search
            // and Add buttons appeared "not working". Each event handler re-binds the
            // parts it changes after updating state.
            if (!IsPostBack)
                BindAll();
        }

        // ── Bind helpers ─────────────────────────────────────────────

        private void BindAll()
        {
            BindDeals(SearchTerm);
            BindCategories();
            BindMenuItems(SelectedCategory, SearchTerm);
            BindCart();
            ApplyLayout();
        }

        // Loads active deals and shows them as cards above the menu grid. Each card
        // displays the deal price and (struck-through) the original sum of its items.
        // When a search term is given, deals are matched on their title or member items.
        private void BindDeals(string search)
        {
            DataSet ds;
            try
            {
                ds = DBHelper.ExecuteDataSet("sp_GetActiveDealsWithItems");
            }
            catch
            {
                pnlDeals.Visible = false;
                return;
            }

            if (ds.Tables.Count < 1 || ds.Tables[0].Rows.Count == 0)
            {
                pnlDeals.Visible = false;
                return;
            }

            DataTable deals = ds.Tables[0];
            DataTable items = ds.Tables.Count > 1 ? ds.Tables[1] : new DataTable();

            // Original price = sum of member item BasePrices, per deal.
            var originalByDeal = new Dictionary<int, decimal>();
            var namesByDeal    = new Dictionary<int, List<string>>();
            foreach (DataRow r in items.Rows)
            {
                int dealId = Convert.ToInt32(r["DealID"]);
                decimal bp = Convert.ToDecimal(r["BasePrice"]);
                originalByDeal[dealId] = (originalByDeal.TryGetValue(dealId, out var o) ? o : 0m) + bp;
                if (!namesByDeal.TryGetValue(dealId, out var list)) { list = new List<string>(); namesByDeal[dealId] = list; }
                list.Add(Convert.ToString(r["ItemName"]));
            }

            var view = new DataTable();
            view.Columns.Add("DealID", typeof(int));
            view.Columns.Add("Title", typeof(string));
            view.Columns.Add("ItemsLabel", typeof(string));
            view.Columns.Add("DealPrice", typeof(decimal));
            view.Columns.Add("OriginalPrice", typeof(decimal));

            foreach (DataRow d in deals.Rows)
            {
                int dealId   = Convert.ToInt32(d["DealID"]);
                decimal orig = originalByDeal.TryGetValue(dealId, out var o) ? o : 0m;
                decimal price = ComputeDealPrice(d, orig);
                string itemsLabel = namesByDeal.TryGetValue(dealId, out var names)
                    ? string.Join(", ", names) : "";

                view.Rows.Add(dealId, Convert.ToString(d["Title"]), itemsLabel,
                    Math.Round(price, 0), Math.Round(orig, 0));
            }

            // Match the search on the deal title or any of its member item names.
            DataView dv = view.DefaultView;
            if (!string.IsNullOrWhiteSpace(search))
            {
                string safe = search.Trim().Replace("'", "''").Replace("[", "[[]").Replace("%", "[%]");
                dv.RowFilter = $"Title LIKE '%{safe}%' OR ItemsLabel LIKE '%{safe}%'";
            }

            bool hasDeals = dv.Count > 0;
            rptDeals.DataSource = hasDeals ? (object)dv : null;
            rptDeals.DataBind();
            pnlDeals.Visible = hasDeals;
        }

        // The effective price of a whole deal given the sum of its item base prices.
        private static decimal ComputeDealPrice(DataRow deal, decimal originalSum)
        {
            string type = Convert.ToString(deal["DealType"]);
            decimal value = Convert.ToDecimal(deal["DiscountValue"]);

            if (type == "BundlePrice")
                return deal["DealPrice"] == DBNull.Value ? originalSum : Convert.ToDecimal(deal["DealPrice"]);
            if (type == "Percentage")
                return Math.Round(originalSum * (1 - value / 100m), 2);
            // Flat amount off the whole bundle (never below zero).
            return Math.Max(0m, originalSum - value);
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

        private void BindMenuItems(int? categoryId, string search)
        {
            var catParam = categoryId.HasValue
                ? DBHelper.Parameter("@CategoryID", categoryId.Value)
                : DBHelper.Parameter("@CategoryID", DBNull.Value);

            var dt = DBHelper.ExecuteDataTable(
                "sp_GetMenuItems",
                catParam,
                DBHelper.Parameter("@IsAvailable", true));

            // sp_GetMenuItems has no text filter, so apply the search in-memory on Name/Description.
            DataView view = dt.DefaultView;
            if (!string.IsNullOrWhiteSpace(search))
            {
                string safe = search.Trim().Replace("'", "''").Replace("[", "[[]").Replace("%", "[%]");
                view.RowFilter = $"Name LIKE '%{safe}%' OR Description LIKE '%{safe}%'";
            }

            bool hasRows = view.Count > 0;
            // Don't show the "no items" empty-state if matching deals are on screen —
            // the search did return something (a deal), just not an à-la-carte item.
            pnlNoItems.Visible = !hasRows && !pnlDeals.Visible;
            rptMenu.DataSource = hasRows ? (object)view : null;
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

            int totalQty = cart.Sum(c => c.Qty);
            lblCartCount.Text = totalQty == 1 ? "1 item" : totalQty + " items";

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
            bool isDineIn   = (type == "DineIn");
            bool isDelivery = (type == "Delivery");

            pnlTableNo.Visible = isDineIn;
            pnlAddress.Visible = isDelivery;

            // Only validate the field that is actually shown for the chosen order type.
            rfvTableNo.Enabled = isDineIn;
            rfvAddress.Enabled = isDelivery;

            // Clear fields that no longer apply so stale values are never submitted.
            if (!isDineIn)   txtTableNo.Text = string.Empty;
            if (!isDelivery) txtAddress.Text = string.Empty;
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

        protected void txtSearch_Changed(object sender, EventArgs e)
        {
            SearchTerm = txtSearch.Text;
            BindAll();
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
            // Merge only with an existing à-la-carte line for the same item
            // (deal lines carry a DealName and are kept separate).
            var existing = cart.FirstOrDefault(c => c.ItemID == itemId && string.IsNullOrEmpty(c.DealName));
            if (existing != null)
                existing.Qty++;
            else
                cart.Add(new CartItem { Key = NewKey(), ItemID = itemId, Name = name, UnitPrice = price, Qty = 1 });

            Cart = cart;
            BindCart();
        }

        // ── Deal add event ───────────────────────────────────────────

        protected void rptDeals_ItemCommand(object source, RepeaterCommandEventArgs e)
        {
            if (e.CommandName != "AddDeal") return;

            int dealId = Convert.ToInt32(e.CommandArgument);

            var ds = DBHelper.ExecuteDataSet("sp_GetActiveDealsWithItems");
            if (ds.Tables.Count < 2) return;

            DataRow deal = ds.Tables[0].AsEnumerable()
                .FirstOrDefault(r => Convert.ToInt32(r["DealID"]) == dealId);
            var dealItems = ds.Tables[1].AsEnumerable()
                .Where(r => Convert.ToInt32(r["DealID"]) == dealId).ToList();
            if (deal == null || dealItems.Count == 0) return;

            string dealName  = Convert.ToString(deal["Title"]);
            decimal original = dealItems.Sum(r => Convert.ToDecimal(r["BasePrice"]));
            decimal dealPrice = ComputeDealPrice(deal, original);

            // Distribute the deal price across the member items in proportion to
            // their base price, so the line totals sum to the deal price. The last
            // line absorbs any rounding remainder.
            var cart = Cart;
            decimal allocated = 0m;
            for (int i = 0; i < dealItems.Count; i++)
            {
                var r       = dealItems[i];
                int itemId  = Convert.ToInt32(r["ItemID"]);
                string name = Convert.ToString(r["ItemName"]);
                decimal bp  = Convert.ToDecimal(r["BasePrice"]);

                decimal linePrice;
                if (i == dealItems.Count - 1)
                    linePrice = Math.Round(dealPrice - allocated, 2);          // remainder
                else
                {
                    linePrice = original > 0
                        ? Math.Round(dealPrice * (bp / original), 2)
                        : Math.Round(dealPrice / dealItems.Count, 2);
                    allocated += linePrice;
                }

                cart.Add(new CartItem
                {
                    Key       = NewKey(),
                    ItemID    = itemId,
                    Name      = name,
                    UnitPrice = linePrice,
                    Qty       = 1,
                    DealName  = dealName
                });
            }

            Cart = cart;
            BindCart();
        }

        private static string NewKey() => Guid.NewGuid().ToString("N");

        // ── Cart events ──────────────────────────────────────────────

        protected void rptCart_ItemCommand(object source, RepeaterCommandEventArgs e)
        {
            string key = Convert.ToString(e.CommandArgument);
            var cart   = Cart;
            var item   = cart.FirstOrDefault(c => c.Key == key);
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
            // Server-side guard — the client-side OnClientClick is only a convenience.
            Page.Validate("PlaceOrder");
            if (!Page.IsValid)
                return;

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
            lblError.Text    = "<span class=\"fas fa-exclamation-circle me-2\"></span>" +
                               HttpUtility.HtmlEncode(msg);
            lblError.Visible = true;
        }
    }
}
