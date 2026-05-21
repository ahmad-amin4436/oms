using System;
using OMS.App_Code.DAL;
using OMS.App_Code.Helpers;

namespace OMS.Offers
{
    public partial class OfferList : System.Web.UI.Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {
            SecurityHelper.RequireRoles("Admin", "Manager");
            if (!IsPostBack)
            {
                gvOffers.DataSource = DBHelper.ExecuteDataTable("sp_GetOffers", DBHelper.Parameter("@IsActive", DBNull.Value));
                gvOffers.DataBind();
            }
        }
    }
}
