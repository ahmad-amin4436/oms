using System.Collections.Generic;

namespace OMS.Common.Models
{
    public class NavMenuSection
    {
        public int SectionID { get; set; }
        public string SectionName { get; set; }
        public int SortOrder { get; set; }
        public List<NavMenuGroup> Groups { get; set; } = new List<NavMenuGroup>();
    }
}
