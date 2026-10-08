using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Web;
using System.Web.UI;
using OMS.Common.BLL;
using OMS.Common.Models;
using OMS.DAL.Repositories;

namespace OMS
{
    public partial class SiteMaster : MasterPage
    {
        protected void Page_Load(object sender, EventArgs e)
        {
            FixScriptManagerPaths();

            // The menu is no longer stored in ViewState (it was 25+ KB uploaded on every click), so build it each
            // request; the menu data itself is cached per role, so this is cheap.
            RenderNavMenu();
        }

        // ----------------------------------------------------------------
        // Notifications (bell): unread customer messages + pending orders
        // ----------------------------------------------------------------

        protected override void OnPreRender(EventArgs e)
        {
            base.OnPreRender(e);
            string html = BuildNotificationsHtml();
            litNotif1.Text = html;
            litNotif2.Text = html;
            litNotif3.Text = html;
            litNotif4.Text = html;
        }

        
        private string BuildNotificationsHtml()
        {
            if (!OMS.Common.Helpers.SecurityHelper.IsAuthenticated) return string.Empty;

            bool canSeeMessages = OMS.Common.Helpers.SecurityHelper.IsInRole("Admin", "Manager");
            System.Data.DataTable dt = null;
            try
            {
                dt = OMS.Common.DAL.DBHelper.ExecuteDataTable("sp_GetNotifications",
                    OMS.Common.DAL.DBHelper.Parameter("@IncludeMessages", canSeeMessages));
            }
            catch { /* bell must never break a page (e.g. script not yet applied) */ }

            int count = dt == null ? 0 : dt.Rows.Count;
            var sb = new StringBuilder();
            sb.Append("<li class=\"nav-item dropdown\">");
            sb.Append("<a class=\"nav-link notification-indicator ")
              .Append(count > 0 ? "notification-indicator-primary " : "")
              .Append("px-0 fa-icon-wait\" id=\"navbarDropdownNotification\" role=\"button\" data-bs-toggle=\"dropdown\" aria-haspopup=\"true\" aria-expanded=\"false\" data-hide-on-body-scroll=\"data-hide-on-body-scroll\">")
              .Append("<span class=\"fas fa-bell\" data-fa-transform=\"shrink-6\" style=\"font-size: 33px;\"></span></a>");
            sb.Append("<div class=\"dropdown-menu dropdown-caret dropdown-menu-end dropdown-menu-card dropdown-menu-notification dropdown-caret-bg\" aria-labelledby=\"navbarDropdownNotification\">");
            sb.Append("<div class=\"card card-notification shadow-none\"><div class=\"card-header\"><div class=\"row justify-content-between align-items-center\">");
            sb.Append("<div class=\"col-auto\"><h6 class=\"card-header-title mb-0\">Notifications</h6></div>");
            if (canSeeMessages && count > 0)
                sb.Append("<div class=\"col-auto ps-0 ps-sm-3\"><a class=\"card-link fw-normal\" href=\"#\" data-mark-read=\"1\">Mark all as read</a></div>");
            sb.Append("</div></div><div class=\"scrollbar-overlay\" style=\"max-height: 19rem\"><div class=\"list-group list-group-flush fw-normal fs--1\">");

            if (count == 0)
                sb.Append("<div class=\"list-group-item text-center text-500 py-4\">No new notifications</div>");
            else
                foreach (System.Data.DataRow r in dt.Rows)
                {
                    bool isMsg = Convert.ToString(r["Kind"]) == "Message";
                    string url = isMsg ? ResolveUrl("~/Admin/Messages.aspx")
                                       : ResolveUrl("~/Orders/OrderDetail.aspx?id=" + r["RefID"]);
                    string icon = isMsg ? "fa-envelope text-primary" : "fa-receipt text-warning";
                    sb.Append("<div class=\"list-group-item").Append(isMsg ? " notif-msg" : "").Append("\"><a class=\"notification notification-flush notification-unread\" href=\"")
                      .Append(url).Append("\"><div class=\"notification-avatar\"><div class=\"avatar avatar-2xl me-3\">")
                      .Append("<div class=\"avatar-name rounded-circle\"><span class=\"fas ").Append(icon).Append("\"></span></div></div></div>")
                      .Append("<div class=\"notification-body\"><p class=\"mb-1\"><strong>")
                      .Append(HttpUtility.HtmlEncode(Convert.ToString(r["Title"]))).Append("</strong> ")
                      .Append(HttpUtility.HtmlEncode(Convert.ToString(r["Detail"]))).Append("</p>")
                      .Append("<span class=\"notification-time\">")
                      .Append(TimeAgo(Convert.ToDateTime(r["CreatedAt"]))).Append("</span></div></a></div>");
                }

            sb.Append("</div></div>");
            sb.Append("<div class=\"card-footer text-center border-top\"><a class=\"card-link d-block\" href=\"")
              .Append(ResolveUrl(canSeeMessages ? "~/Admin/Messages.aspx" : "~/Orders/OrderList.aspx"))
              .Append("\">View all</a></div></div></div></li>");
            return sb.ToString();
        }

