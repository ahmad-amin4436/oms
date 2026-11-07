using System;
using System.Data;
using System.Web;
using System.Web.Security;
using OMS.Common.DAL;
using System.Data.SqlClient;

namespace OMS.Common.Helpers
{
    public static class SecurityHelper
    {
        public static int UserID
        {
            get { return Convert.ToInt32(HttpContext.Current.Session["UserID"] ?? 0); }
        }

        public static bool CanPerform(string actionKey)
        {
            RequireLogin();
            if (string.IsNullOrEmpty(actionKey) || string.IsNullOrEmpty(UserRole)) return false;

            // Same answer all request long (rights only change via the Roles page), so look it up once.
            var items = HttpContext.Current.Items;
            string cacheKey = "CanPerform:" + UserRole + "|" + actionKey;
            if (items[cacheKey] is bool) return (bool)items[cacheKey];

            var canParam = DBHelper.OutputParameter("@CanPerform", SqlDbType.Bit);
            DBHelper.ExecuteNonQuery("sp_CanRolePerform",
                DBHelper.Parameter("@RoleName", UserRole),
                DBHelper.Parameter("@ActionKey", actionKey),
                canParam);

            bool allowed = canParam.Value != DBNull.Value && Convert.ToBoolean(canParam.Value);
            items[cacheKey] = allowed;
            return allowed;
        }

        /// <summary>
        /// Table export is done in the browser from rows the page already shows, so the Export operation
        /// of the screen's module decides whether the Export button is offered. A screen whose module has
        /// no Export operation in Roles & Rights is not restricted.
        /// </summary>
        public static bool CanExportCurrentPage()
        {
            var ctx = HttpContext.Current;
            if (ctx == null || !IsAuthenticated) return true;
            string path = ctx.Request.AppRelativeCurrentExecutionFilePath ?? "";
            string module;
            switch (path.ToLowerInvariant())
            {
                case "~/orders/orderlist.aspx":      module = "OrderList"; break;
                case "~/menu/menuitems.aspx":        module = "MenuItems"; break;
                case "~/default.aspx":               module = "Dashboard"; break;
                case "~/analytics/analytics.aspx":   module = "Analytics"; break;
                default: return true;
            }
            return CanPerform(module + ".Export");
        }

        public static void RequirePermission(string actionKey)
        {
            if (!CanPerform(actionKey))
            {
                HttpContext.Current.Response.Redirect("~/AccessDenied.aspx", true);
            }
        }

        public static void LogActivity(string module, string action, string description = null,
            int? orderId = null, string entityType = null, int? entityId = null,
            string fieldName = null, string previousValue = null, string newValue = null)
        {
            DBHelper.ExecuteNonQuery("sp_LogActivity",
                DBHelper.Parameter("@UserID", UserID == 0 ? (object)DBNull.Value : UserID),
                DBHelper.Parameter("@Action", action),
                DBHelper.Parameter("@Description", description),
                DBHelper.Parameter("@IPAddress", GetIPAddress()),
                DBHelper.Parameter("@Module", module),
                DBHelper.Parameter("@OrderID", orderId.HasValue ? (object)orderId.Value : DBNull.Value),
                DBHelper.Parameter("@EntityType", entityType),
                DBHelper.Parameter("@EntityID", entityId.HasValue ? (object)entityId.Value : DBNull.Value),
                DBHelper.Parameter("@FieldName", fieldName),
                DBHelper.Parameter("@PreviousValue", previousValue),
                DBHelper.Parameter("@NewValue", newValue));
        }

        private static string GetIPAddress()
        {
            var request = HttpContext.Current == null ? null : HttpContext.Current.Request;
            return request == null ? null : request.UserHostAddress;
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
                HttpContext.Current.Response.End();   // stop the page: no handler may run unauthenticated
            }
        }

        public static void RequireRoles(params string[] roles)
        {
            RequireLogin();
            if (!IsInRole(roles))
            {
                HttpContext.Current.Response.Redirect("~/AccessDenied.aspx", true);   // ends the request
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

            // The decision only changes when rights are edited, which clears the "auth" cache scope.
            return AppCache.GetOrAdd<object>("auth", "can|" + role + "|" + url, 60, () =>
            {
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
                return (object)(granted || !UrlExistsInNav(url));
            }) is bool ok && ok;
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
                HttpContext.Current.Response.Redirect("~/AccessDenied.aspx", true);   // ends the request
        }

        /// <summary>
        /// For showing/hiding links and buttons: same rule as <see cref="RequireUrlAccess"/>,
        /// cached for the request. Hiding is only a convenience; the target page enforces it.
        /// </summary>
        public static bool CanOpen(string url)
        {
            if (!IsAuthenticated) return false;
            var cache = HttpContext.Current.Items;
            string key = "CanOpen:" + url;
            if (cache[key] == null) cache[key] = CanAccessUrl(url);
            return (bool)cache[key];
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
