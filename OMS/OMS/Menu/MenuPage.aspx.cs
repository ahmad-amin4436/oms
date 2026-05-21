using System;
using OMS.App_Code.DAL;

namespace OMS.Menu
{
    public partial class MenuPage : System.Web.UI.Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {
            if (!IsPostBack)
            {
                rptPublicMenu.DataSource = DBHelper.ExecuteDataTable("sp_GetMenuItems", DBHelper.Parameter("@CategoryID", DBNull.Value), DBHelper.Parameter("@IsAvailable", true));
                rptPublicMenu.DataBind();
            }
        }
    }
}
