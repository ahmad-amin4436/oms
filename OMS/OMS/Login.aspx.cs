using System;
using OMS.App_Code.BLL;

namespace OMS
{
    public partial class Login : System.Web.UI.Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {
            if (!IsPostBack && User.Identity.IsAuthenticated)
            {
                Response.Redirect("~/Dashboard.aspx", false);
                Context.ApplicationInstance.CompleteRequest();
            }
        }

        protected void btnLogin_Click(object sender, EventArgs e)
        {
            if (!Page.IsValid) return;

            string error;
            if (AuthService.TryLogin(txtEmail.Text.Trim(), txtPassword.Text, chkRememberMe.Checked, out error))
            {
                Response.Redirect("~/Dashboard.aspx", false);
                Context.ApplicationInstance.CompleteRequest();
                return;
            }

            pnlAlert.Visible = true;
            litAlert.Text = Server.HtmlEncode(error);
        }
    }
}
