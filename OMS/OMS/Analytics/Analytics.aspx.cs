using System;
using System.Data;
using System.Globalization;
using System.Text;
using OMS.Common.BLL;
using OMS.Common.Helpers;
using OMS.Common.Models;

namespace OMS.Analytics
{
    public partial class Analytics : System.Web.UI.Page
    {
        // Chart payloads emitted into the page script (set during BindAll).
        protected string RevenueChartJson  = "{\"labels\":[],\"data\":[]}";
        protected string PaymentChartJson  = "{\"labels\":[],\"data\":[]}";
        protected string TopItemsChartJson = "{\"labels\":[],\"data\":[]}";

        protected void Page_Load(object sender, EventArgs e)
        {
            SecurityHelper.RequireUrlAccess();
            if (!IsPostBack)
            {
                var today = LocalToday();
                txtStart.Text = today.AddDays(-29).ToString(StartFmt);
                txtEnd.Text   = today.ToString(EndFmt);
                BindAll();
            }
        }

        // Full-day defaults for the date-and-time pickers (value format of <input type=datetime-local>).
        private const string StartFmt = "yyyy-MM-dd'T'00:00";
        private const string EndFmt   = "yyyy-MM-dd'T'23:59";

        // Exact time window (local time) when the user narrowed the times; otherwise null = whole business days.
        private DateTime? _from, _to;

        protected void btnApply_Click(object sender, EventArgs e) => BindAll();

        // 7d / 30d / 90d quick presets.
        protected void lbPreset_Click(object sender, EventArgs e)
        {
            int days;
            int.TryParse(((System.Web.UI.WebControls.LinkButton)sender).CommandArgument, out days);
            if (days <= 0) days = 30;

            var today = LocalToday();
            txtStart.Text = today.AddDays(-(days - 1)).ToString(StartFmt);
            txtEnd.Text   = today.ToString(EndFmt);
            BindAll();
        }

        private void BindAll()
        {
            var today = LocalToday();
            DateTime start, end;
            DateTime s0, e0;
            s0 = DateTime.TryParse(txtStart.Text, out s0) ? s0 : today.AddDays(-29);
            e0 = DateTime.TryParse(txtEnd.Text,   out e0) ? e0 : today.AddHours(23).AddMinutes(59);

            // Guard against an inverted range.
            if (e0 < s0) { var t = s0; s0 = e0; e0 = t; }

            // Full days (00:00 to 23:59) = report by business day. Anything narrower = exact time window.
            bool exact = !(s0.TimeOfDay == TimeSpan.Zero && e0.TimeOfDay >= new TimeSpan(23, 59, 0));
            _from = exact ? (DateTime?)s0 : null;
            _to   = exact ? (DateTime?)e0.AddSeconds(59) : null;   // the picker has minute precision: include the whole last minute
            start = s0.Date; end = e0.Date;

            litRangeLabel.Text = exact
                ? s0.ToString("dd MMM yyyy, hh:mm tt") + " – " + e0.ToString("dd MMM yyyy, hh:mm tt")
                : start.ToString("dd MMM yyyy") + " – " + end.ToString("dd MMM yyyy");

            BindSummary(start, end);

            DataTable revenue  = DashboardService.RevenueByDay(start, end, _from, _to);
            DataTable topItems = DashboardService.TopMenuItems(start, end, 10, _from, _to);
            DataTable payments = DashboardService.PaymentAnalytics(start, end, _from, _to);
            DataTable hourly   = DashboardService.OrdersByHour(start, end, _from, _to);

            gvRevenue.DataSource  = revenue;  gvRevenue.DataBind();
            gvTopItems.DataSource = topItems; gvTopItems.DataBind();
            gvHourly.DataSource   = hourly;   gvHourly.DataBind();

            RevenueChartJson  = BuildChartJson(revenue,  "SaleDate", "Revenue",    isDate: true);
            TopItemsChartJson = BuildChartJson(topItems, "ItemName", "OrderCount", isDate: false);
            PaymentChartJson  = BuildChartJson(payments, "PaymentMethod", "Revenue", isDate: false);

            // Draw the charts with the data just bound - also during partial-page refreshes.
            System.Web.UI.ScriptManager.RegisterStartupScript(updAnalytics, typeof(System.Web.UI.UpdatePanel), "renderCharts",
                "renderCharts(" + RevenueChartJson + "," + PaymentChartJson + "," + TopItemsChartJson + ");", true);
        }

