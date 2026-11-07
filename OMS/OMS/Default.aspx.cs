using System;
using System.Collections.Generic;
using System.Data;
using System.Globalization;
using System.Linq;
using System.Text;
using System.Web;
using System.Web.UI;
using OMS.Common.BLL;
using OMS.Common.DAL;
using OMS.Common.Helpers;
using OMS.Common.Models;

namespace OMS
{
    public partial class _Default : Page
    {
        // Local business day (UTC+5), matching the rest of the app.
        private static DateTime LocalToday => DateTime.UtcNow.AddHours(5).Date;

        // Total Sales chart payload, emitted into the page script.
        protected string TotalSalesChartJson = "{\"labels\":[],\"thisMonth\":[],\"lastMonth\":[]}";

        // Top Products chart payload (top items: units + revenue).
        protected string TopProductsChartJson = "{\"labels\":[],\"units\":[],\"revenue\":[]}";

        // Daily Orders chart: 12 months × per-day DineIn/TakeawayDelivery counts.
        protected string DailyOrdersJson = "{\"dineIn\":[],\"takeawayDelivery\":[]}";

        // Radar chart: this-month vs last-month revenue by order type.
        protected string RadarJson = "{\"thisMonth\":[0,0,0],\"lastMonth\":[0,0,0]}";

        protected void Page_Load(object sender, EventArgs e)
        {
            SecurityHelper.RequireUrlAccess();
            SecurityHelper.RequirePermission("Dashboard.View");
            bool canExport = SecurityHelper.CanPerform("Dashboard.Export");
            pnlSalesExport.Visible = pnlTopExport.Visible = pnlRecentExport.Visible = canExport;
            MaintainScrollPositionOnPostBack = true;          // keep the scroll spot after View All / range / export postbacks
            if (!IsPostBack)
                BindDashboard();
        }

        // All-time totals, read once per page load (one aggregate query) and shared by the cards below.
        private DataRow _totals;
        private int T(string column) { return _totals == null ? 0 : Convert.ToInt32(_totals[column]); }

        private void BindDashboard()
        {
            _totals = DashboardService.Totals();
            BindGreeting();
            BindHeadlineAndStats();
            BindShareCards();
            BindOrderBreakdown();
            BindTotalSalesChart();
            BindDailyOrdersChart();
            BindRadarChart();
            BindRecentOrders();
            BindBestSelling();
        }

        // Best Selling range dropdown (Last 7 days / Last Month / Last Year).
        // A postback re-renders the page, so the whole dashboard (and its chart JSON) is rebuilt.
        protected void ddlBestRange_SelectedIndexChanged(object sender, EventArgs e)
        {
            BindDashboard();
        }

        // View All / View Less toggle for the Best Selling table (stays on this page).
        private bool BestShowAll
        {
            get { return ViewState["BestShowAll"] is bool && (bool)ViewState["BestShowAll"]; }
            set { ViewState["BestShowAll"] = value; }
        }

        protected void btnBestViewAll_Click(object sender, EventArgs e)
        {
            BestShowAll = !BestShowAll;
            BindDashboard();
        }

        // Number of days selected in the Best Selling range dropdown (default = 30, the previous fixed range).
        private int BestRangeDays()
        {
            int d;
            return int.TryParse(ddlBestRange.SelectedValue, out d) && d > 0 ? d : 30;
        }

        // ── "Order Breakdown" card (count + share per order status) ───

        // Pending = unpaid, Confirmed = fully paid (Cancelled is the admin-only void).
        private static readonly (string Status, string BarClass)[] StatusFlow =
        {
            ("Pending",   "bg-warning"),
            ("Confirmed", "bg-success"),
            ("Cancelled", "bg-danger"),
        };

        private void BindOrderBreakdown()
        {
            int total = T("TotalOrders");

            var view = new DataTable();
            view.Columns.Add("Status", typeof(string));
            view.Columns.Add("Count", typeof(int));
            view.Columns.Add("Pct", typeof(int));
            view.Columns.Add("BarClass", typeof(string));

            foreach (var s in StatusFlow)
            {
                int count = T(s.Status + "Orders");
                int pct = total == 0 ? 0 : (int)Math.Round(count * 100m / total);
                view.Rows.Add(s.Status, count, pct, s.BarClass);
            }

            rptBreakdown.DataSource = view;
            rptBreakdown.DataBind();
        }

