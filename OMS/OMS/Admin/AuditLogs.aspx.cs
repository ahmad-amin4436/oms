using System;
using System.Data;
using OMS.Common.DAL;
using OMS.Common.Helpers;
using System.Web.UI.WebControls;

namespace OMS.Admin
{
    public partial class AuditLogs : System.Web.UI.Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {
            SecurityHelper.RequireUrlAccess();
            SecurityHelper.RequirePermission("Administration.AuditLogs.View");
            if (!IsPostBack)
            {
                BindFilters();
                BindLogs(null);
            }
        }

        private void BindFilters()
        {
            BindDropDown(ddlUser, DBHelper.ExecuteDataTable("sp_GetAllUsers"), "FullName", "UserID", "All users");
            BindDropDown(ddlRole, DBHelper.ExecuteDataTable("sp_GetRoles"), "RoleName", "RoleName", "All roles");
            BindDropDown(ddlModule, DBHelper.ExecuteDataTable("sp_GetAuditModules"), "ModuleName", "ModuleKey", "All modules");
            BindDropDown(ddlAction, DBHelper.ExecuteDataTable("sp_GetAuditActions"), "ActionName", "ActionKey", "All actions");
        }

        private static void BindDropDown(DropDownList list, DataTable data, string text, string value, string first)
        {
            list.DataSource = data;
            list.DataTextField = text;
            list.DataValueField = value;
            list.DataBind();
            list.Items.Insert(0, new ListItem(first, ""));
        }

        protected void btnApply_Click(object sender, EventArgs e)
        {
            BindLogs(null);
        }

        protected void ActivityFilter_Click(object sender, EventArgs e)
        {
            var link = (LinkButton)sender;
            BindLogs(Convert.ToString(link.CommandArgument));
        }

        protected void Clear_Click(object sender, EventArgs e)
        {
            ddlUser.SelectedIndex = ddlRole.SelectedIndex = ddlModule.SelectedIndex = ddlAction.SelectedIndex = 0;
            txtStartDate.Text = txtEndDate.Text = txtOrderID.Text = "";
            BindLogs(null);
        }

        private void BindLogs(string actionOverride)
        {
            int orderId;
            DateTime startDate, endDate;
            object userId = string.IsNullOrEmpty(ddlUser.SelectedValue) ? (object)DBNull.Value : Convert.ToInt32(ddlUser.SelectedValue);
            object order = int.TryParse(txtOrderID.Text, out orderId) ? (object)orderId : DBNull.Value;
            object start = DateTime.TryParse(txtStartDate.Text, out startDate) ? (object)startDate.Date : DBNull.Value;
            object end = DateTime.TryParse(txtEndDate.Text, out endDate) ? (object)endDate.Date : DBNull.Value;

            gvAudit.DataSource = DBHelper.ExecuteDataTable("sp_GetAuditLogs",
                DBHelper.Parameter("@UserID", userId),
                DBHelper.Parameter("@RoleName", string.IsNullOrEmpty(ddlRole.SelectedValue) ? (object)DBNull.Value : ddlRole.SelectedValue),
                DBHelper.Parameter("@Action", actionOverride ?? (string.IsNullOrEmpty(ddlAction.SelectedValue) ? (object)DBNull.Value : ddlAction.SelectedValue)),
                DBHelper.Parameter("@Module", string.IsNullOrEmpty(ddlModule.SelectedValue) ? (object)DBNull.Value : ddlModule.SelectedValue),
                DBHelper.Parameter("@StartDate", start),
                DBHelper.Parameter("@EndDate", end),
                DBHelper.Parameter("@OrderID", order));
            gvAudit.DataBind();
        }
    }
}
