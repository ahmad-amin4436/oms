using System;
using OMS.Common.DAL;
using OMS.Common.Helpers;

namespace OMS.Admin
{
    public partial class Users : System.Web.UI.Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {
            SecurityHelper.RequireRoles("Admin");
            if (!IsPostBack)
                BindUsers();
        }

        private void BindUsers()
        {
            gvUsers.DataSource = DBHelper.ExecuteDataTable("sp_GetAllUsers");
            gvUsers.DataBind();
        }

        protected void gvUsers_RowCommand(object sender, System.Web.UI.WebControls.GridViewCommandEventArgs e)
        {
            if (e.CommandName != "Toggle") return;

            int userId = Convert.ToInt32(e.CommandArgument);
            var result = DBHelper.ExecuteDataTable("sp_ToggleUserStatus",
                DBHelper.Parameter("@UserID", userId));

            bool nowActive = result.Rows.Count > 0 && Convert.ToBoolean(result.Rows[0][0]);
            lblMsg.Text    = nowActive ? "User activated." : "User deactivated.";
            lblMsg.Visible = true;

            BindUsers();
        }
    }
}