        // ── Total Sales line chart (This Month vs Last Month, real data) ──

        private void BindTotalSalesChart()
        {
            DataTable dt = DashboardService.TwoMonthDailySales(LocalToday);

            var labels = new System.Text.StringBuilder();
            var thisMonth = new System.Text.StringBuilder();
            var lastMonth = new System.Text.StringBuilder();
            decimal thisTotal = 0m, lastTotal = 0m;

            foreach (DataRow r in dt.Rows)
            {
                if (labels.Length > 0) { labels.Append(','); thisMonth.Append(','); lastMonth.Append(','); }

                labels.Append(Convert.ToInt32(r["DayNo"]));   // day-of-month number as label
                decimal tm = Convert.ToDecimal(r["ThisMonth"]);
                decimal lm = Convert.ToDecimal(r["LastMonth"]);
                thisMonth.Append(tm.ToString(System.Globalization.CultureInfo.InvariantCulture));
                lastMonth.Append(lm.ToString(System.Globalization.CultureInfo.InvariantCulture));
                thisTotal += tm;
                lastTotal += lm;
            }

            TotalSalesChartJson =
                "{\"labels\":[" + labels + "],\"thisMonth\":[" + thisMonth + "],\"lastMonth\":[" + lastMonth + "]}";

            litSalesThisMonth.Text = "Rs. " + thisTotal.ToString("N0");
            litSalesLastMonth.Text = "Rs. " + lastTotal.ToString("N0");
        }

        // ── "Order Completion" + "Order Types" cards ─────────────────

        private void BindShareCards()
        {
            int total = T("TotalOrders");

            // Order Completion = Confirmed (paid) / total
            int delivered = T("ConfirmedOrders");
            int completionPct = total == 0 ? 0 : (int)Math.Round(delivered * 100m / total);
            litCompletionPct.Text = completionPct + "%";

            // Order Types split
            int dineIn = T("DineInOrders");
            int takeaway = T("TakeawayOrders");
            int delivery = T("DeliveryOrders");

            litDineInPct.Text = Pct(dineIn, total);
            litTakeawayPct.Text = Pct(takeaway, total);
            litDeliveryPct.Text = Pct(delivery, total);
            litTotalOrdersCenter.Text = total.ToString("N0");
        }

        private static string Pct(int part, int total)
            => (total == 0 ? 0 : (int)Math.Round(part * 100m / total)) + "%";

        // ── Greeting ─────────────────────────────────────────────────

        private void BindGreeting()
        {
            int hour = DateTime.UtcNow.AddHours(5).Hour;
            string part = hour < 12 ? "Morning" : hour < 17 ? "Afternoon" : "Evening";
            string name = SecurityHelper.UserName;
            litGreeting.Text = "Good " + part + (string.IsNullOrEmpty(name) ? "!" : ", " + Server.HtmlEncode(name) + "!");
        }

        // ── Headline numbers + the 6-cell stat grid ──────────────────

        private void BindHeadlineAndStats()
        {
            DashboardSummary summary = DashboardService.GetSummary(LocalToday);

            // Today's headline
            litTodayVisits.Text = summary.TodayOrders.ToString("N0");
            litTodaySales.Text = "Rs. " + summary.TodayRevenue.ToString("N0");

            // Overall, all-time figures (one aggregate query, see BindDashboard)
            int totalOrders = T("TotalOrders");
            int itemsSold = DashboardService.ItemsSold();
            decimal grossSale = _totals == null ? 0m : Convert.ToDecimal(_totals["GrossSales"]);   // paid (Confirmed) orders only
            int cancelled = T("CancelledOrders");
            int processing = T("PendingOrders");                                               // unpaid
            int confirmedCount = T("ConfirmedOrders");
            decimal avgOrder = confirmedCount == 0 ? 0 : Math.Round(grossSale / confirmedCount, 2);

            // "Weekly sales" + "Total order" mini-cards
            decimal weekSales = WeekRevenue();
            litWeeklySales.Text = "Rs. " + FormatK(weekSales);
            litTotalOrder.Text = FormatK(totalOrders);

            // Stat grid
            litOrders.Text = totalOrders.ToString("N0");
            litItemsSold.Text = itemsSold.ToString("N0");
            litCancelled.Text = cancelled.ToString("N0");
            litGrossSale.Text = "Rs. " + grossSale.ToString("N0");
            litAvgOrder.Text = "Rs. " + avgOrder.ToString("N0");
            litProcessing.Text = processing.ToString("N0");

            // "Pending fulfilment" comes from the summary, so it no longer depends on the admin-stats query returning a row.
            litPendingFulfil.Text = summary.PendingOrders.ToString("N0");

            // Admin counts (users / menu / unread messages / active offers)
            DataTable adminStats = DBHelper.ExecuteDataTable("sp_GetAdminStats");
            if (adminStats.Rows.Count > 0)
            {
                DataRow a = adminStats.Rows[0];
                litMenuCount.Text = Convert.ToInt32(a["MenuCount"]).ToString("N0");
                litUnread.Text = Convert.ToInt32(a["UnreadMessages"]).ToString("N0");
            }
        }


