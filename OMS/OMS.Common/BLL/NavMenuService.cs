using System.Collections.Generic;
using OMS.Common.Interfaces;
using OMS.Common.Models;

namespace OMS.Common.BLL
{
    /// <summary>
    /// Business-logic layer for navigation menu retrieval.
    /// Depends on INavMenuRepository (injected), keeping BLL free of DAL specifics.
    /// </summary>
    public class NavMenuService
    {
        private readonly INavMenuRepository _repository;

        public NavMenuService(INavMenuRepository repository)
        {
            _repository = repository;
        }

        /// <summary>
        /// Returns nav sections + groups + items visible to the given role.
        /// Falls back to "Guest" when roleName is null or empty.
        /// </summary>
        public IList<NavMenuSection> GetNavSections(string roleName)
        {
            if (string.IsNullOrWhiteSpace(roleName))
                roleName = "Guest";

            return _repository.GetNavMenuByRole(roleName);
        }
    }
}
