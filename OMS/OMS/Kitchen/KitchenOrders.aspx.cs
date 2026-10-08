using System;
using OMS.Common.Helpers;

namespace OMS.Kitchen
{
    /// <summary>Kitchen screen: dishes being prepared, filter by category, Done button, live updates.</summary>
    public partial class KitchenOrders : System.Web.UI.Page
    {
        protected string FeedUrl;

        protected void Page_Load(object sender, EventArgs e)
        {
            SecurityHelper.RequireUrlAccess();      // same nav rights as the menu entry
            FeedUrl = ResolveUrl("~/Kitchen/KitchenFeed.ashx");
        }
    }
}