        private static string TimeAgo(DateTime utc)
        {
            var span = DateTime.UtcNow - utc;
            if (span.TotalMinutes < 1)  return "Just now";
            if (span.TotalMinutes < 60) return (int)span.TotalMinutes + "m ago";
            if (span.TotalHours < 24)   return (int)span.TotalHours + "h ago";
            return (int)span.TotalDays + "d ago";
        }

        // The MSAjax/WebForms ScriptManager NuGet packages register their framework
        // script bundles ("MsAjaxBundle", "WebFormsBundle") so the ScriptManager renders
        // them with an app-RELATIVE <script src> (e.g. "Scripts/WebForms/MsAjax/...").
        // On a page in a subfolder like /Orders/ the browser resolves that to
        // "/Orders/Scripts/..." which 404s, so the Ajax framework fails to load
        // (Sys/Type undefined) and postback/validation features break. Pointing the
        // ScriptManager's own ResourceMapping at the physical files with a ROOT-relative
        // ("~/") path — set per request so it always wins over the package defaults —
        // makes the <script src> render correctly from any folder depth.
        // Bump when a script file is repaired/replaced so browsers fetch it instead of reusing a cached copy.
        private const string ScriptVersion = "?v=2";

        private void FixScriptManagerPaths()
        {
            var map = ScriptManager.ScriptResourceMapping;

            // Point the MsAjax/WebForms framework bundles at the physical script files
            // using an app-root-absolute path ("/<app>/Scripts/WebForms/...") so the
            // rendered <script src> resolves the same from any folder depth. The default
            // package registration rendered these folder-relative, which 404'd on pages
            // under subfolders like /Orders/ and left the Ajax framework unloaded.
            string root = ResolveUrl("~/").TrimEnd('/');

            void Map(string name, string localFile)
            {
                map.AddDefinition(name, new System.Web.UI.ScriptResourceDefinition
                {
                    Path = root + localFile + ScriptVersion,
                    DebugPath = root + localFile + ScriptVersion
                });
            }

            Map("MsAjaxBundle",   "/Scripts/WebForms/MsAjax/MicrosoftAjax.js");
            Map("WebFormsBundle", "/Scripts/WebForms/WebForms.js");

            // The Ajax framework scripts are registered per file name; version each one as well.
            foreach (var f in new[] { "MicrosoftAjax.js", "MicrosoftAjaxApplicationServices.js", "MicrosoftAjaxComponentModel.js",
                "MicrosoftAjaxCore.js", "MicrosoftAjaxGlobalization.js", "MicrosoftAjaxHistory.js", "MicrosoftAjaxNetwork.js",
                "MicrosoftAjaxSerialization.js", "MicrosoftAjaxTimer.js", "MicrosoftAjaxWebForms.js", "MicrosoftAjaxWebServices.js" })
                Map(f, "/Scripts/WebForms/MsAjax/" + f);

            // jQuery too (the default registration has no version, so a browser keeps the old file it cached).
            map.AddDefinition("jquery", new System.Web.UI.ScriptResourceDefinition
            {
                Path = root + "/Scripts/jquery-3.3.1.min.js" + ScriptVersion,
                DebugPath = root + "/Scripts/jquery-3.3.1.js" + ScriptVersion,
                LoadSuccessExpression = "window.jQuery"
            });
        }

        // ----------------------------------------------------------------
        // Dynamic navigation rendering
        // ----------------------------------------------------------------