        private void BindSummary(DateTime start, DateTime end)
        {
            AnalyticsSummary s = DashboardService.AnalyticsSummary(start, end, _from, _to);

            litRevenue.Text   = "Rs. " + s.TotalRevenue.ToString("N0");
            litOrders.Text    = s.TotalOrders.ToString("N0");
            litAov.Text       = "Rs. " + s.AvgOrderValue.ToString("N0");
            litCompleted.Text = s.CompletedOrders.ToString("N0");
            litActive.Text    = s.ActiveOrders.ToString("N0");
            litCancelled.Text       = s.CancelledOrders.ToString("N0");
            litCancelledAmount.Text = "Rs. " + s.CancelledAmount.ToString("N0") + " not counted as revenue";

            litRevenueDelta.Text = DeltaBadge(s.RevenueChangePct);
            litOrdersDelta.Text  = DeltaBadge(s.OrdersChangePct);
        }

        // Renders a small up/down % badge vs the previous period.
        private static string DeltaBadge(decimal? pct)
        {
            if (pct == null) return "<span class=\"badge badge-subtle-secondary fs--2\">—</span>";

            bool up = pct.Value >= 0;
            string cls   = up ? "badge-subtle-success" : "badge-subtle-danger";
            string arrow = up ? "fa-caret-up" : "fa-caret-down";
            string sign  = up ? "+" : "";
            return string.Format(
                "<span class=\"badge {0} fs--2\"><span class=\"fas {1} me-1\"></span>{2}{3}%</span>",
                cls, arrow, sign, pct.Value.ToString("0.#", CultureInfo.InvariantCulture));
        }

        // Builds {"labels":[...],"data":[...]} from a table's label + numeric columns.
        private static string BuildChartJson(DataTable dt, string labelCol, string valueCol, bool isDate)
        {
            var labels = new StringBuilder();
            var data   = new StringBuilder();

            if (dt != null)
            {
                foreach (DataRow r in dt.Rows)
                {
                    if (labels.Length > 0) { labels.Append(','); data.Append(','); }

                    string label = isDate
                        ? Convert.ToDateTime(r[labelCol]).ToString("dd MMM")
                        : Convert.ToString(r[labelCol]);
                    labels.Append(JsonString(label));

                    decimal v = r[valueCol] == DBNull.Value ? 0m : Convert.ToDecimal(r[valueCol]);
                    data.Append(v.ToString(CultureInfo.InvariantCulture));
                }
            }

            return "{\"labels\":[" + labels + "],\"data\":[" + data + "]}";
        }

        // Minimal JSON string escaping for chart labels.
        private static string JsonString(string s)
        {
            if (s == null) return "\"\"";
            var sb = new StringBuilder("\"");
            foreach (char c in s)
            {
                switch (c)
                {
                    case '"':  sb.Append("\\\""); break;
                    case '\\': sb.Append("\\\\"); break;
                    case '\n': sb.Append("\\n");  break;
                    case '\r': sb.Append("\\r");  break;
                    case '\t': sb.Append("\\t");  break;
                    default:
                        if (c < ' ') sb.AppendFormat("\\u{0:x4}", (int)c);
                        else sb.Append(c);
                        break;
                }
            }
            sb.Append('"');
            return sb.ToString();
        }

        // Restaurant operates in UTC+5; "today" is the local business day.
        private static DateTime LocalToday() => DateTime.UtcNow.AddHours(5).Date;
    }
}
