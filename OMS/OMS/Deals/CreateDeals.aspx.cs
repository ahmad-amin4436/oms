using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.Linq;
using System.Web.UI.HtmlControls;
using System.Web.UI.WebControls;
using OMS.Common.DAL;
using OMS.Common.Helpers;

namespace OMS.Deals
{
    public partial class CreateDeals : System.Web.UI.Page
    {
        // Items grouped by CategoryID for binding the nested item repeater
        // during a BindItemPicker call (read in rptDealCats_ItemDataBound).
        private Dictionary<int, DataTable> _itemsByCategory;

        protected void Page_Load(object sender, EventArgs e)
        {
            SecurityHelper.RequireUrlAccess();

            if (!IsPostBack)
            {
                int dealId;
                if (int.TryParse(Request.QueryString["id"], out dealId) && dealId > 0)
                    LoadDeal(dealId);
                else
                    ResetForm();
            }
        }

        // ── Deal type toggle ─────────────────────────────────────────

        protected void ddlDealType_SelectedIndexChanged(object sender, EventArgs e)
        {
            ApplyDealTypeUI();
        }

        // Shows the value field relevant to the selected deal type.
        private void ApplyDealTypeUI()
        {
            bool isBundle = ddlDealType.SelectedValue == "BundlePrice";
            pnlBundle.Visible   = isBundle;
            pnlDiscount.Visible = !isBundle;
            litValueLabel.Text  = ddlDealType.SelectedValue == "Percentage"
                ? "Discount (%)" : "Discount (Rs.)";
        }

        // ── Load / Reset ─────────────────────────────────────────────

        private void LoadDeal(int dealId)
        {
            var dt = DBHelper.ExecuteDataTable("sp_GetDealByID",
                DBHelper.Parameter("@DealID", dealId));
            if (dt.Rows.Count == 0)
            {
                ShowErr("That deal no longer exists.");
                ResetForm();
                return;
            }

            var row = dt.Rows[0];
            litTitle.Text   = "Edit Deal";
            hfDealID.Value  = dealId.ToString();
            txtTitle.Text       = Convert.ToString(row["Title"]);
            txtDescription.Text = row["Description"] == DBNull.Value ? "" : Convert.ToString(row["Description"]);
            chkActive.Checked   = Convert.ToBoolean(row["IsActive"]);
            txtStartDate.Text   = Convert.ToDateTime(row["StartDate"]).ToString("yyyy-MM-dd");
            txtEndDate.Text     = Convert.ToDateTime(row["EndDate"]).ToString("yyyy-MM-dd");

            var typeItem = ddlDealType.Items.FindByValue(Convert.ToString(row["DealType"]));
            if (typeItem != null) { ddlDealType.ClearSelection(); typeItem.Selected = true; }

            txtDiscountValue.Text = Convert.ToDecimal(row["DiscountValue"]).ToString("0.##");
            txtDealPrice.Text     = row["DealPrice"] == DBNull.Value
                ? "" : Convert.ToDecimal(row["DealPrice"]).ToString("0.##");

            ApplyDealTypeUI();

            // Pre-select the items already attached to this deal.
            var selected = DBHelper.ExecuteDataTable("sp_GetDealItems",
                DBHelper.Parameter("@DealID", dealId))
                .AsEnumerable()
                .Select(r => Convert.ToInt32(r["ItemID"]))
                .ToHashSet();
            BindItemPicker(selected);
        }

        private void ResetForm()
        {
            litTitle.Text = "Create Deal";
            hfDealID.Value = "0";
            txtTitle.Text = "";
            txtDescription.Text = "";
            txtDiscountValue.Text = "";
            txtDealPrice.Text = "";
            txtStartDate.Text = DateTime.UtcNow.AddHours(5).ToString("yyyy-MM-dd");
            txtEndDate.Text   = DateTime.UtcNow.AddHours(5).AddDays(7).ToString("yyyy-MM-dd");
            chkActive.Checked = true;
            ddlDealType.SelectedIndex = 0;
            ApplyDealTypeUI();
            BindItemPicker(new HashSet<int>());
        }

        // ── Menu-item picker ─────────────────────────────────────────

        // Builds the category -> items structure with a Selected flag and binds
        // the outer (category) repeater. Items render via rptDealCats_ItemDataBound.
        private void BindItemPicker(HashSet<int> selectedItemIds)
        {
            var items = DBHelper.ExecuteDataTable("sp_GetMenuItemsForDeal");

            _itemsByCategory = new Dictionary<int, DataTable>();
            var cats = new DataTable();
            cats.Columns.Add("CategoryID", typeof(int));
            cats.Columns.Add("CategoryName", typeof(string));

            foreach (DataRow it in items.Rows)
            {
                int catId  = Convert.ToInt32(it["CategoryID"]);
                int itemId = Convert.ToInt32(it["ItemID"]);

                if (!_itemsByCategory.TryGetValue(catId, out var tbl))
                {
                    tbl = NewItemTable();
                    _itemsByCategory[catId] = tbl;
                    cats.Rows.Add(catId, Convert.ToString(it["CategoryName"]));
                }

                tbl.Rows.Add(itemId,
                    Convert.ToString(it["ItemName"]),
                    Convert.ToBoolean(it["IsAvailable"]),
                    selectedItemIds.Contains(itemId));
            }

            pnlNoItems.Visible   = cats.Rows.Count == 0;
            rptDealCats.DataSource = cats;
            rptDealCats.DataBind();
        }