        private void RenderNavMenu()
        {
            var role = HttpContext.Current.Session?["UserRole"]?.ToString() ?? "Guest";
            var service = new NavMenuService(new NavMenuRepository());
            // The menu only changes when rights are edited (clears the "auth" scope): cache it per role.
            var sections = OMS.Common.Helpers.AppCache.GetOrAdd<IList<NavMenuSection>>("auth", "nav|" + role, 60, () => service.GetNavSections(role));

            string verticalHtml = BuildNavHtml(sections);
            string topHtml      = BuildTopNavHtml(sections);

            litNavMenu.Text           = verticalHtml;
            litNavMenuDoubleTop.Text  = topHtml;
            litNavMenuStandard.Text   = topHtml;
            litNavMenuCombo.Text      = topHtml;
        }

        private string BuildNavHtml(IList<NavMenuSection> sections)
        {
            var currentPath = Request.AppRelativeCurrentExecutionFilePath?.ToLower() ?? string.Empty;
            var sb = new StringBuilder();

            foreach (var section in sections)
            {
                if (section.Groups.Count == 0) continue;

                bool isTopSection = section.SectionID == 0; // implicit top-level, no label

                if (isTopSection)
                {
                    // Each top-level group gets its own <li>
                    foreach (var group in section.Groups)
                        sb.Append(BuildGroupLi(group, null, currentPath));
                }
                else
                {
                    // All groups for this section share one <li> with the section label at top
                    sb.AppendLine("<li class=\"nav-item\">");
                    sb.AppendLine("  <div class=\"row navbar-vertical-label-wrapper mt-3 mb-2\">");
                    sb.AppendFormat("    <div class=\"col-auto navbar-vertical-label\">{0}</div>{1}",
                        HtmlEncode(section.SectionName), Environment.NewLine);
                    sb.AppendLine("    <div class=\"col ps-0\"><hr class=\"mb-0 navbar-vertical-divider\" /></div>");
                    sb.AppendLine("  </div>");

                    foreach (var group in section.Groups)
                        sb.Append(BuildGroupContent(group, currentPath));

                    sb.AppendLine("</li>");
                }
            }

            return sb.ToString();
        }

        // Renders a group as a standalone <li> (used for top-level groups with no section label)
        private string BuildGroupLi(NavMenuGroup group, string sectionName, string currentPath)
        {
            var sb = new StringBuilder();
            sb.AppendLine("<li class=\"nav-item\">");
            sb.Append(BuildGroupContent(group, currentPath));
            sb.AppendLine("</li>");
            return sb.ToString();
        }

        // Renders just the group content (anchor + optional sub-list), without the wrapping <li>
        private string BuildGroupContent(NavMenuGroup group, string currentPath)
        {
            var sb = new StringBuilder();

            if (group.IsDirectLink)
            {
                // Direct link — no children
                bool directActive = IsItemActive(group.Url, currentPath);
                sb.AppendFormat(
                    "<a class=\"nav-link{0}\" href=\"{1}\" role=\"button\">{2}</a>{3}",
                    directActive ? " active" : string.Empty,
                    ResolveUrl(group.Url),
                    BuildGroupInner(group),
                    Environment.NewLine);
            }
            else if (group.IsCollapsible)
            {
                bool expanded = IsGroupActive(group, currentPath);
                string showClass = expanded ? " show" : string.Empty;
                string ariaExpanded = expanded ? "true" : "false";

                sb.AppendFormat(
                    "<a class=\"nav-link dropdown-indicator{0}\" href=\"#{1}\" role=\"button\" " +
                    "data-bs-toggle=\"collapse\" aria-expanded=\"{2}\" aria-controls=\"{1}\">{3}</a>{4}",
                    expanded ? " active" : string.Empty,
                    HtmlEncode(group.CollapseId),
                    ariaExpanded,
                    BuildGroupInner(group),
                    Environment.NewLine);

                sb.AppendFormat("<ul class=\"nav collapse{0}\" id=\"{1}\">{2}",
                    showClass, HtmlEncode(group.CollapseId), Environment.NewLine);

                foreach (var item in group.Items)
                    sb.Append(BuildItemLi(item, currentPath));

                sb.AppendLine("</ul>");
            }

            return sb.ToString();
        }

        // Builds the inner <div> for a group anchor
        private static string BuildGroupInner(NavMenuGroup group)
        {
            return string.Format(
                "<div class=\"d-flex align-items-center\">" +
                "<span class=\"nav-link-text ps-1\">{0}</span>" +
                "</div>",
                HtmlEncode(group.GroupName));
        }

