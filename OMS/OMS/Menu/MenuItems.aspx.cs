using System;
using OMS.App_Code.DAL;
using OMS.App_Code.Helpers;

namespace OMS.Menu
{
    public partial class MenuItems : System.Web.UI.Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {
            SecurityHelper.RequireRoles("Admin", "Manager");
            if (!IsPostBack)
            {
                gvMenuItems.DataSource = DBHelper.ExecuteDataTable("sp_GetMenuItems", DBHelper.Parameter("@CategoryID", DBNull.Value), DBHelper.Parameter("@IsAvailable", DBNull.Value));
                gvMenuItems.DataBind();
            }
        }
    }
}
