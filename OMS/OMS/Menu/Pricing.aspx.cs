using System;
using OMS.Common.DAL;
using OMS.Common.Helpers;

namespace OMS.Menu
{
    public partial class Pricing : System.Web.UI.Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {
            SecurityHelper.RequireUrlAccess();
            if (!IsPostBack)
            {
                gvPricing.DataSource = DBHelper.ExecuteDataTable("sp_GetSizePricingMatrix");
                gvPricing.DataBind();
            }
        }
    }
}
