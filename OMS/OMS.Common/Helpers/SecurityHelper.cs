using System;
using System.Data;
using System.Web;
using System.Web.Security;
using OMS.Common.DAL;

namespace OMS.Common.Helpers
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

        /// <summary>
        /// True when the current role may open the given page URL, decided by the
        /// same nav-rights data (NavGroupRoles / NavItemRoles) that builds the menu.
        /// Admin always passes. A URL not present in the nav at all returns true
        /// (it was never nav-gated, so only login is required).
        /// </summary>
        public static bool CanAccessUrl(string url)
        {
            if (string.IsNullOrEmpty(url)) return true;

            // Admin is the system owner — never lock the admin out of any page.
            if (IsInRole("Admin")) return true;

            var role = UserRole;
            if (string.IsNullOrEmpty(role)) return false;

            var canParam = DBHelper.OutputParameter("@CanAccess", SqlDbType.Bit);
            DBHelper.ExecuteNonQuery("sp_CanRoleAccessUrl",
                DBHelper.Parameter("@RoleName", role),
                DBHelper.Parameter("@Url", url),
                canParam);

            // A page that exists in the nav and is denied -> false.
            // A page not found in the nav at all -> @CanAccess stays 0, but we
            // treat "unknown" as allowed (login already enforced) so non-nav
            // utility pages are not accidentally locked. Distinguish via a probe.
            bool granted = canParam.Value != DBNull.Value && Convert.ToBoolean(canParam.Value);
            if (granted) return true;

            return !UrlExistsInNav(url);
        }

        /// <summary>
        /// Enforces <see cref="CanAccessUrl"/> for the current request's page.
        /// Redirects to AccessDenied when the role lacks the right.
        /// Call with no argument to use the current page automatically.
        /// </summary>
        public static void RequireUrlAccess(string url = null)
        {
            RequireLogin();

            if (string.IsNullOrEmpty(url))
                url = HttpContext.Current.Request.AppRelativeCurrentExecutionFilePath; // e.g. ~/Reports/PrintInvoice.aspx

            if (!CanAccessUrl(url))
            {
                HttpContext.Current.Response.Redirect("~/AccessDenied.aspx", false);
                HttpContext.Current.ApplicationInstance.CompleteRequest();
            }
        }

        // Is this URL registered anywhere in the nav (group link or item)?
        private static bool UrlExistsInNav(string url)
        {
            var dt = DBHelper.ExecuteDataTable("sp_UrlExistsInNav",
                DBHelper.Parameter("@Url", url));
            return dt.Rows.Count > 0 && Convert.ToInt32(dt.Rows[0][0]) > 0;
        }
    }
}
