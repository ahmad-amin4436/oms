using System.Collections.Generic;

namespace OMS.Common.Models
{
    public class NavMenuGroup
    {
        public int     GroupID    { get; set; }
        public int?    SectionID  { get; set; }
        public string  GroupName  { get; set; }
        public string  IconClass  { get; set; }
        public string  Url        { get; set; }   // null = collapsible group
        public string  CollapseId { get; set; }   // null = direct link
        public int     SortOrder  { get; set; }
        public List<NavMenuItem> Items { get; set; } = new List<NavMenuItem>();

        public bool IsDirectLink    => !string.IsNullOrEmpty(Url);
        public bool IsCollapsible   => string.IsNullOrEmpty(Url) && !string.IsNullOrEmpty(CollapseId);
    }
}
