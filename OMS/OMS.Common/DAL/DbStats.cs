using System;
using System.Collections.Generic;
using System.Text;
using System.Web;

namespace OMS.Common.DAL
{
    /// <summary>
    /// Per-request record of the database calls a page made (how many, how long). Emitted as a standard
    /// Server-Timing response header so it shows up in the browser's Network tab.
    /// </summary>
    public static class DbStats
    {
        private const string Key = "OMS.DbStats";

        private sealed class Entry { public string Name; public long Ms; }

        public static void Record(string procedure, long ms)
        {
            var ctx = HttpContext.Current;
            if (ctx == null) return;
            var list = ctx.Items[Key] as List<Entry>;
            if (list == null) ctx.Items[Key] = list = new List<Entry>();
            list.Add(new Entry { Name = procedure, Ms = ms });
        }

        /// <summary>Value for the Server-Timing header, or null when the request made no database calls.
        /// With <paramref name="detail"/> each query is listed (staff only).</summary>
        public static string Header(HttpContext ctx, bool detail)
        {
            var list = ctx == null ? null : ctx.Items[Key] as List<Entry>;
            if (list == null || list.Count == 0) return null;

            long total = 0;
            foreach (var e in list) total += e.Ms;
            var sb = new StringBuilder("db;dur=").Append(total).Append(";desc=\"").Append(list.Count).Append(" queries\"");
            if (detail)
            {
                int n = 0;
                foreach (var e in list)
                {
                    if (++n > 15) break;
                    sb.Append(", q").Append(n).Append(";dur=").Append(e.Ms).Append(";desc=\"").Append(e.Name).Append('"');
                }
            }
            return sb.ToString();
        }
    }
}