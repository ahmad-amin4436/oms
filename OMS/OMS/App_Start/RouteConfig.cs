using System;
using System.Collections.Generic;
using System.Web;
using System.Web.Routing;
using Microsoft.AspNet.FriendlyUrls;

namespace OMS
{
    public static class RouteConfig
    {
        public static void RegisterRoutes(RouteCollection routes)
        {
            var settings = new FriendlyUrlSettings();
            // Off (not Permanent): do NOT 301-redirect *.aspx to extensionless URLs.
            // With Permanent, pages were served at "/Orders/NewOrder" and the Web Forms
            // <form> posted back to that relative, extensionless URL — which breaks
            // __doPostBack event routing, so LinkButton/Repeater ItemCommand clicks and
            // AutoPostBack never fired. Turning auto-redirect off keeps real .aspx URLs,
            // so postbacks resolve to the page and all server events fire normally.
            settings.AutoRedirectMode = RedirectMode.Off;
            routes.EnableFriendlyUrls(settings);
        }
    }
}
