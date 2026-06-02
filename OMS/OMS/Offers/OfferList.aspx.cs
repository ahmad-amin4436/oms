using System;
using OMS.Common.DAL;
using OMS.Common.Helpers;

namespace OMS.Offers
{
    public partial class OfferList : System.Web.UI.Page
    {
        private bool? FilterActive
        {
            get { return ViewState["FilterActive"] as bool?; }
            set { ViewState["FilterActive"] = value; }
        }

        protected void Page_Load(object sender, EventArgs e)
        {
            SecurityHelper.RequireUrlAccess();
            if (!IsPostBack)
                BindOffers();
        }

        private void BindOffers()
        {
            var param = FilterActive.HasValue
                ? DBHelper.Parameter("@IsActive", FilterActive.Value)
                : DBHelper.Parameter("@IsActive", DBNull.Value);

            gvOffers.DataSource = DBHelper.ExecuteDataTable("sp_GetOffers", param);
            gvOffers.DataBind();
        }

        protected void lbAll_Click(object sender, EventArgs e)
        {
            FilterActive = null;
            lbAll.CssClass     = "btn btn-sm btn-primary";
            lbActive.CssClass  = "btn btn-sm btn-falcon-default";
            lbInactive.CssClass = "btn btn-sm btn-falcon-default";
            BindOffers();
        }

        protected void lbActive_Click(object sender, EventArgs e)
        {
            FilterActive = true;
            lbAll.CssClass     = "btn btn-sm btn-falcon-default";
            lbActive.CssClass  = "btn btn-sm btn-primary";
            lbInactive.CssClass = "btn btn-sm btn-falcon-default";
            BindOffers();
        }

        protected void lbInactive_Click(object sender, EventArgs e)
        {
            FilterActive = false;
            lbAll.CssClass     = "btn btn-sm btn-falcon-default";
            lbActive.CssClass  = "btn btn-sm btn-falcon-default";
            lbInactive.CssClass = "btn btn-sm btn-primary";
            BindOffers();
        }

        protected void gvOffers_RowCommand(object sender, System.Web.UI.WebControls.GridViewCommandEventArgs e)
        {
            if (e.CommandName != "Toggle") return;

            int offerId = Convert.ToInt32(e.CommandArgument);
            var result  = DBHelper.ExecuteDataTable("sp_ToggleOfferStatus",
                DBHelper.Parameter("@OfferID", offerId));

            bool nowActive = result.Rows.Count > 0 && Convert.ToBoolean(result.Rows[0][0]);
            lblMsg.Text    = nowActive ? "Offer activated." : "Offer deactivated.";
            lblMsg.Visible = true;
            BindOffers();
        }

        protected string FormatDiscount(string type, decimal value)
        {
            return type == "Percentage"
                ? value.ToString("N0") + "%"
                : "Rs. " + value.ToString("N0");
        }
    }
}
