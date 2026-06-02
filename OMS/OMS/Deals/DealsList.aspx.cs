using System;
using System.Web.UI.WebControls;
using OMS.Common.DAL;
using OMS.Common.Helpers;

namespace OMS.Deals
{
    public partial class DealsList : System.Web.UI.Page
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
                BindDeals();
        }

        private void BindDeals()
        {
            var param = FilterActive.HasValue
                ? DBHelper.Parameter("@IsActive", FilterActive.Value)
                : DBHelper.Parameter("@IsActive", DBNull.Value);

            gvDeals.DataSource = DBHelper.ExecuteDataTable("sp_GetDeals", param);
            gvDeals.DataBind();
        }

        protected void lbAll_Click(object sender, EventArgs e)      { SetFilter(null); }
        protected void lbActive_Click(object sender, EventArgs e)   { SetFilter(true); }
        protected void lbInactive_Click(object sender, EventArgs e) { SetFilter(false); }

        private void SetFilter(bool? active)
        {
            FilterActive = active;
            lbAll.CssClass      = "btn btn-sm " + (active == null  ? "btn-primary" : "btn-falcon-default");
            lbActive.CssClass   = "btn btn-sm " + (active == true  ? "btn-primary" : "btn-falcon-default");
            lbInactive.CssClass = "btn btn-sm " + (active == false ? "btn-primary" : "btn-falcon-default");
            BindDeals();
        }

        protected void gvDeals_RowCommand(object sender, GridViewCommandEventArgs e)
        {
            int dealId;
            if (!int.TryParse(Convert.ToString(e.CommandArgument), out dealId)) return;

            if (e.CommandName == "Toggle")
            {
                var result = DBHelper.ExecuteDataTable("sp_ToggleDealStatus",
                    DBHelper.Parameter("@DealID", dealId));
                bool nowActive = result.Rows.Count > 0 && Convert.ToBoolean(result.Rows[0][0]);
                ShowMsg(nowActive ? "Deal activated." : "Deal deactivated.");
                BindDeals();
            }
            else if (e.CommandName == "DeleteDeal")
            {
                DBHelper.ExecuteNonQuery("sp_DeleteDeal", DBHelper.Parameter("@DealID", dealId));
                ShowMsg("Deal deleted.");
                BindDeals();
            }
        }

        // Percentage -> "20%", Flat -> "Rs. 200", BundlePrice -> "Rs. 999"
        protected string FormatDealValue(string type, decimal value, object dealPrice)
        {
            if (type == "Percentage") return value.ToString("N0") + "%";
            if (type == "BundlePrice")
                return dealPrice == null || dealPrice == DBNull.Value
                    ? "—"
                    : "Rs. " + Convert.ToDecimal(dealPrice).ToString("N0");
            return "Rs. " + value.ToString("N0");
        }

        private void ShowMsg(string text)
        {
            lblMsg.Text = text;
            lblMsg.Visible = true;
            lblErr.Visible = false;
        }
    }
}
