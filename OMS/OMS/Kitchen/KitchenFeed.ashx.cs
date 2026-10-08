using System;
using System.Collections.Generic;
using System.Data;
using System.Web;
using System.Web.Script.Serialization;
using System.Web.SessionState;
using OMS.Common.DAL;
using OMS.Common.Helpers;

namespace OMS.Kitchen
{
    /// <summary>
    /// Background feed for the Kitchen screen (no page reloads).
    ///   GET            -> the dishes still being prepared, as JSON
    ///   POST done=ID   -> the chef finished that dish
    /// Same rights as the page itself: whoever may open Kitchen/KitchenOrders.aspx.
    /// </summary>
    public class KitchenFeed : IHttpHandler, IRequiresSessionState
    {
        private const string PageUrl = "~/Kitchen/KitchenOrders.aspx";

        public bool IsReusable { get { return false; } }

        public void ProcessRequest(HttpContext context)
        {
            // Keep a plain 401 (not a redirect to the login page) so the screen can tell the user to sign in.
            context.Response.SuppressFormsAuthenticationRedirect = true;
            context.Response.Cache.SetCacheability(HttpCacheability.NoCache);
            context.Response.ContentType = "application/json";

            if (!SecurityHelper.IsAuthenticated) { Fail(context, 401); return; }
            if (!SecurityHelper.CanAccessUrl(PageUrl)) { Fail(context, 403); return; }

            if (context.Request.HttpMethod == "POST")
            {
                // Our own page only: a custom header cannot be added by a form on another site.
                if (context.Request.Headers["X-Requested-With"] != "XMLHttpRequest") { Fail(context, 400); return; }
                int id;
                if (!int.TryParse(context.Request.Form["done"], out id) || id <= 0) { Fail(context, 400); return; }
                int userId = SecurityHelper.UserID;
                if (userId == 0) { Fail(context, 401); return; }

                DBHelper.ExecuteNonQuery("sp_MarkItemDone",
                    DBHelper.Parameter("@OrderItemID", id),
                    DBHelper.Parameter("@DoneBy", userId));
                context.Response.Write("{\"ok\":true}");
                return;
            }

            var dt = DBHelper.ExecuteDataTable("sp_GetKitchenItems");
            var items = new List<Dictionary<string, object>>(dt.Rows.Count);
            foreach (DataRow r in dt.Rows)
            {
                items.Add(new Dictionary<string, object>
                {
                    { "id",       Convert.ToInt32(r["OrderItemID"]) },
                    { "orderNo",  Convert.ToString(r["OrderNumber"]) },
                    { "table",    Convert.ToString(r["TableNumber"]) },
                    { "type",     Convert.ToString(r["OrderType"]) },
                    { "name",     Convert.ToString(r["ItemName"]) },
                    { "qty",      Convert.ToInt32(r["Quantity"]) },
                    { "size",     Convert.ToString(r["SizeName"]) },
                    { "note",     Convert.ToString(r["SpecialInstructions"]) },
                    { "catId",    Convert.ToInt32(r["CategoryID"]) },
                    { "cat",      Convert.ToString(r["CategoryName"]) },
                    { "ageSec",   Math.Max(0, Convert.ToInt32(r["AgeSeconds"])) }   // measured by the server, not the browser clock
                });
            }
            context.Response.Write(new JavaScriptSerializer().Serialize(new Dictionary<string, object> { { "items", items } }));
        }

        private static void Fail(HttpContext context, int code)
        {
            context.Response.StatusCode = code;
            context.Response.Write("{\"error\":" + code + "}");
        }
    }
}