        // Paid/gross revenue for the last 7 local days.
        private static decimal WeekRevenue()
        {
            DataTable dt = DashboardService.RevenueByDay(LocalToday.AddDays(-6), LocalToday);
            return dt.AsEnumerable().Sum(r => Convert.ToDecimal(r["Revenue"]));
        }

        // ── Recent Purchases table ───────────────────────────────────

        private void BindRecentOrders()
        {
            DataTable orders = DashboardService.RecentOrders(14);   // newest first
            rptRecent.DataSource = orders.Rows.Count > 0 ? orders : null;
            rptRecent.DataBind();
            litRecentRowCount.Text = orders.Rows.Count + (orders.Rows.Count == 1 ? " row" : " rows") + " shown in this table.";
        }

        // Badge class for an order status value (matches the workflow colours).
        protected string StatusBadge(object status)
        {
            switch (Convert.ToString(status))
            {
                case "Confirmed": return "badge-subtle-success";
                case "Pending": return "badge-subtle-warning";
                case "Cancelled": return "badge-subtle-danger";
                default: return "badge-subtle-secondary";
            }
        }

        // ── Daily Orders line chart (DineIn vs Takeaway+Delivery, all 12 months) ──

        private void BindDailyOrdersChart()
        {
            // One query for the whole year (rows only for days that had orders); the arrays below are
            // laid out month by month, one value per day, zero where nothing was ordered.
            int year = LocalToday.Year;
            DataTable dt = DashboardService.DailyOrdersByTypeYear(year);

            var dineIn = new int[13][];
            var taked = new int[13][];
            for (int m = 1; m <= 12; m++)
            {
                int days = DateTime.DaysInMonth(year, m);
                dineIn[m] = new int[days];
                taked[m] = new int[days];
            }
            int thisMonthTotal = 0;
            foreach (DataRow r in dt.Rows)
            {
                int m = Convert.ToInt32(r["MonthNo"]), day = Convert.ToInt32(r["DayNo"]);
                if (m < 1 || m > 12 || day < 1 || day > dineIn[m].Length) continue;
                int di = Convert.ToInt32(r["DineIn"]), td = Convert.ToInt32(r["TakeawayDelivery"]);
                dineIn[m][day - 1] = di;
                taked[m][day - 1] = td;
                if (m == LocalToday.Month) thisMonthTotal += di + td;
            }

            var dineInSb = new System.Text.StringBuilder();
            var takedSb = new System.Text.StringBuilder();
            for (int m = 1; m <= 12; m++)
            {
                if (m > 1) { dineInSb.Append(','); takedSb.Append(','); }
                dineInSb.Append('[').Append(string.Join(",", dineIn[m])).Append(']');
                takedSb.Append('[').Append(string.Join(",", taked[m])).Append(']');
            }

            DailyOrdersJson = "{\"dineIn\":[" + dineInSb + "],\"takeawayDelivery\":[" + takedSb + "]}";
            litDailyOrdersTotal.Text = thisMonthTotal.ToString("N0");
        }

        // ── Sales by POS radar chart — 6 order metrics, this month vs last month ──

