using System;
using System.Data;
using System.Data.SqlClient;
using System.Web;
using System.Web.UI.WebControls;
using OMS.Common.DAL;
using OMS.Common.Helpers;
using System.Web.UI;

namespace OMS.Admin
{
    public partial class PrinterConfiguration : System.Web.UI.Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {
            SecurityHelper.RequireUrlAccess();
            SecurityHelper.RequirePermission("Administration.PrinterConfiguration.View");
            if (!IsPostBack)
                BindGrid();
        }

        private void BindGrid()
        {
            DataTable printers = DBHelper.ExecuteDataTable("sp_GetDepartmentPrinterConfigurations");
            if (!printers.Columns.Contains("PrinterName"))
                printers.Columns.Add("PrinterName", typeof(string));

            gvPrinters.DataSource = printers;
            gvPrinters.DataBind();
        }

        protected void gvPrinters_RowCommand(object sender, GridViewCommandEventArgs e)
        {
            SecurityHelper.RequireUrlAccess();
            SecurityHelper.RequirePermission("Administration.PrinterConfiguration.Edit");

            if (!string.Equals(e.CommandName, "SavePrinter", StringComparison.OrdinalIgnoreCase))
                return;

            int departmentId;
            if (!int.TryParse(Convert.ToString(e.CommandArgument), out departmentId))
                return;

            var row = (GridViewRow)((Control)e.CommandSource).NamingContainer;
            var txtIp = (TextBox)row.FindControl("txtPrinterIP");
            var txtName = (TextBox)row.FindControl("txtPrinterName");
            var txtPort = (TextBox)row.FindControl("txtPrinterPort");
            var chkEnabled = (CheckBox)row.FindControl("chkPrinterEnabled");

            int port;
            object portValue = DBNull.Value;
            if (!string.IsNullOrWhiteSpace(txtPort.Text))
            {
                if (!int.TryParse(txtPort.Text.Trim(), out port) || port < 1 || port > 65535)
                {
                    ShowErr("Printer port must be between 1 and 65535.");
                    return;
                }
                portValue = port;
            }

            string ip = (txtIp.Text ?? string.Empty).Trim();
            string printerName = (txtName.Text ?? string.Empty).Trim();
            if (chkEnabled.Checked && ip.Length == 0 && printerName.Length == 0)
            {
                ShowErr("Enter a LAN printer IP/host or a Windows printer queue name before enabling the printer.");
                return;
            }

            try
            {
                DBHelper.ExecuteNonQuery("sp_SaveDepartmentPrinterConfiguration",
                    DBHelper.Parameter("@DepartmentID", departmentId),
                    DBHelper.Parameter("@PrinterIP", string.IsNullOrEmpty(ip) ? (object)DBNull.Value : ip),
                    DBHelper.Parameter("@PrinterName", string.IsNullOrEmpty(printerName) ? (object)DBNull.Value : printerName),
                    DBHelper.Parameter("@PrinterPort", portValue),
                    DBHelper.Parameter("@PrinterEnabled", chkEnabled.Checked));

                ShowMsg("Printer configuration saved.");
                BindGrid();
            }
            catch (SqlException ex)
            {
                ShowErr(ex.Message);
            }
        }

        private void ShowMsg(string text)
        {
            lblMsg.Text = HttpUtility.HtmlEncode(text);
            lblMsg.Visible = true;
            lblErr.Visible = false;
        }

        private void ShowErr(string text)
        {
            lblErr.Text = HttpUtility.HtmlEncode(text);
            lblErr.Visible = true;
            lblMsg.Visible = false;
        }
    }
}
