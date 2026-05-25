using System;
using System.Data;
using System.Web.UI.WebControls;
using OMS.Common.DAL;
using OMS.Common.Helpers;

namespace OMS.Menu
{
    public partial class MenuItems : System.Web.UI.Page
    {
        private int? SelectedCategory
        {
            get { return ViewState["SelCat"] as int?; }
            set { ViewState["SelCat"] = value; }
        }

        // Keeps the "Manage Categories" section open across postbacks once expanded.
        private bool CategoriesOpen
        {
            get { return ViewState["CatsOpen"] as bool? ?? false; }
            set { ViewState["CatsOpen"] = value; }
        }

        protected void Page_Load(object sender, EventArgs e)
        {
            SecurityHelper.RequireRoles("Admin", "Manager");
            if (!IsPostBack)
                BindAll();
        }

        // ── Binding ──────────────────────────────────────────────────

        private void BindAll()
        {
            BindCategoryTabs();
            BindItems();
        }

        private void BindCategoryTabs()
        {
            lbAllCat.CssClass = "btn btn-sm " + (SelectedCategory == null ? "btn-primary" : "btn-falcon-default");
            var dt = DBHelper.ExecuteDataTable("sp_GetMenuCategories");
            rptCatTabs.DataSource = dt.Rows.Count > 0 ? (object)dt : null;
            rptCatTabs.DataBind();
        }

        private void BindItems()
        {
            var catParam = SelectedCategory.HasValue
                ? DBHelper.Parameter("@CategoryID", SelectedCategory.Value)
                : DBHelper.Parameter("@CategoryID", DBNull.Value);

            gvMenuItems.DataSource = DBHelper.ExecuteDataTable(
                "sp_GetMenuItems",
                catParam,
                DBHelper.Parameter("@IsAvailable", DBNull.Value));
            gvMenuItems.DataBind();
        }

        private void BindCategoryDropdown()
        {
            var dt = DBHelper.ExecuteDataTable("sp_GetMenuCategories");
            ddlCategory.DataSource     = dt;
            ddlCategory.DataTextField  = "CategoryName";
            ddlCategory.DataValueField = "CategoryID";
            ddlCategory.DataBind();
            ddlCategory.Items.Insert(0, new ListItem("- Select category -", ""));
        }

        protected string GetCatBtnCss(int catId)
        {
            bool active = SelectedCategory.HasValue && SelectedCategory.Value == catId;
            return "btn btn-sm " + (active ? "btn-primary" : "btn-falcon-default");
        }

        // ── Category filter ──────────────────────────────────────────

        protected void lbAllCat_Click(object sender, EventArgs e)
        {
            SelectedCategory = null;
            HideEditor();
            BindAll();
        }

        protected void rptCatTabs_ItemCommand(object source, RepeaterCommandEventArgs e)
        {
            if (e.CommandName == "Filter")
            {
                SelectedCategory = Convert.ToInt32(e.CommandArgument);
                HideEditor();
                BindAll();
            }
        }

        // ── Grid row actions ─────────────────────────────────────────

        protected void gvMenuItems_RowCommand(object sender, GridViewCommandEventArgs e)
        {
            switch (e.CommandName)
            {
                case "Toggle":
                    ToggleAvailability(Convert.ToInt32(e.CommandArgument));
                    break;
                case "EditItem":
                    OpenEditorForEdit(Convert.ToInt32(e.CommandArgument));
                    break;
                case "DeleteItem":
                    DeleteItem(Convert.ToInt32(e.CommandArgument));
                    break;
            }
        }

        private void ToggleAvailability(int itemId)
        {
            var result = DBHelper.ExecuteDataTable("sp_ToggleMenuItemAvailability",
                DBHelper.Parameter("@ItemID", itemId));

            bool nowAvailable = result.Rows.Count > 0 && Convert.ToBoolean(result.Rows[0][0]);
            ShowMsg(nowAvailable ? "Item marked as available." : "Item marked as unavailable.");
            BindItems();
        }

        private void DeleteItem(int itemId)
        {
            // sp_DeleteMenuItem is a soft delete (sets IsAvailable = 0) so existing
            // order history that references the item stays intact.
            DBHelper.ExecuteNonQuery("sp_DeleteMenuItem", DBHelper.Parameter("@ItemID", itemId));
            ShowMsg("Item removed from the menu.");
            HideEditor();
            BindItems();
        }

