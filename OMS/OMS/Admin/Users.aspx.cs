using System;
using OMS.App_Code.Helpers;

namespace OMS.Admin
{
    public partial class Users : System.Web.UI.Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {
            SecurityHelper.RequireRoles("Admin");
        }
    }
}
