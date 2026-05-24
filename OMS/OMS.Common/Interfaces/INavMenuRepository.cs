using System.Collections.Generic;
using OMS.Common.Models;

namespace OMS.Common.Interfaces
{
    public interface INavMenuRepository
    {
        /// <summary>
        /// Returns the full nav tree for the given role name.
        /// Pass "All" to retrieve items accessible to every authenticated user.
        /// </summary>
        IList<NavMenuSection> GetNavMenuByRole(string roleName);
    }
}
