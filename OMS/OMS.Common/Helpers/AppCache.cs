using System;
using System.Collections.Concurrent;
using System.Web;
using System.Web.Caching;

namespace OMS.Common.Helpers
{
    /// <summary>
    /// Small in-memory cache for data that is read on almost every page but changes rarely
    /// (menu, settings, permissions, dashboard figures).
    ///
    /// Entries live in scopes. Writing through DBHelper bumps the scope's version (see ScopeForWrite), so
    /// the next read goes to the database: an edit shows up immediately, never after a timeout. The short
    /// time-to-live only covers changes made outside the application (e.g. a SQL script).
    /// </summary>
    public static class AppCache
    {
        private static readonly ConcurrentDictionary<string, int> Versions = new ConcurrentDictionary<string, int>();

        public static T GetOrAdd<T>(string scope, string key, int seconds, Func<T> factory)
        {
            var cache = HttpRuntime.Cache;
            string k = scope + "|" + Versions.GetOrAdd(scope, 0) + "|" + key;
            object hit = cache.Get(k);
            if (hit is T) return (T)hit;

            T value = factory();
            if (value != null)
                cache.Insert(k, value, null, DateTime.UtcNow.AddSeconds(seconds), Cache.NoSlidingExpiration);
            return value;
        }

        /// <summary>Forget everything in a scope (older entries can no longer be hit).</summary>
        public static void Clear(string scope)
        {
            Versions.AddOrUpdate(scope, 1, (s, v) => v + 1);
        }

        /// <summary>Which cached scope (if any) a write procedure invalidates.</summary>
        public static string ScopeForWrite(string procedure)
        {
            if (string.IsNullOrEmpty(procedure)) return null;
            switch (procedure)
            {
                case "sp_SaveMenuItem": case "sp_DeleteMenuItem": case "sp_ToggleMenuItemAvailability":
                case "sp_SaveCategory": case "sp_DeleteCategory": case "sp_SaveSizePricing": case "sp_SaveTopping":
                case "sp_SaveDeal": case "sp_DeleteDeal": case "sp_ToggleDealStatus":
                    return "menu";
                case "sp_SaveRole": case "sp_DeleteRole": case "sp_SetRoleNavGroups": case "sp_SetRoleNavItems":
                case "sp_SaveUser": case "sp_DeleteUser": case "sp_ToggleUserStatus":
                    return "auth";
                case "sp_SetSetting":
                    return "settings";
                case "sp_CreateOrder": case "sp_InsertOrderItem": case "sp_AddOrderItem": case "sp_ConfirmOrder":
                case "sp_CancelOrder": case "sp_CloseBusinessDay":
                    return "orders";
            }
            return null;
        }
    }
}