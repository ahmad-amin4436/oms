using System;
using System.Data;
using System.Linq;
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
            SecurityHelper.RequireRoles("Admin");
            if (!SecurityHelper.IsInRole("Admin")) return;   // redirect is queued, stop here
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
                int pct   = total == 0 ? 0 : (int)Math.Round(count * 100m / total);
                view.Rows.Add(s.Status, count, pct, s.BarClass);
            }

            rptBreakdown.DataSource = view;
            rptBreakdown.DataBind();
        }

        // ── Total Sales line chart (This Month vs Last Month, real data) ──

        private void BindTotalSalesChart()
        {
            DataTable dt = DashboardService.TwoMonthDailySales(LocalToday);

            var labels    = new System.Text.StringBuilder();
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
            int dineIn   = T("DineInOrders");
            int takeaway = T("TakeawayOrders");
            int delivery = T("DeliveryOrders");

            litDineInPct.Text   = Pct(dineIn, total);
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
            litTodaySales.Text  = "Rs. " + summary.TodayRevenue.ToString("N0");

            // Overall, all-time figures (one aggregate query, see BindDashboard)
            int totalOrders    = T("TotalOrders");
            int itemsSold      = DashboardService.ItemsSold();
            decimal grossSale  = _totals == null ? 0m : Convert.ToDecimal(_totals["GrossSales"]);   // paid (Confirmed) orders only
            int cancelled      = T("CancelledOrders");
            int processing     = T("PendingOrders");                                               // unpaid
            int confirmedCount = T("ConfirmedOrders");
            decimal avgOrder   = confirmedCount == 0 ? 0 : Math.Round(grossSale / confirmedCount, 2);

            // "Weekly sales" + "Total order" mini-cards
            decimal weekSales = WeekRevenue();
            litWeeklySales.Text = "Rs. " + FormatK(weekSales);
            litTotalOrder.Text  = FormatK(totalOrders);

            // Stat grid
            litOrders.Text     = totalOrders.ToString("N0");
            litItemsSold.Text  = itemsSold.ToString("N0");
            litCancelled.Text  = cancelled.ToString("N0");
            litGrossSale.Text  = "Rs. " + grossSale.ToString("N0");
            litAvgOrder.Text   = "Rs. " + avgOrder.ToString("N0");
            litProcessing.Text = processing.ToString("N0");

            // Admin counts (users / menu / unread messages / active offers)
            DataTable adminStats = DBHelper.ExecuteDataTable("sp_GetAdminStats");
            if (adminStats.Rows.Count > 0)
            {
                DataRow a = adminStats.Rows[0];
                litMenuCount.Text  = Convert.ToInt32(a["MenuCount"]).ToString("N0");
                litUnread.Text     = Convert.ToInt32(a["UnreadMessages"]).ToString("N0");
                litPendingFulfil.Text = summary.PendingOrders.ToString("N0");
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
        }

        // Badge class for an order status value (matches the workflow colours).
        protected string StatusBadge(object status)
        {
            switch (Convert.ToString(status))
            {
                case "Confirmed": return "badge-subtle-success";
                case "Pending":   return "badge-subtle-warning";
                case "Cancelled": return "badge-subtle-danger";
                default:          return "badge-subtle-secondary";
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
            var taked  = new int[13][];
            for (int m = 1; m <= 12; m++)
            {
                int days = DateTime.DaysInMonth(year, m);
                dineIn[m] = new int[days];
                taked[m]  = new int[days];
            }
            int thisMonthTotal = 0;
            foreach (DataRow r in dt.Rows)
            {
                int m = Convert.ToInt32(r["MonthNo"]), day = Convert.ToInt32(r["DayNo"]);
                if (m < 1 || m > 12 || day < 1 || day > dineIn[m].Length) continue;
                int di = Convert.ToInt32(r["DineIn"]), td = Convert.ToInt32(r["TakeawayDelivery"]);
                dineIn[m][day - 1] = di;
                taked[m][day - 1]  = td;
                if (m == LocalToday.Month) thisMonthTotal += di + td;
            }

            var dineInSb = new System.Text.StringBuilder();
            var takedSb  = new System.Text.StringBuilder();
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
            int thisDi  = Convert.ToInt32(r["ThisDineIn"]);
            int thisTa  = Convert.ToInt32(r["ThisTakeaway"]);
            int thisDe  = Convert.ToInt32(r["ThisDelivery"]);
            int thisPe  = Convert.ToInt32(r["ThisPending"]);
            int thisPr  = Convert.ToInt32(r["ThisConfirmed"]);
            int thisDd  = Convert.ToInt32(r["ThisCancelled"]);
            int lastDi  = Convert.ToInt32(r["LastDineIn"]);
            int lastTa  = Convert.ToInt32(r["LastTakeaway"]);
            int lastDe  = Convert.ToInt32(r["LastDelivery"]);
            int lastPe  = Convert.ToInt32(r["LastPending"]);
            int lastPr  = Convert.ToInt32(r["LastConfirmed"]);
            int lastDd  = Convert.ToInt32(r["LastCancelled"]);

            RadarJson =
                "{\"thisMonth\":[" + thisDi + "," + thisTa + "," + thisDe + "," + thisPe + "," + thisPr + "," + thisDd + "]" +
                ",\"lastMonth\":[" + lastDi + "," + lastTa + "," + lastDe + "," + lastPe + "," + lastPr + "," + lastDd + "]}";

            litRadarThisMonth.Text = (thisDi + thisTa + thisDe).ToString("N0") + " orders";
            litRadarLastMonth.Text = (lastDi + lastTa + lastDe).ToString("N0") + " orders";
        }

        // ── Best Selling Products table ──────────────────────────────

        private void BindBestSelling()
        {
            // Top items over the last 30 local days.
            DataTable top = DashboardService.TopMenuItems(LocalToday.AddDays(-29), LocalToday, 7);

            decimal totalUnits = top.AsEnumerable().Sum(r => Convert.ToInt32(r["OrderCount"]));
            decimal totalRev   = top.AsEnumerable().Sum(r => Convert.ToDecimal(r["Revenue"]));

            // Add computed share columns for the template's count/revenue percentages.
            if (!top.Columns.Contains("OrderPct"))   top.Columns.Add("OrderPct", typeof(int));
            if (!top.Columns.Contains("RevenuePct")) top.Columns.Add("RevenuePct", typeof(int));
            foreach (DataRow r in top.Rows)
            {
                int units = Convert.ToInt32(r["OrderCount"]);
                decimal rev = Convert.ToDecimal(r["Revenue"]);
                r["OrderPct"]   = totalUnits == 0 ? 0 : (int)Math.Round(units / totalUnits * 100m);
                r["RevenuePct"] = totalRev   == 0 ? 0 : (int)Math.Round(rev / totalRev * 100m);
            }

            litBestTotalOrders.Text = ((int)totalUnits).ToString("N0");

            rptBest.DataSource = top.Rows.Count > 0 ? top : null;
            rptBest.DataBind();

            // Build the Top Products chart payload from the same data.
            var lblSb  = new System.Text.StringBuilder();
            var unitSb = new System.Text.StringBuilder();
            var revSb  = new System.Text.StringBuilder();
            foreach (DataRow r in top.Rows)
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
    }
}
