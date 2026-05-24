using System;
using System.Data;
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

        protected void Page_Load(object sender, EventArgs e)
        {
            SecurityHelper.RequireRoles("Admin", "Manager");
            if (!IsPostBack)
                BindAll();
        }

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

        protected string GetCatBtnCss(int catId)
        {
            bool active = SelectedCategory.HasValue && SelectedCategory.Value == catId;
            return "btn btn-sm " + (active ? "btn-primary" : "btn-falcon-default");
        }

        protected void lbAllCat_Click(object sender, EventArgs e)
        {
            SelectedCategory = null;
            BindAll();
        }

        protected void rptCatTabs_ItemCommand(object source, System.Web.UI.WebControls.RepeaterCommandEventArgs e)
        {
            if (e.CommandName == "Filter")
            {
                SelectedCategory = Convert.ToInt32(e.CommandArgument);
                BindAll();
            }
        }

        protected void gvMenuItems_RowCommand(object sender, System.Web.UI.WebControls.GridViewCommandEventArgs e)
        {
            if (e.CommandName != "Toggle") return;

            int itemId = Convert.ToInt32(e.CommandArgument);
            var result = DBHelper.ExecuteDataTable("sp_ToggleMenuItemAvailability",
                DBHelper.Parameter("@ItemID", itemId));

            bool nowAvailable = result.Rows.Count > 0 && Convert.ToBoolean(result.Rows[0][0]);
            lblMsg.Text    = nowAvailable ? "Item marked as available." : "Item marked as unavailable.";
            lblMsg.Visible = true;

            BindItems();
        }
    }
}