        protected void rptDealCats_ItemDataBound(object sender, RepeaterItemEventArgs e)
        {
            if (e.Item.ItemType != ListItemType.Item && e.Item.ItemType != ListItemType.AlternatingItem)
                return;

            var hf = (HtmlInputHidden)e.Item.FindControl("hfCategoryId");
            var rptItems = (Repeater)e.Item.FindControl("rptDealItems");
            if (hf == null || rptItems == null) return;

            int catId = Convert.ToInt32(hf.Value);
            if (_itemsByCategory != null && _itemsByCategory.TryGetValue(catId, out var tbl))
            {
                rptItems.DataSource = tbl;
                rptItems.DataBind();
            }
        }

        // Reads the checked menu-item IDs back out of the picker repeaters.
        private List<string> CollectSelectedItemIds()
        {
            var ids = new List<string>();
            foreach (RepeaterItem cat in rptDealCats.Items)
            {
                var rptItems = (Repeater)cat.FindControl("rptDealItems");
                if (rptItems == null) continue;

                foreach (RepeaterItem it in rptItems.Items)
                {
                    var chk = (CheckBox)it.FindControl("chkItem");
                    var hf  = (HtmlInputHidden)it.FindControl("hfItemId");
                    if (chk != null && hf != null && chk.Checked)
                        ids.Add(hf.Value);
                }
            }
            return ids;
        }

        private static DataTable NewItemTable()
        {
            var t = new DataTable();
            t.Columns.Add("ItemID", typeof(int));
            t.Columns.Add("ItemName", typeof(string));
            t.Columns.Add("IsAvailable", typeof(bool));
            t.Columns.Add("Selected", typeof(bool));
            return t;
        }

        protected void btnReset_Click(object sender, EventArgs e)
        {
            ResetForm();
        }

        // ── Save ─────────────────────────────────────────────────────

        protected void btnSave_Click(object sender, EventArgs e)
        {
            if (!Page.IsValid) return;

            int dealId = 0;
            int.TryParse(hfDealID.Value, out dealId);

            string dealType = ddlDealType.SelectedValue;
            bool isBundle = dealType == "BundlePrice";

            decimal discountValue = 0;
            decimal? dealPrice = null;

            if (isBundle)
            {
                decimal price;
                if (!decimal.TryParse(txtDealPrice.Text.Trim(), out price) || price < 0)
                {
                    ShowErr("Enter a valid bundle price.");
                    return;
                }
                dealPrice = price;
            }
            else
            {
                if (!decimal.TryParse(txtDiscountValue.Text.Trim(), out discountValue) || discountValue < 0)
                {
                    ShowErr("Enter a valid discount value.");
                    return;
                }
                if (dealType == "Percentage" && discountValue > 100)
                {
                    ShowErr("A percentage discount cannot exceed 100%.");
                    return;
                }
            }

            DateTime start, end;
            if (!DateTime.TryParse(txtStartDate.Text, out start) ||
                !DateTime.TryParse(txtEndDate.Text, out end))
            {
                ShowErr("Enter valid start and end dates.");
                return;
            }
            if (end < start)
            {
                ShowErr("End date cannot be earlier than start date.");
                return;
            }

            var selectedItemIds = CollectSelectedItemIds();

            try
            {
                var idParam = DBHelper.OutputParameter("@DealID", SqlDbType.Int);
                idParam.Value = dealId;

                DBHelper.ExecuteNonQuery("sp_SaveDeal",
                    idParam,
                    DBHelper.Parameter("@Title",         txtTitle.Text.Trim()),
                    DBHelper.Parameter("@Description",   string.IsNullOrWhiteSpace(txtDescription.Text)
                                                            ? (object)DBNull.Value : txtDescription.Text.Trim()),
                    DBHelper.Parameter("@DealType",      dealType),
                    DBHelper.Parameter("@DiscountValue", discountValue),
                    DBHelper.Parameter("@DealPrice",     (object)dealPrice ?? DBNull.Value),
                    DBHelper.Parameter("@StartDate",     start),
                    DBHelper.Parameter("@EndDate",       end),
                    DBHelper.Parameter("@IsActive",      chkActive.Checked),
                    DBHelper.Parameter("@ItemIDs",       selectedItemIds.Count > 0
                                                            ? (object)string.Join(",", selectedItemIds)
                                                            : DBNull.Value));

                ShowMsg(dealId == 0 ? "Deal created." : "Deal updated.");
                hfDealID.Value = Convert.ToString(idParam.Value);
                litTitle.Text  = "Edit Deal";

                // Re-bind the picker from the persisted set so it reflects what was saved.
                BindItemPicker(selectedItemIds.Select(int.Parse).ToHashSet());
            }
            catch (SqlException ex)
            {
                ShowErr(ex.Message);
            }
        }

        // ── Helpers ──────────────────────────────────────────────────

        private void ShowMsg(string text)
        {
            lblMsg.Text = text;
            lblMsg.Visible = true;
            lblErr.Visible = false;
        }

        private void ShowErr(string text)
        {
            lblErr.Text = text;
            lblErr.Visible = true;
            lblMsg.Visible = false;
        }
    }
}
