using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Optimization;
using System.Web.Routing;
using System.Web.Security;
using System.Web.SessionState;
using System.Security.Principal;
using OMS.App_Code.DAL;

namespace OMS
{
    public class Global : HttpApplication
    {
        void Application_Start(object sender, EventArgs e)
        {
            // Code that runs on application startup
            RouteConfig.RegisterRoutes(RouteTable.Routes);
            BundleConfig.RegisterBundles(BundleTable.Bundles);
        }

        void Application_PostAuthenticateRequest(object sender, EventArgs e)
        {
            var authCookie = Request.Cookies[FormsAuthentication.FormsCookieName];
            if (authCookie == null || string.IsNullOrEmpty(authCookie.Value)) return;

            try
            {
                var ticket = FormsAuthentication.Decrypt(authCookie.Value);
                if (ticket == null || ticket.Expired) return;

                var parts = (ticket.UserData ?? "").Split('|');
                var role = parts.Length > 1 ? parts[1] : "";
                Context.User = new GenericPrincipal(new FormsIdentity(ticket), new[] { role });
            }
            catch
            {
                FormsAuthentication.SignOut();
            }
        }

        void Application_AcquireRequestState(object sender, EventArgs e)
        {
            if (Context == null || Context.Session == null || Context.User == null || !Context.User.Identity.IsAuthenticated) return;

            var authCookie = Request.Cookies[FormsAuthentication.FormsCookieName];
            if (authCookie == null) return;

            var ticket = FormsAuthentication.Decrypt(authCookie.Value);
            if (ticket == null) return;

            var parts = (ticket.UserData ?? "").Split('|');
            if (parts.Length > 0) Session["UserID"] = parts[0];
            if (parts.Length > 1) Session["UserRole"] = parts[1];
            Session["UserName"] = ticket.Name;
        }

        void Application_PreRequestHandlerExecute(object sender, EventArgs e)
        {
            var page = Context.CurrentHandler as System.Web.UI.Page;
            if (page == null || Session == null) return;

            page.PreInit += delegate
            {
                page.ViewStateUserKey = Session.SessionID;
            };
        }

        void Application_Error(object sender, EventArgs e)
        {
            var ex = Server.GetLastError();
            if (ex == null) return;

            try
            {
                DBHelper.ExecuteNonQuery("sp_LogError",
                    DBHelper.Parameter("@Message", ex.Message),
                    DBHelper.Parameter("@StackTrace", ex.ToString()),
                    DBHelper.Parameter("@Url", Request.RawUrl),
                    DBHelper.Parameter("@IPAddress", Request.UserHostAddress));
            }
            catch
            {
                // Last-resort safety: avoid recursive failures if database logging is unavailable.
            }
        }
    }
}