        // ── Add / Edit editor ────────────────────────────────────────

        protected void btnAddNew_Click(object sender, EventArgs e)
        {
            BindCategoryDropdown();
            hfItemID.Value      = "0";
            litEditorTitle.Text = "Add New Item";

            txtName.Text        = "";
            txtDescription.Text = "";
            txtPrice.Text       = "";
            ddlCategory.SelectedIndex = 0;
            chkAvailable.Checked = true;
            chkFeatured.Checked  = false;

            pnlEditor.Visible = true;
        }

        private void OpenEditorForEdit(int itemId)
        {
            var dt = DBHelper.ExecuteDataTable("sp_GetMenuItemByID",
                DBHelper.Parameter("@ItemID", itemId));
            if (dt.Rows.Count == 0)
            {
                ShowErr("That item no longer exists.");
                BindItems();
                return;
            }

            BindCategoryDropdown();
            var row = dt.Rows[0];

            hfItemID.Value      = itemId.ToString();
            litEditorTitle.Text = "Edit Item";
            txtName.Text        = Convert.ToString(row["Name"]);
            txtDescription.Text = row["Description"] == DBNull.Value ? "" : Convert.ToString(row["Description"]);
            txtPrice.Text       = Convert.ToDecimal(row["BasePrice"]).ToString("0.##");
            chkAvailable.Checked = Convert.ToBoolean(row["IsAvailable"]);
            chkFeatured.Checked  = Convert.ToBoolean(row["IsFeatured"]);

            var catItem = ddlCategory.Items.FindByValue(Convert.ToString(row["CategoryID"]));
            if (catItem != null) { ddlCategory.ClearSelection(); catItem.Selected = true; }

            pnlEditor.Visible = true;
        }

        protected void btnSave_Click(object sender, EventArgs e)
        {
            if (!Page.IsValid) return;

            int itemId = 0;
            int.TryParse(hfItemID.Value, out itemId);

            int categoryId;
            if (!int.TryParse(ddlCategory.SelectedValue, out categoryId))
            {
                ShowErr("Please select a valid category.");
                pnlEditor.Visible = true;
                return;
            }

            decimal price;
            if (!decimal.TryParse(txtPrice.Text.Trim(), out price) || price < 0)
            {
                ShowErr("Please enter a valid base price.");
                pnlEditor.Visible = true;
                return;
            }

            try
            {
                var idParam = DBHelper.OutputParameter("@ItemID", SqlDbType.Int);
                idParam.Value = itemId;

                DBHelper.ExecuteNonQuery("sp_SaveMenuItem",
                    idParam,
                    DBHelper.Parameter("@CategoryID",  categoryId),
                    DBHelper.Parameter("@Name",        txtName.Text.Trim()),
                    DBHelper.Parameter("@Description", string.IsNullOrWhiteSpace(txtDescription.Text)
                                                         ? (object)DBNull.Value : txtDescription.Text.Trim()),
                    DBHelper.Parameter("@BasePrice",   price),
                    DBHelper.Parameter("@ImagePath",   DBNull.Value),
                    DBHelper.Parameter("@IsAvailable", chkAvailable.Checked),
                    DBHelper.Parameter("@IsFeatured",  chkFeatured.Checked));

                ShowMsg(itemId == 0 ? "New item added to the menu." : "Item updated.");
                HideEditor();
                BindAll();
            }
            catch (Exception ex)
            {
                ShowErr("Failed to save item: " + ex.Message);
                pnlEditor.Visible = true;
            }
        }

        protected void lbCancel_Click(object sender, EventArgs e)
        {
            HideEditor();
        }

        // ── Helpers ──────────────────────────────────────────────────

        private void HideEditor()
        {
            pnlEditor.Visible = false;
        }

        private void ShowMsg(string text)
        {
            lblMsg.Text    = text;
            lblMsg.Visible = true;
            lblErr.Visible = false;
        }

        private void ShowErr(string text)
        {
            lblErr.Text    = text;
            lblErr.Visible = true;
            lblMsg.Visible = false;
        }

        // ══════════════════════════════════════════════════════════════
        //  CATEGORY MANAGEMENT
        // ══════════════════════════════════════════════════════════════

