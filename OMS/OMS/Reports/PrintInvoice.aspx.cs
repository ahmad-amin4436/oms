using System;
using OMS.App_Code.DAL;
using OMS.App_Code.Helpers;

namespace OMS.Reports
{
    public partial class PrintInvoice : System.Web.UI.Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {
            SecurityHelper.RequireRoles("Admin", "Manager", "Cashier");
            if (!IsPostBack)
            {
                int id;
                if (!int.TryParse(Request.QueryString["id"], out id)) return;
                var ds = DBHelper.ExecuteDataSet("sp_GetOrderByID", DBHelper.Parameter("@OrderID", id));
                if (ds.Tables.Count > 0 && ds.Tables[0].Rows.Count > 0) lblOrderNumber.Text = Convert.ToString(ds.Tables[0].Rows[0]["OrderNumber"]);
                gvInvoiceItems.DataSource = ds.Tables.Count > 1 ? ds.Tables[1] : null;
                gvInvoiceItems.DataBind();
            }
        }
    }
}