        private void BindRadarChart()
        {
            DataRow r = DashboardService.RevenueByOrderType(LocalToday);
            if (r == null) return;

            var inv = System.Globalization.CultureInfo.InvariantCulture;
            int thisDi = Convert.ToInt32(r["ThisDineIn"]);
            int thisTa = Convert.ToInt32(r["ThisTakeaway"]);
            int thisDe = Convert.ToInt32(r["ThisDelivery"]);
            int thisPe = Convert.ToInt32(r["ThisPending"]);
            int thisPr = Convert.ToInt32(r["ThisConfirmed"]);
            int thisDd = Convert.ToInt32(r["ThisCancelled"]);
            int lastDi = Convert.ToInt32(r["LastDineIn"]);
            int lastTa = Convert.ToInt32(r["LastTakeaway"]);
            int lastDe = Convert.ToInt32(r["LastDelivery"]);
            int lastPe = Convert.ToInt32(r["LastPending"]);
            int lastPr = Convert.ToInt32(r["LastConfirmed"]);
            int lastDd = Convert.ToInt32(r["LastCancelled"]);

            RadarJson =
                "{\"thisMonth\":[" + thisDi + "," + thisTa + "," + thisDe + "," + thisPe + "," + thisPr + "," + thisDd + "]" +
                ",\"lastMonth\":[" + lastDi + "," + lastTa + "," + lastDe + "," + lastPe + "," + lastPr + "," + lastDd + "]}";

            litRadarThisMonth.Text = (thisDi + thisTa + thisDe).ToString("N0") + " orders";
            litRadarLastMonth.Text = (lastDi + lastTa + lastDe).ToString("N0") + " orders";
        }

        // ── Best Selling Products table ──────────────────────────────

        private void BindBestSelling()
        {
            // Range selected in the dropdown (default: last 30 local days).
            DateTime from = LocalToday.AddDays(-(BestRangeDays() - 1));

            // The Top Products chart always uses the top 7; the table shows the top 7, or every item after "View All".
            DataTable chartTop = DashboardService.TopMenuItems(from, LocalToday, 7);
            DataTable top = BestShowAll ? DashboardService.TopMenuItems(from, LocalToday, 1000) : chartTop;

            btnBestViewAll.Text = BestShowAll ? "View Less" : "View All";

            decimal totalUnits = top.AsEnumerable().Sum(r => Convert.ToInt32(r["OrderCount"]));
            decimal totalRev = top.AsEnumerable().Sum(r => Convert.ToDecimal(r["Revenue"]));

            // Add computed share columns for the template's count/revenue percentages.
            if (!top.Columns.Contains("OrderPct")) top.Columns.Add("OrderPct", typeof(int));
            if (!top.Columns.Contains("RevenuePct")) top.Columns.Add("RevenuePct", typeof(int));
            foreach (DataRow r in top.Rows)
            {
                int units = Convert.ToInt32(r["OrderCount"]);
                decimal rev = Convert.ToDecimal(r["Revenue"]);
                r["OrderPct"] = totalUnits == 0 ? 0 : (int)Math.Round(units / totalUnits * 100m);
                r["RevenuePct"] = totalRev == 0 ? 0 : (int)Math.Round(rev / totalRev * 100m);
            }

            litBestTotalOrders.Text = ((int)totalUnits).ToString("N0");

            rptBest.DataSource = top.Rows.Count > 0 ? top : null;
            rptBest.DataBind();

            // Build the Top Products chart payload (top 7 only).
            var lblSb = new System.Text.StringBuilder();
            var unitSb = new System.Text.StringBuilder();
            var revSb = new System.Text.StringBuilder();
            foreach (DataRow r in chartTop.Rows)
            {
                if (lblSb.Length > 0) { lblSb.Append(','); unitSb.Append(','); revSb.Append(','); }
                lblSb.Append(JsonStr(Convert.ToString(r["ItemName"])));
                unitSb.Append(Convert.ToInt32(r["OrderCount"]));
                revSb.Append(Convert.ToDecimal(r["Revenue"]).ToString("0", System.Globalization.CultureInfo.InvariantCulture));
            }
            TopProductsChartJson =
                "{\"labels\":[" + lblSb + "],\"units\":[" + unitSb + "],\"revenue\":[" + revSb + "]}";
        }

        // Minimal JSON string escaping for chart labels.
        private static string JsonStr(string s)
        {
            if (string.IsNullOrEmpty(s)) return "\"\"";
            return "\"" + s.Replace("\\", "\\\\").Replace("\"", "\\\"") + "\"";
        }

        // ── Helpers ──────────────────────────────────────────────────

        // Compact "K" formatting (e.g. 47200 -> "47.2K", 980 -> "980").
        protected static string FormatK(decimal value)
        {
            if (Math.Abs(value) >= 1000)
                return (value / 1000m).ToString("0.#") + "K";
            return value.ToString("0");
        }

