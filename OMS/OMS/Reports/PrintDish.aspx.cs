using System;
using System.Data;
using System.Text;
using System.Web;
using OMS.Common.DAL;
using OMS.Common.Helpers;

namespace OMS.Reports
{
    /// <summary>Kitchen ticket for a single order line (?id=OrderID&amp;item=OrderItemID).</summary>
    public partial class PrintDish : System.Web.UI.Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {
            // A dish ticket is printed from Order Detail, so it needs that page's right.
            SecurityHelper.RequireUrlAccess("~/Orders/OrderDetail.aspx");

            int orderId, orderItemId;
            if (!int.TryParse(Request.QueryString["id"], out orderId) ||
                !int.TryParse(Request.QueryString["item"], out orderItemId))
            {
                Fail("Invalid request.");
                return;
            }

            var ds = DBHelper.ExecuteDataSet("sp_GetOrderByID", DBHelper.Parameter("@OrderID", orderId));
            if (ds.Tables.Count < 2 || ds.Tables[0].Rows.Count == 0) { Fail("Order not found."); return; }

            DataRow order = ds.Tables[0].Rows[0];
            if (Convert.ToString(order["Status"]) == "Cancelled") { Fail("This order is cancelled."); return; }

            // The item must belong to this order (never trust the query string).
            DataRow[] lines = ds.Tables[1].Select("OrderItemID = " + orderItemId);
            if (lines.Length == 0) { Fail("Item not found on this order."); return; }
            DataRow line = lines[0];

            var sb = new StringBuilder();
            sb.Append("<div class=\"ticket\">");
            sb.Append("<div class=\"center big\">").Append(H(order["OrderNumber"])).Append("</div>");
            sb.Append("<div class=\"center\">")
              .Append(Convert.ToDateTime(order["CreatedAt"]).ToString("dd MMM yyyy, hh:mm tt")).Append("</div>");
            sb.Append("<hr class=\"rule\" />");

            string type = Convert.ToString(order["OrderType"]);
            sb.Append("<div class=\"row\"><span class=\"bold\">Order ID</span><span>#").Append(orderId).Append("</span></div>");
            sb.Append("<div class=\"row\"><span class=\"bold\">Type</span><span>").Append(H(type)).Append("</span></div>");
            string table = Convert.ToString(order["TableNumber"]);
            if (table.Length > 0)
                sb.Append("<div class=\"row\"><span class=\"bold\">Table</span><span>").Append(H(table)).Append("</span></div>");
            string cust = Convert.ToString(order["CustomerName"]);
            if (cust.Length > 0)
                sb.Append("<div class=\"row\"><span class=\"bold\">Customer</span><span>").Append(H(cust)).Append("</span></div>");

            sb.Append("<hr class=\"rule\" />");
            sb.Append("<div class=\"row\"><span class=\"big\">").Append(H(line["ItemName"])).Append("</span>")
              .Append("<span class=\"qty\">x").Append(Convert.ToInt32(line["Quantity"])).Append("</span></div>");

            string size = Convert.ToString(line["SizeName"]);
            if (size.Length > 0)
                sb.Append("<div>Size: ").Append(H(size)).Append("</div>");

            if (ds.Tables.Count > 2)
                foreach (DataRow t in ds.Tables[2].Select("OrderItemID = " + orderItemId))
                    sb.Append("<div class=\"mod\">+ ").Append(H(t["Name"])).Append("</div>");

            string note = Convert.ToString(line["SpecialInstructions"]);
            if (note.Length > 0)
                sb.Append("<div class=\"bold\" style=\"margin-top:1mm\">Note: ").Append(H(note)).Append("</div>");

            sb.Append("<hr class=\"rule\" />");
            sb.Append("<div class=\"center\">Printed ").Append(DateTime.UtcNow.AddHours(5).ToString("dd MMM yyyy, hh:mm tt")).Append("</div>");
            sb.Append("</div>");
            litTicket.Text = sb.ToString();

            // Open the browser print dialog (printer is chosen there), then close the popup.
            litScript.Text = "<script>window.addEventListener('load',function(){window.print();});" +
                             "window.addEventListener('afterprint',function(){if(window.opener){window.close();}});</script>";
        }

        private static string H(object o) { return HttpUtility.HtmlEncode(Convert.ToString(o)); }

        private void Fail(string msg)
        {
            litTicket.Text = "<div class=\"error\">" + HttpUtility.HtmlEncode(msg) + "</div>";
        }
    }
}
