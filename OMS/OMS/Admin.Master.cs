using System;
using OMS.Common.Helpers;

namespace OMS
{
    public partial class AdminMaster : System.Web.UI.MasterPage
    {
        protected void Page_Load(object sender, EventArgs e)
        {
            SecurityHelper.RequireRoles("Admin", "Manager");
        }
    }
}