        protected static string Fmt(object amount)
            => "Rs. " + Convert.ToDecimal(amount).ToString("N0");

        // ── Export buttons ───────────────────────────────────────────

        // Total Sales card → Excel
        protected void btnSalesExcel_Click(object sender, EventArgs e)
        {
            SecurityHelper.RequirePermission("Dashboard.Export");
            List<object[]> rows = SalesRows();
            SendExcel("Total_Sales", "Total Sales - This Month vs Last Month (Rs.)",
                      new[] { "Day", "This Month", "Last Month" }, rows);
        }

        // Total Sales card → PDF
        protected void btnSalesPDF_Click(object sender, EventArgs e)
        {
            SecurityHelper.RequirePermission("Dashboard.Export");
            List<object[]> rows = SalesRows();
            var lines = new List<string>
            {
                "Total Sales - This Month vs Last Month (Rs.)",
                "Generated: " + DateTime.UtcNow.AddHours(5).ToString("yyyy-MM-dd HH:mm"),
                "",
                "Day".PadRight(10) + "This Month".PadLeft(18) + "Last Month".PadLeft(18),
                new string('-', 46)
            };
            foreach (object[] r in rows)
            {
                lines.Add(Convert.ToString(r[0]).PadRight(10) +
                          Convert.ToDecimal(r[1]).ToString("N0").PadLeft(18) +
                          Convert.ToDecimal(r[2]).ToString("N0").PadLeft(18));
            }
            SendPdf("Total_Sales", lines);
        }

        // Top Products card → Excel
        protected void btnTopProductsExcel_Click(object sender, EventArgs e)
        {
            SecurityHelper.RequirePermission("Dashboard.Export");
            DataTable top = DashboardService.TopMenuItems(LocalToday.AddDays(-(BestRangeDays() - 1)), LocalToday, 7);
            var rows = new List<object[]>();
            foreach (DataRow r in top.Rows)
                rows.Add(new object[] { Convert.ToString(r["ItemName"]), Convert.ToInt32(r["OrderCount"]), Convert.ToDecimal(r["Revenue"]) });

            SendExcel("Top_Products", "Top Products (last " + BestRangeDays() + " days)",
                      new[] { "Item", "Units", "Revenue (Rs.)" }, rows);
        }

        // Top Products card → PDF
        protected void btnTopProductsPDF_Click(object sender, EventArgs e)
        {
            SecurityHelper.RequirePermission("Dashboard.Export");
            int days = BestRangeDays();
            DataTable top = DashboardService.TopMenuItems(LocalToday.AddDays(-(days - 1)), LocalToday, 7);
            var lines = new List<string>
            {
                "Top Products (last " + days + " days)",
                "Generated: " + DateTime.UtcNow.AddHours(5).ToString("yyyy-MM-dd HH:mm"),
                "",
                "Item".PadRight(36) + "Units".PadLeft(8) + "Revenue (Rs.)".PadLeft(16),
                new string('-', 60)
            };
            foreach (DataRow r in top.Rows)
            {
                string name = Convert.ToString(r["ItemName"]);
                if (name.Length > 34) name = name.Substring(0, 34);
                lines.Add(name.PadRight(36) +
                          Convert.ToInt32(r["OrderCount"]).ToString("N0").PadLeft(8) +
                          Convert.ToDecimal(r["Revenue"]).ToString("N0").PadLeft(16));
            }
            SendPdf("Top_Products", lines);
        }

        // Recent Purchases card → export with the columns ticked in the Export popup
        private static readonly (string Key, string Title, int Width, bool Right)[] RecentCols =
        {
            ("customer", "Customer",     22, false),
            ("phone",    "Phone",        15, false),
            ("order",    "Order #",      14, false),
            ("status",   "Status",       10, false),
            ("amount",   "Amount (Rs.)", 14, true),
        };

        // Columns ticked in the popup (all of them if nothing was posted).
        private List<(string Key, string Title, int Width, bool Right)> SelectedRecentCols()
        {
            var posted = new HashSet<string>(Request.Form.GetValues("expCols") ?? new string[0]);
            var list = RecentCols.Where(c => posted.Contains(c.Key)).ToList();
            return list.Count == 0 ? RecentCols.ToList() : list;
        }

