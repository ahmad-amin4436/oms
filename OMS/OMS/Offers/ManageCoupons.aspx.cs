using System;
using OMS.Common.DAL;
using OMS.Common.Helpers;

namespace OMS.Offers
{
    public partial class ManageCoupons : System.Web.UI.Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {
            SecurityHelper.RequireRoles("Admin", "Manager");
            if (!IsPostBack)
                BindCoupons();
        }

        private void BindCoupons()
        {
            gvCoupons.DataSource = DBHelper.ExecuteDataTable("sp_GetCoupons");
            gvCoupons.DataBind();
        }

        protected void gvCoupons_RowCommand(object sender, System.Web.UI.WebControls.GridViewCommandEventArgs e)
        {
            if (e.CommandName != "Toggle") return;

            int couponId = Convert.ToInt32(e.CommandArgument);
            var result   = DBHelper.ExecuteDataTable("sp_ToggleCouponStatus",
                DBHelper.Parameter("@CouponID", couponId));

            bool nowActive = result.Rows.Count > 0 && Convert.ToBoolean(result.Rows[0][0]);
            lblMsg.Text    = nowActive ? "Coupon enabled." : "Coupon disabled.";
            lblMsg.Visible = true;
            BindCoupons();
        }

        protected string FormatDiscount(string type, decimal value)
        {
            return type == "Percentage"
                ? value.ToString("N0") + "%"
                : "Rs. " + value.ToString("N0");
        }
    }
}
