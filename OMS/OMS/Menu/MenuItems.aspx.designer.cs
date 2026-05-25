namespace OMS.Menu
{
    public partial class MenuItems
    {
        protected global::System.Web.UI.WebControls.Label        lblMsg;
        protected global::System.Web.UI.WebControls.Label        lblErr;

        protected global::System.Web.UI.WebControls.Button       btnToggleCats;
        protected global::System.Web.UI.WebControls.Panel        pnlCategories;
        protected global::System.Web.UI.WebControls.Panel        pnlCatEditor;
        protected global::System.Web.UI.WebControls.HiddenField  hfCatID;
        protected global::System.Web.UI.WebControls.TextBox      txtCatName;
        protected global::System.Web.UI.WebControls.TextBox      txtCatOrder;
        protected global::System.Web.UI.WebControls.CheckBox     chkCatActive;
        protected global::System.Web.UI.WebControls.Button       btnSaveCat;
        protected global::System.Web.UI.WebControls.Button       btnCancelCat;
        protected global::System.Web.UI.WebControls.Button       btnAddCat;
        protected global::System.Web.UI.WebControls.GridView     gvCategories;

        protected global::System.Web.UI.WebControls.Panel        pnlEditor;
        protected global::System.Web.UI.WebControls.Literal      litEditorTitle;
        protected global::System.Web.UI.WebControls.LinkButton   lbCloseEditor;
        protected global::System.Web.UI.WebControls.HiddenField  hfItemID;
        protected global::System.Web.UI.WebControls.TextBox      txtName;
        protected global::System.Web.UI.WebControls.DropDownList ddlCategory;
        protected global::System.Web.UI.WebControls.TextBox      txtPrice;
        protected global::System.Web.UI.WebControls.TextBox      txtDescription;
        protected global::System.Web.UI.WebControls.CheckBox     chkAvailable;
        protected global::System.Web.UI.WebControls.CheckBox     chkFeatured;
        protected global::System.Web.UI.WebControls.Button       btnSave;
        protected global::System.Web.UI.WebControls.Button       btnCancel;

        protected global::System.Web.UI.WebControls.LinkButton   lbAllCat;
        protected global::System.Web.UI.WebControls.Repeater     rptCatTabs;
        protected global::System.Web.UI.WebControls.Button       btnAddNew;
        protected global::System.Web.UI.WebControls.GridView     gvMenuItems;
    }
}
