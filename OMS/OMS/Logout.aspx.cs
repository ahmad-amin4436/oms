using System;
using OMS.Common.BLL;

namespace OMS
{
    public partial class Logout : System.Web.UI.Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {
            AuthService.Logout();
        }
    }
}