        private static object RecentValue(DataRow r, string key)
        {
            switch (key)
            {
                case "customer":
                    string cust = Convert.ToString(r["CustomerName"]);
                    return string.IsNullOrEmpty(cust) ? "Walk-in" : cust;
                case "phone": return Convert.ToString(r["CustomerPhone"]);
                case "order": return Convert.ToString(r["OrderNumber"]);
                case "status": return Convert.ToString(r["Status"]);
                default: return Convert.ToDecimal(r["TotalAmount"]);
            }
        }

        protected void btnRecentExcel_Click(object sender, EventArgs e)
        {
            SecurityHelper.RequirePermission("Dashboard.Export");
            var cols = SelectedRecentCols();
            DataTable orders = DashboardService.RecentOrders(14);
            var rows = new List<object[]>();
            foreach (DataRow r in orders.Rows)
                rows.Add(cols.Select(c => RecentValue(r, c.Key)).ToArray());

            SendExcel("Recent_Purchases", "Recent Purchases", cols.Select(c => c.Title).ToArray(), rows);
        }

        protected void btnRecentPDF_Click(object sender, EventArgs e)
        {
            SecurityHelper.RequirePermission("Dashboard.Export");
            var cols = SelectedRecentCols();
            DataTable orders = DashboardService.RecentOrders(14);

            var lines = new List<string>
            {
                "Recent Purchases",
                "Generated: " + DateTime.UtcNow.AddHours(5).ToString("yyyy-MM-dd HH:mm"),
                ""
            };
            Func<string, int, bool, string> cell = (text, width, right) =>
            {
                if (text.Length > width - 1) text = text.Substring(0, width - 1);
                return right ? text.PadLeft(width) : text.PadRight(width);
            };
            lines.Add(string.Concat(cols.Select(c => cell(c.Title, c.Width, c.Right))));
            lines.Add(new string('-', cols.Sum(c => c.Width)));
            foreach (DataRow r in orders.Rows)
            {
                lines.Add(string.Concat(cols.Select(c =>
                {
                    object v = RecentValue(r, c.Key);
                    string t = v is decimal ? ((decimal)v).ToString("N0") : Convert.ToString(v);
                    return cell(t, c.Width, c.Right);
                })));
            }
            SendPdf("Recent_Purchases", lines);
        }

        // Day-by-day rows (+ a Total row) for the Total Sales export.
        private static List<object[]> SalesRows()
        {
            DataTable dt = DashboardService.TwoMonthDailySales(LocalToday);
            var rows = new List<object[]>();
            decimal thisTotal = 0m, lastTotal = 0m;
            foreach (DataRow r in dt.Rows)
            {
                decimal tm = Convert.ToDecimal(r["ThisMonth"]);
                decimal lm = Convert.ToDecimal(r["LastMonth"]);
                rows.Add(new object[] { Convert.ToInt32(r["DayNo"]), tm, lm });
                thisTotal += tm;
                lastTotal += lm;
            }
            rows.Add(new object[] { "Total", thisTotal, lastTotal });
            return rows;
        }

        // Sends an Excel-readable (.xls) table. No third-party library needed.
        private void SendExcel(string fileBase, string title, string[] headers, List<object[]> rows)
        {
            var sb = new StringBuilder();
            sb.Append("<html xmlns:x=\"urn:schemas-microsoft-com:office:excel\"><head><meta charset=\"utf-8\" /></head><body>");
            sb.Append("<table border=\"1\">");
            sb.Append("<tr><td colspan=\"" + headers.Length + "\" style=\"font-weight:bold;font-size:14pt\">" + HttpUtility.HtmlEncode(title) + "</td></tr>");
            sb.Append("<tr style=\"font-weight:bold;background-color:#E5E7EB\">");
            foreach (string h in headers) sb.Append("<td>" + HttpUtility.HtmlEncode(h) + "</td>");
            sb.Append("</tr>");
            foreach (object[] row in rows)
            {
                sb.Append("<tr>");
                foreach (object v in row) sb.Append(ExcelCell(v));
                sb.Append("</tr>");
            }
            sb.Append("</table></body></html>");

            Response.Clear();
            Response.Buffer = true;
            Response.ContentType = "application/vnd.ms-excel";
            Response.Charset = "utf-8";
            Response.ContentEncoding = Encoding.UTF8;
            Response.AddHeader("Content-Disposition", "attachment; filename=" + fileBase + "_" + LocalToday.ToString("yyyyMMdd") + ".xls");
            Response.Write(sb.ToString());
            Response.Flush();
            Response.End();
        }

