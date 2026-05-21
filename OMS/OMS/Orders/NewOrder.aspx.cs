using System;
using System.Data.SqlClient;
using OMS.App_Code.DAL;
using OMS.App_Code.Helpers;

namespace OMS.Orders
{
    public partial class NewOrder : System.Web.UI.Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {
            SecurityHelper.RequireRoles("Admin", "Manager", "Cashier");
            if (!IsPostBack) BindMenu();
        }

        protected void btnPlaceOrder_Click(object sender, EventArgs e)
        {
            decimal subtotal;
            decimal.TryParse(txtSubTotal.Text, out subtotal);
            var tax = Math.Round(subtotal * 0.16m, 2);
            var output = DBHelper.OutputParameter("@OrderID", System.Data.SqlDbType.Int);
            DBHelper.ExecuteNonQuery("sp_CreateOrder",
                DBHelper.Parameter("@CustomerName", txtCustomerName.Text.Trim()),
                DBHelper.Parameter("@Phone", txtPhone.Text.Trim()),
                DBHelper.Parameter("@Address", txtAddress.Text.Trim()),
                DBHelper.Parameter("@TableNumber", DBNull.Value),
                DBHelper.Parameter("@OrderType", ddlOrderType.SelectedValue),
                DBHelper.Parameter("@PaymentMethod", ddlPaymentMethod.SelectedValue),
                DBHelper.Parameter("@PaymentStatus", "Pending"),
                DBHelper.Parameter("@SubTotal", subtotal),
                DBHelper.Parameter("@DiscountAmount", 0),
                DBHelper.Parameter("@TaxAmount", tax),
                DBHelper.Parameter("@TotalAmount", subtotal + tax),
                DBHelper.Parameter("@CouponID", DBNull.Value),
                DBHelper.Parameter("@Notes", DBNull.Value),
                DBHelper.Parameter("@CreatedBy", SecurityHelper.UserID == 0 ? (object)DBNull.Value : SecurityHelper.UserID),
                output);
            Response.Redirect("OrderDetail.aspx?id=" + output.Value, false);
            Context.ApplicationInstance.CompleteRequest();
        }

        private void BindMenu()
        {
            rptMenu.DataSource = DBHelper.ExecuteDataTable("sp_GetMenuItems", DBHelper.Parameter("@CategoryID", DBNull.Value), DBHelper.Parameter("@IsAvailable", true));
            rptMenu.DataBind();
        }
    }
}
