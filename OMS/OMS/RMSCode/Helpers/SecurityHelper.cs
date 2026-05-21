using System;
using System.Web;
using System.Web.Security;

namespace OMS.App_Code.Helpers
{
    public static class SecurityHelper
    {
        public static int UserID
        {
            get { return Convert.ToInt32(HttpContext.Current.Session["UserID"] ?? 0); }
        }

        public static string UserName
        {
            get { return Convert.ToString(HttpContext.Current.Session["UserName"] ?? ""); }
        }

        public static string UserRole
        {
            get { return Convert.ToString(HttpContext.Current.Session["UserRole"] ?? ""); }
        }

        public static bool IsAuthenticated
        {
            get { return HttpContext.Current.User != null && HttpContext.Current.User.Identity.IsAuthenticated; }
        }

        public static bool IsInRole(params string[] roles)
        {
            var role = UserRole;
            foreach (var allowed in roles)
            {
                if (string.Equals(role, allowed, StringComparison.OrdinalIgnoreCase)) return true;
            }
            return false;
        }

        public static void RequireLogin()
        {
            if (!IsAuthenticated || UserID == 0)
            {
                FormsAuthentication.RedirectToLoginPage();
                HttpContext.Current.ApplicationInstance.CompleteRequest();
            }
        }

        public static void RequireRoles(params string[] roles)
        {
            RequireLogin();
            if (!IsInRole(roles))
            {
                HttpContext.Current.Response.Redirect("~/AccessDenied.aspx", false);
                HttpContext.Current.ApplicationInstance.CompleteRequest();
            }
        }
    }
}
