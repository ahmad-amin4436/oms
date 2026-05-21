using System;
using OMS.App_Code.DAL;
using OMS.App_Code.Helpers;

namespace OMS.Admin
{
    public partial class Messages : System.Web.UI.Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {
            SecurityHelper.RequireRoles("Admin", "Manager");
            if (!IsPostBack)
            {
                gvMessages.DataSource = DBHelper.ExecuteDataTable("sp_GetMessages", DBHelper.Parameter("@IsRead", DBNull.Value));
                gvMessages.DataBind();
            }
        }
    }
}
