using System;
using OMS.App_Code.DAL;
using OMS.App_Code.Helpers;

namespace OMS.Offers
{
    public partial class ManageCoupons : System.Web.UI.Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {
            SecurityHelper.RequireRoles("Admin", "Manager");
            if (!IsPostBack)
            {
                gvCoupons.DataSource = DBHelper.ExecuteDataTable("sp_GetCoupons");
                gvCoupons.DataBind();
            }
        }
    }
}