        // Renders a single nav sub-item <li>
        private string BuildItemLi(NavMenuItem item, string currentPath)
        {
            string itemUrl = ResolveUrl(item.Url);
            bool isActive = IsItemActive(item.Url, currentPath);

            string badge = string.IsNullOrEmpty(item.BadgeText)
                ? string.Empty
                : string.Format("<span class=\"badge rounded-pill ms-2 {0}\">{1}</span>",
                    HtmlEncode(item.BadgeClass), HtmlEncode(item.BadgeText));

            return string.Format(
                "<li class=\"nav-item\">" +
                "<a class=\"nav-link{0}\" href=\"{1}\">" +
                "<div class=\"d-flex align-items-center\">" +
                "<span class=\"nav-link-text ps-1\">{2}{3}</span>" +
                "</div></a></li>{4}",
                isActive ? " active" : string.Empty,
                itemUrl,
                HtmlEncode(item.ItemName),
                badge,
                Environment.NewLine);
        }

        // ----------------------------------------------------------------
        // Horizontal top-nav rendering (navbarDoubleTop / Standard / Combo)
        // ----------------------------------------------------------------

        private string BuildTopNavHtml(IList<NavMenuSection> sections)
        {
            var currentPath = Request.AppRelativeCurrentExecutionFilePath?.ToLower() ?? string.Empty;
            var sb = new StringBuilder();

            foreach (var section in sections)
            {
                foreach (var group in section.Groups)
                {
                    if (group.IsDirectLink)
                    {
                        // Plain nav link — no dropdown
                        bool active = IsItemActive(group.Url, currentPath);
                        sb.AppendFormat(
                            "<li class=\"nav-item\"><a class=\"nav-link{0}\" href=\"{1}\" role=\"button\">" +
                            "{2}</a></li>{3}",
                            active ? " active" : string.Empty,
                            ResolveUrl(group.Url),
                            HtmlEncode(group.GroupName),
                            Environment.NewLine);
                    }
                    else if (group.IsCollapsible)
                    {
                        bool expanded = IsGroupActive(group, currentPath);
                        sb.AppendFormat(
                            "<li class=\"nav-item dropdown\"><a class=\"nav-link dropdown-toggle{0}\" " +
                            "href=\"#\" role=\"button\" data-bs-toggle=\"dropdown\" aria-expanded=\"{1}\">" +
                            "{2}</a>{3}",
                            expanded ? " active" : string.Empty,
                            expanded ? "true" : "false",
                            HtmlEncode(group.GroupName),
                            Environment.NewLine);

                        sb.AppendLine("<ul class=\"dropdown-menu dropdown-menu-card dropdown-menu-end\">");
                        sb.AppendLine("  <div class=\"bg-white dark__bg-1000 rounded-3 py-2\">");

                        foreach (var item in group.Items)
                        {
                            bool itemActive = IsItemActive(item.Url, currentPath);
                            string badge = string.IsNullOrEmpty(item.BadgeText)
                                ? string.Empty
                                : string.Format(" <span class=\"badge rounded-pill ms-2 {0}\">{1}</span>",
                                    HtmlEncode(item.BadgeClass), HtmlEncode(item.BadgeText));

                            sb.AppendFormat(
                                "    <a class=\"dropdown-item{0}\" href=\"{1}\">{2}{3}</a>{4}",
                                itemActive ? " active" : string.Empty,
                                ResolveUrl(item.Url),
                                HtmlEncode(item.ItemName),
                                badge,
                                Environment.NewLine);
                        }

                        sb.AppendLine("  </div>");
                        sb.AppendLine("</ul></li>");
                    }
                }
            }

            return sb.ToString();
        }

        // ----------------------------------------------------------------
        // Active-state helpers
        // ----------------------------------------------------------------

        private bool IsGroupActive(NavMenuGroup group, string currentPath)
        {
            return group.Items.Any(i => IsItemActive(i.Url, currentPath));
        }

        private static bool IsItemActive(string itemUrl, string currentPath)
        {
            if (string.IsNullOrEmpty(itemUrl) || string.IsNullOrEmpty(currentPath))
                return false;

            // Normalise: strip leading ~/ and compare paths case-insensitively
            string normalised = itemUrl.TrimStart('~', '/').ToLower();
            return currentPath.TrimStart('~', '/').EndsWith(normalised,
                StringComparison.OrdinalIgnoreCase);
        }

        // ----------------------------------------------------------------
        // Utility
        // ----------------------------------------------------------------

        private static string HtmlEncode(string value)
            => string.IsNullOrEmpty(value) ? string.Empty : HttpUtility.HtmlEncode(value);
    }
}
