using System.Web;
using System.Web.SessionState;
using OMS.Common.DAL;
using OMS.Common.Helpers;

namespace OMS
{
    /// <summary>"Mark all as read" for the notification bell, called in the background (no page reload).</summary>
    public class MarkNotificationsRead : IHttpHandler, IRequiresSessionState
    {
        public bool IsReusable { get { return false; } }

        public void ProcessRequest(HttpContext context)
        {
            // POST from our own pages only: the custom header cannot be added by another site's form.
            bool ajax = context.Request.Headers["X-Requested-With"] == "XMLHttpRequest";
            if (context.Request.HttpMethod != "POST" || !ajax) { Fail(context, 400); return; }
            if (!SecurityHelper.IsAuthenticated) { Fail(context, 401); return; }
            if (!SecurityHelper.IsInRole("Admin", "Manager")) { Fail(context, 403); return; }

            DBHelper.ExecuteNonQuery("sp_MarkAllMessagesRead");
            context.Response.ContentType = "text/plain";
            context.Response.Write("ok");
        }

        private static void Fail(HttpContext context, int code)
        {
            context.Response.StatusCode = code;
            context.Response.Write("error");
        }
    }
}