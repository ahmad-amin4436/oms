using System;

namespace OMS
{
    public partial class Dashboard : System.Web.UI.Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {
            Response.Redirect(ResolveUrl("~/Default.aspx"), false);
            Context.ApplicationInstance.CompleteRequest();
        }
    }
}
