namespace OMS.App_Code.Models
{
    public class DashboardSummary
    {
        public int TodayOrders { get; set; }
        public int YesterdayOrders { get; set; }
        public decimal TodayRevenue { get; set; }
        public int PendingOrders { get; set; }
        public string PopularItemName { get; set; }
        public int PopularItemCount { get; set; }
    }
}
