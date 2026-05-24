namespace OMS.Common.Models
{
    public class NavMenuItem
    {
        public int    ItemID     { get; set; }
        public int    GroupID    { get; set; }
        public string ItemName   { get; set; }
        public string Url        { get; set; }
        public int    SortOrder  { get; set; }
        public string BadgeText  { get; set; }
        public string BadgeClass { get; set; }
    }
}