        private static string ExcelCell(object v)
        {
            if (v is int || v is long || v is decimal || v is double)
                return "<td>" + Convert.ToString(v, CultureInfo.InvariantCulture) + "</td>";
            // text cell (keeps phone numbers / order numbers from being reformatted by Excel)
            return "<td style=\"mso-number-format:'\\@'\">" + HttpUtility.HtmlEncode(Convert.ToString(v)) + "</td>";
        }

        // Builds and sends a simple multi-page text PDF (Courier, A4). No third-party library needed.
        private void SendPdf(string fileBase, List<string> lines)
        {
            byte[] pdf = BuildSimplePdf(lines);

            Response.Clear();
            Response.Buffer = true;
            Response.ContentType = "application/pdf";
            Response.AddHeader("Content-Disposition", "attachment; filename=" + fileBase + "_" + LocalToday.ToString("yyyyMMdd") + ".pdf");
            Response.AddHeader("Content-Length", pdf.Length.ToString());
            Response.BinaryWrite(pdf);
            Response.Flush();
            Response.End();
        }

        private static byte[] BuildSimplePdf(List<string> lines)
        {
            const int linesPerPage = 58;
            var pages = new List<List<string>>();
            for (int i = 0; i < lines.Count; i += linesPerPage)
                pages.Add(lines.Skip(i).Take(linesPerPage).ToList());
            if (pages.Count == 0) pages.Add(new List<string>());

            Encoding enc = Encoding.GetEncoding("ISO-8859-1");
            var ms = new System.IO.MemoryStream();
            Action<string> w = s => { byte[] b = enc.GetBytes(s); ms.Write(b, 0, b.Length); };

            int objCount = 3 + pages.Count * 2;      // 1 catalog, 2 pages, 3 font, then (page, content) pairs
            var off = new long[objCount + 1];

            w("%PDF-1.4\n");

            off[1] = ms.Position;
            w("1 0 obj\n<< /Type /Catalog /Pages 2 0 R >>\nendobj\n");

            string kids = string.Join(" ", Enumerable.Range(0, pages.Count).Select(i => (4 + 2 * i) + " 0 R"));
            off[2] = ms.Position;
            w("2 0 obj\n<< /Type /Pages /Kids [" + kids + "] /Count " + pages.Count + " >>\nendobj\n");

            off[3] = ms.Position;
            w("3 0 obj\n<< /Type /Font /Subtype /Type1 /BaseFont /Courier >>\nendobj\n");

            for (int i = 0; i < pages.Count; i++)
            {
                int pObj = 4 + 2 * i, cObj = 5 + 2 * i;

                var cs = new StringBuilder();
                cs.Append("BT\n/F1 9 Tf\n40 800 Td\n12 TL\n");
                foreach (string line in pages[i])
                    cs.Append("(" + PdfEsc(line) + ") Tj T*\n");
                cs.Append("ET");
                string content = cs.ToString();

                off[pObj] = ms.Position;
                w(pObj + " 0 obj\n<< /Type /Page /Parent 2 0 R /MediaBox [0 0 595 842] /Resources << /Font << /F1 3 0 R >> >> /Contents " + cObj + " 0 R >>\nendobj\n");

                off[cObj] = ms.Position;
                w(cObj + " 0 obj\n<< /Length " + content.Length + " >>\nstream\n" + content + "\nendstream\nendobj\n");
            }

            long xref = ms.Position;
            w("xref\n0 " + (objCount + 1) + "\n0000000000 65535 f \n");
            for (int i = 1; i <= objCount; i++)
                w(off[i].ToString("D10") + " 00000 n \n");
            w("trailer\n<< /Size " + (objCount + 1) + " /Root 1 0 R >>\nstartxref\n" + xref + "\n%%EOF");

            return ms.ToArray();
        }

        // Escape for a PDF literal string; anything outside printable ASCII becomes '?'.
        private static string PdfEsc(string s)
        {
            var sb = new StringBuilder();
            foreach (char c in s ?? "")
            {
                if (c == '(' || c == ')' || c == '\\') sb.Append('\\').Append(c);
                else if (c < 32 || c > 126) sb.Append('?');
                else sb.Append(c);
            }
            return sb.ToString();
        }
    }
}
