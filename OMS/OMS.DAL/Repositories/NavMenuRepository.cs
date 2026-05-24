using System;
using System.Collections.Generic;
using System.Data;
using OMS.Common.Interfaces;
using OMS.Common.Models;

namespace OMS.DAL.Repositories
{
    /// <summary>
    /// Fetches navigation-menu data via sp_GetNavMenuByRole
    /// and assembles the three-level hierarchy:
    ///   NavMenuSection → NavMenuGroup → NavMenuItem
    /// </summary>
    public class NavMenuRepository : INavMenuRepository
    {
        public IList<NavMenuSection> GetNavMenuByRole(string roleName)
        {
            var ds = DataHelper.ExecuteDataSet(
                "sp_GetNavMenuByRole",
                DataHelper.ParamString("@RoleName", roleName, 50));

            var sections   = new List<NavMenuSection>();
            var sectionMap = new Dictionary<int, NavMenuSection>();
            var groupMap   = new Dictionary<int, NavMenuGroup>();

            // --- Table 0: Sections ------------------------------------------
            if (ds.Tables.Count > 0)
            {
                foreach (DataRow row in ds.Tables[0].Rows)
                {
                    var sec = new NavMenuSection
                    {
                        SectionID   = Convert.ToInt32(row["SectionID"]),
                        SectionName = Convert.ToString(row["SectionName"]),
                        SortOrder   = Convert.ToInt32(row["SortOrder"])
                    };
                    sectionMap[sec.SectionID] = sec;
                    sections.Add(sec);
                }
            }

            // --- Table 1: Groups --------------------------------------------
            // Groups with SectionID = NULL are top-level (no section label).
            // We represent them as an implicit section with SectionID = 0.
            var topSection = new NavMenuSection { SectionID = 0, SectionName = string.Empty, SortOrder = 0 };

            if (ds.Tables.Count > 1)
            {
                foreach (DataRow row in ds.Tables[1].Rows)
                {
                    var grp = new NavMenuGroup
                    {
                        GroupID    = Convert.ToInt32(row["GroupID"]),
                        SectionID  = row["SectionID"] == DBNull.Value ? (int?)null : Convert.ToInt32(row["SectionID"]),
                        GroupName  = Convert.ToString(row["GroupName"]),
                        IconClass  = Convert.ToString(row["IconClass"]),
                        Url        = row["Url"]        == DBNull.Value ? null : Convert.ToString(row["Url"]),
                        CollapseId = row["CollapseId"] == DBNull.Value ? null : Convert.ToString(row["CollapseId"]),
                        SortOrder  = Convert.ToInt32(row["SortOrder"])
                    };
                    groupMap[grp.GroupID] = grp;

                    if (grp.SectionID.HasValue && sectionMap.TryGetValue(grp.SectionID.Value, out var parentSection))
                        parentSection.Groups.Add(grp);
                    else
                        topSection.Groups.Add(grp);   // no section — goes to implicit top section
                }
            }

            // Insert top-level section first if it has any groups
            if (topSection.Groups.Count > 0)
                sections.Insert(0, topSection);

            // --- Table 2: Items ---------------------------------------------
            if (ds.Tables.Count > 2)
            {
                foreach (DataRow row in ds.Tables[2].Rows)
                {
                    var item = new NavMenuItem
                    {
                        ItemID     = Convert.ToInt32(row["ItemID"]),
                        GroupID    = Convert.ToInt32(row["GroupID"]),
                        ItemName   = Convert.ToString(row["ItemName"]),
                        Url        = Convert.ToString(row["Url"]),
                        SortOrder  = Convert.ToInt32(row["SortOrder"]),
                        BadgeText  = row["BadgeText"]  == DBNull.Value ? null : Convert.ToString(row["BadgeText"]),
                        BadgeClass = row["BadgeClass"] == DBNull.Value ? null : Convert.ToString(row["BadgeClass"])
                    };

                    if (groupMap.TryGetValue(item.GroupID, out var parentGroup))
                        parentGroup.Items.Add(item);
                }
            }

            return sections;
        }
    }
}
