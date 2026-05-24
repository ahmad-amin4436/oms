using System;
using System.Web;
using System.Web.UI;

namespace OMS.Common.Helpers
{
    public static class UiHelper
    {
        public static string StatusBadgeClass(string status)
        {
            switch ((status ?? "").ToLowerInvariant())
            {
                case "pending": return "badge-subtle-warning";
                case "confirmed": return "badge-subtle-info";
                case "preparing": return "badge-subtle-primary";
                case "ready": return "badge-subtle-success";
                case "delivered": return "badge-subtle-secondary";
                case "cancelled": return "badge-subtle-danger";
                default: return "badge-subtle-secondary";
            }
        }

        public static string StatusBadgeIcon(string status)
        {
            switch ((status ?? "").ToLowerInvariant())
            {
                case "pending": return "fas fa-stream";
                case "confirmed": return "fas fa-check";
                case "preparing": return "fas fa-redo";
                case "ready": return "fas fa-box";
                case "delivered": return "fas fa-check";
                case "cancelled": return "fas fa-ban";
                default: return "fas fa-stream";
            }
        }

        public static string HtmlEncode(object value)
        {
            return HttpUtility.HtmlEncode(Convert.ToString(value));
        }

        public static void Toast(Page page, string message, string type)
        {
            var script = string.Format("window.rmsToast && window.rmsToast({0}, {1});",
                new System.Web.Script.Serialization.JavaScriptSerializer().Serialize(message),
                new System.Web.Script.Serialization.JavaScriptSerializer().Serialize(type));
            ScriptManager.RegisterStartupScript(page, page.GetType(), Guid.NewGuid().ToString("N"), script, true);
        }
    }
}
