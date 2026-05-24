namespace OMS.Common.Models
{
    public class MenuItemModel
    {
        public int ItemID { get; set; }
        public int CategoryID { get; set; }
        public string CategoryName { get; set; }
        public string Name { get; set; }
        public string Description { get; set; }
        public decimal BasePrice { get; set; }
        public string ImagePath { get; set; }
        public bool IsAvailable { get; set; }
        public bool IsFeatured { get; set; }
    }
}