        private void BindCategoriesGrid()
        {
            gvCategories.DataSource = DBHelper.ExecuteDataTable("sp_GetAllCategories");
            gvCategories.DataBind();
        }

        protected void btnToggleCats_Click(object sender, EventArgs e)
        {
            CategoriesOpen   = !CategoriesOpen;
            pnlCategories.Visible = CategoriesOpen;
            btnToggleCats.Text    = CategoriesOpen ? "Hide Categories" : "Manage Categories";

            if (CategoriesOpen)
                BindCategoriesGrid();
            else
                HideCatEditor();
        }

        protected void btnAddCat_Click(object sender, EventArgs e)
        {
            KeepCategoriesOpen();
            hfCatID.Value      = "0";
            txtCatName.Text    = "";
            txtCatOrder.Text   = "0";
            chkCatActive.Checked = true;
            pnlCatEditor.Visible = true;
            BindCategoriesGrid();
        }

        protected void gvCategories_RowCommand(object sender, GridViewCommandEventArgs e)
        {
            KeepCategoriesOpen();

            if (e.CommandName == "EditCat")
            {
                OpenCatEditor(Convert.ToInt32(e.CommandArgument));
            }
            else if (e.CommandName == "DeleteCat")
            {
                DBHelper.ExecuteNonQuery("sp_DeleteCategory",
                    DBHelper.Parameter("@CategoryID", Convert.ToInt32(e.CommandArgument)));
                ShowMsg("Category deactivated.");
                HideCatEditor();
                BindCategoriesGrid();
                // Filter tabs only show active categories, so refresh them too.
                BindCategoryTabs();
                BindItems();
            }
        }

        private void OpenCatEditor(int categoryId)
        {
            // sp_GetAllCategories returns every category; find the one being edited.
            var dt = DBHelper.ExecuteDataTable("sp_GetAllCategories");
            DataRow row = null;
            foreach (DataRow r in dt.Rows)
                if (Convert.ToInt32(r["CategoryID"]) == categoryId) { row = r; break; }

            if (row == null)
            {
                ShowErr("That category no longer exists.");
                BindCategoriesGrid();
                return;
            }

            hfCatID.Value        = categoryId.ToString();
            txtCatName.Text      = Convert.ToString(row["CategoryName"]);
            txtCatOrder.Text     = Convert.ToString(row["DisplayOrder"]);
            chkCatActive.Checked = Convert.ToBoolean(row["IsActive"]);
            pnlCatEditor.Visible = true;
            BindCategoriesGrid();
        }

        protected void btnSaveCat_Click(object sender, EventArgs e)
        {
            KeepCategoriesOpen();
            if (!Page.IsValid) { pnlCatEditor.Visible = true; BindCategoriesGrid(); return; }

            int catId = 0;
            int.TryParse(hfCatID.Value, out catId);

            int order = 0;
            int.TryParse(txtCatOrder.Text.Trim(), out order);

            try
            {
                var idParam = DBHelper.OutputParameter("@CategoryID", SqlDbType.Int);
                idParam.Value = catId;

                DBHelper.ExecuteNonQuery("sp_SaveCategory",
                    idParam,
                    DBHelper.Parameter("@Name",         txtCatName.Text.Trim()),
                    DBHelper.Parameter("@DisplayOrder", order),
                    DBHelper.Parameter("@IsActive",     chkCatActive.Checked));

                ShowMsg(catId == 0 ? "New category added." : "Category updated.");
                HideCatEditor();
                BindCategoriesGrid();
                // Reflect the change in the filter tabs and item dropdown source.
                BindCategoryTabs();
                BindItems();
            }
            catch (Exception ex)
            {
                ShowErr("Failed to save category: " + ex.Message);
                pnlCatEditor.Visible = true;
                BindCategoriesGrid();
            }
        }

        protected void btnCancelCat_Click(object sender, EventArgs e)
        {
            KeepCategoriesOpen();
            HideCatEditor();
            BindCategoriesGrid();
        }

        private void HideCatEditor()
        {
            pnlCatEditor.Visible = false;
        }

        // Re-assert the open state on every category postback so the section and grid persist.
        private void KeepCategoriesOpen()
        {
            CategoriesOpen        = true;
            pnlCategories.Visible = true;
            btnToggleCats.Text    = "Hide Categories";
        }
    }
}
