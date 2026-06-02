namespace OMS.Common.Models
{
    /// <summary>
    /// KPI totals for the Analytics page, with the preceding equal-length range
    /// captured so the page can show period-over-period deltas.
    /// </summary>
    public class AnalyticsSummary
    {
        public decimal TotalRevenue    { get; set; }
        public int     TotalOrders     { get; set; }
        public int     CompletedOrders { get; set; }   // Status = Delivered
        public int     ActiveOrders    { get; set; }   // in progress (not Delivered/Cancelled)
        public decimal AvgOrderValue   { get; set; }

        public decimal PrevRevenue   { get; set; }
        public int     PrevOrders    { get; set; }

        // Percentage change vs the previous range (null when there is no baseline).
        public decimal? RevenueChangePct => PercentChange(TotalRevenue, PrevRevenue);
        public decimal? OrdersChangePct  => PercentChange(TotalOrders, PrevOrders);

        private static decimal? PercentChange(decimal current, decimal previous)
        {
            if (previous == 0m) return current == 0m ? 0m : (decimal?)null;
            return System.Math.Round((current - previous) / previous * 100m, 1);
        }
    }
}
