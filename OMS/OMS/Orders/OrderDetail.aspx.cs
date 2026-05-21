using System;
using OMS.App_Code.DAL;
using OMS.App_Code.Helpers;

namespace OMS.Orders
{
    public partial class OrderDetail : System.Web.UI.Page
    {
        private int OrderID { get { int id; return int.TryParse(Request.QueryString["id"], out id) ? id : 0; } }

        protected void Page_Load(object sender, EventArgs e)
        {
            SecurityHelper.RequireLogin();
            if (!IsPostBack)
            {
                foreach (var status in new[] { "Pending", "Confirmed", "Preparing", "Ready", "Delivered", "Cancelled" }) ddlStatus.Items.Add(status);
                BindOrder();
            }
        }

        protected void btnUpdateStatus_Click(object sender, EventArgs e)
        {
            DBHelper.ExecuteNonQuery("sp_UpdateOrderStatus", DBHelper.Parameter("@OrderID", OrderID), DBHelper.Parameter("@Status", ddlStatus.SelectedValue), DBHelper.Parameter("@UpdatedBy", SecurityHelper.UserID));
            BindOrder();
        }

        private void BindOrder()
        {
            var ds = DBHelper.ExecuteDataSet("sp_GetOrderByID", DBHelper.Parameter("@OrderID", OrderID));
            if (ds.Tables.Count == 0 || ds.Tables[0].Rows.Count == 0) return;
            lblOrderNumber.Text = Convert.ToString(ds.Tables[0].Rows[0]["OrderNumber"]);
            ddlStatus.SelectedValue = Convert.ToString(ds.Tables[0].Rows[0]["Status"]);
            gvItems.DataSource = ds.Tables.Count > 1 ? ds.Tables[1] : null;
            gvItems.DataBind();
        }
    }
}
