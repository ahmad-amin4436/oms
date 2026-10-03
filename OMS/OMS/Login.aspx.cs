using System;
using System.Linq;
using OMS.Common.BLL;
using OMS.Common.Helpers;
using OMS.DAL.Repositories;

namespace OMS
{
    public partial class Login : System.Web.UI.Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {
            if (!IsPostBack && User.Identity.IsAuthenticated)
            {
                Response.Redirect(HomeUrl(), false);
                Context.ApplicationInstance.CompleteRequest();
            }
        }

        // Admin lands on the dashboard; every other role lands on the first page its
        // rights (nav menu) allow, so nobody is bounced to a page they cannot open.
        private static string HomeUrl()
        {
            if (SecurityHelper.IsInRole("Admin")) return "~/Default.aspx";

            var sections = new NavMenuService(new NavMenuRepository()).GetNavSections(SecurityHelper.UserRole);
            foreach (var g in sections.SelectMany(s => s.Groups).OrderBy(g => g.SortOrder))
            {
                if (g.IsDirectLink && g.Url != "~/Default.aspx") return g.Url;
                var item = g.Items.OrderBy(i => i.SortOrder).FirstOrDefault(i => !string.IsNullOrEmpty(i.Url));
                if (item != null) return item.Url;
            }
            return "~/Orders/OrderList.aspx";
        }

        protected void btnLogin_Click(object sender, EventArgs e)
        {
            if (!Page.IsValid) return;

            string error;
            if (AuthService.TryLogin(txtEmail.Text.Trim(), txtPassword.Text, chkRememberMe.Checked, out error))
            {
                Response.Redirect(HomeUrl(), false);
                Context.ApplicationInstance.CompleteRequest();
                return;
            }

            pnlAlert.Visible = true;
            litAlert.Text = Server.HtmlEncode(error);
        }
    }
}
