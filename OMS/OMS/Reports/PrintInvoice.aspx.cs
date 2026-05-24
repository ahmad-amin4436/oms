using System;
using System.Data;
using OMS.Common.DAL;
using OMS.Common.Helpers;

namespace OMS.Reports
{
    public partial class PrintInvoice : System.Web.UI.Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {
            SecurityHelper.RequireRoles("Admin", "Manager", "Cashier");
            if (!IsPostBack)
                BindInvoice();
        }

        private void BindInvoice()
        {
            int orderId;
            if (!int.TryParse(Request.QueryString["id"], out orderId)) return;

            var ds = DBHelper.ExecuteDataSet("sp_GetOrderByID",
                DBHelper.Parameter("@OrderID", orderId));

            if (ds.Tables.Count == 0 || ds.Tables[0].Rows.Count == 0) return;

            DataRow row = ds.Tables[0].Rows[0];

            lblOrderNumber.Text = Convert.ToString(row["OrderNumber"]);
            lblOrderDate.Text   = Convert.ToDateTime(row["CreatedAt"]).ToString("dd MMM yyyy, hh:mm tt");

            string customer = Convert.ToString(row["CustomerName"]);
            lblCustomer.Text  = string.IsNullOrEmpty(customer) ? "Walk-in" : customer;
            lblPhone.Text     = string.IsNullOrEmpty(Convert.ToString(row["CustomerPhone"])) ? "—" : Convert.ToString(row["CustomerPhone"]);
            lblOrderType.Text = Convert.ToString(row["OrderType"]);

            if (Convert.ToString(row["OrderType"]) == "DineIn" && !string.IsNullOrEmpty(Convert.ToString(row["TableNumber"])))
            {
                pnlTable.Visible = true;
                lblTable.Text    = Convert.ToString(row["TableNumber"]);
            }

            decimal subtotal = Convert.ToDecimal(row["SubTotal"]);
            decimal discount = Convert.ToDecimal(row["DiscountAmount"]);
            decimal tax      = Convert.ToDecimal(row["TaxAmount"]);
            decimal total    = Convert.ToDecimal(row["TotalAmount"]);

            lblSubtotal.Text = Fmt(subtotal);
            lblDiscount.Text = discount > 0 ? "- " + Fmt(discount) : Fmt(0m);
            lblTax.Text      = Fmt(tax);
            lblTotal.Text    = Fmt(total);

            gvInvoiceItems.DataSource = ds.Tables.Count > 1 ? (object)ds.Tables[1] : null;
            gvInvoiceItems.DataBind();
        }

        private static string Fmt(decimal v) => "Rs. " + v.ToString("N0");
    }
}
