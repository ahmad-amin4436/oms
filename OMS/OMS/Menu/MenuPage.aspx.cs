using System;
using System.Data;
using OMS.Common.DAL;

namespace OMS.Menu
{
    public partial class MenuPage : System.Web.UI.Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {
            if (!IsPostBack)
            {
                var dt = DBHelper.ExecuteDataTable("sp_GetMenuItems",
                    DBHelper.Parameter("@CategoryID", DBNull.Value),
                    DBHelper.Parameter("@IsAvailable", true));

                pnlNoItems.Visible      = (dt.Rows.Count == 0);
                rptPublicMenu.DataSource = dt.Rows.Count > 0 ? (object)dt : null;
                rptPublicMenu.DataBind();
            }
        }
    }
}
