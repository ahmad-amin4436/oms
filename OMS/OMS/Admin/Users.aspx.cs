using System;
using System.Data;
using System.Data.SqlClient;
using System.Web.UI.WebControls;
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

        // ── Binding ──────────────────────────────────────────────────

        private void BindUsers()
        {
            gvUsers.DataSource = DBHelper.ExecuteDataTable("sp_GetAllUsers");
            gvUsers.DataBind();
        }

        private void BindRoleDropdown()
        {
            var dt = DBHelper.ExecuteDataTable("sp_GetRoles");
            ddlRole.DataSource     = dt;
            ddlRole.DataTextField  = "RoleName";
            ddlRole.DataValueField = "RoleID";
            ddlRole.DataBind();
            ddlRole.Items.Insert(0, new ListItem("- Select role -", ""));
        }

        // ── Grid row actions ─────────────────────────────────────────

        protected void gvUsers_RowCommand(object sender, GridViewCommandEventArgs e)
        {
            switch (e.CommandName)
            {
                case "Toggle":
                    ToggleStatus(Convert.ToInt32(e.CommandArgument));
                    break;
                case "EditUser":
                    OpenEditorForEdit(Convert.ToInt32(e.CommandArgument));
                    break;
                case "DeleteUser":
                    DeleteUser(Convert.ToInt32(e.CommandArgument));
                    break;
            }
        }

        private void ToggleStatus(int userId)
        {
            var result = DBHelper.ExecuteDataTable("sp_ToggleUserStatus",
                DBHelper.Parameter("@UserID", userId));

            bool nowActive = result.Rows.Count > 0 && Convert.ToBoolean(result.Rows[0][0]);
            ShowMsg(nowActive ? "User activated." : "User deactivated.");
            BindUsers();
        }

        private void DeleteUser(int userId)
        {
            // An admin shouldn't be able to delete their own logged-in account.
            if (userId == SecurityHelper.UserID)
            {
                ShowErr("You cannot delete the account you are currently signed in with.");
                BindUsers();
                return;
            }

            try
            {
                // sp_DeleteUser raises an error if the user has order history.
                DBHelper.ExecuteNonQuery("sp_DeleteUser", DBHelper.Parameter("@UserID", userId));
                ShowMsg("User deleted.");
                HideEditor();
                BindUsers();
            }
            catch (SqlException ex)
            {
                ShowErr(ex.Message);
                BindUsers();
            }
        }

        // ── Add / Edit editor ────────────────────────────────────────

        protected void btnAddNew_Click(object sender, EventArgs e)
        {
            BindRoleDropdown();
            hfUserID.Value      = "0";
            litEditorTitle.Text = "Add New User";
            litPwdHint.Text     = "";

            txtFullName.Text = "";
            txtEmail.Text    = "";
            txtPassword.Text = "";
            ddlRole.SelectedIndex = 0;
            chkActive.Checked = true;

            // New user must supply a password.
            rfvPassword.Enabled = true;

            pnlEditor.Visible = true;
        }

        private void OpenEditorForEdit(int userId)
        {
            var dt = DBHelper.ExecuteDataTable("sp_GetUserByID",
                DBHelper.Parameter("@UserID", userId));
            if (dt.Rows.Count == 0)
            {
                ShowErr("That user no longer exists.");
                BindUsers();
                return;
            }

            BindRoleDropdown();
            var row = dt.Rows[0];

            hfUserID.Value      = userId.ToString();
            litEditorTitle.Text = "Edit User";
            litPwdHint.Text     = "<span class=\"text-600 fs--2 fw-normal ms-1\">(leave blank to keep current)</span>";
            txtFullName.Text    = Convert.ToString(row["FullName"]);
            txtEmail.Text       = Convert.ToString(row["Email"]);
            txtPassword.Text    = "";
            chkActive.Checked   = Convert.ToBoolean(row["IsActive"]);

            var roleItem = ddlRole.Items.FindByValue(Convert.ToString(row["RoleID"]));
            if (roleItem != null) { ddlRole.ClearSelection(); roleItem.Selected = true; }

            // Editing: password optional (blank = keep existing).
            rfvPassword.Enabled = false;

            pnlEditor.Visible = true;
        }

        protected void btnSave_Click(object sender, EventArgs e)
        {
            if (!Page.IsValid) { pnlEditor.Visible = true; return; }

            int userId = 0;
            int.TryParse(hfUserID.Value, out userId);

            int roleId;
            if (!int.TryParse(ddlRole.SelectedValue, out roleId))
            {
                ShowErr("Please select a valid role.");
                pnlEditor.Visible = true;
                return;
            }

            string password = txtPassword.Text;
            // New user requires a password; existing user keeps current if left blank.
            if (userId == 0 && string.IsNullOrWhiteSpace(password))
            {
                ShowErr("A password is required for a new user.");
                pnlEditor.Visible = true;
                return;
            }

            object passwordHash = string.IsNullOrWhiteSpace(password)
                ? (object)DBNull.Value
                : PasswordHelper.HashPassword(password);

            try
            {
                var idParam = DBHelper.OutputParameter("@UserID", SqlDbType.Int);
                idParam.Value = userId;

                DBHelper.ExecuteNonQuery("sp_SaveUser",
                    idParam,
                    DBHelper.Parameter("@FullName",     txtFullName.Text.Trim()),
                    DBHelper.Parameter("@Email",        txtEmail.Text.Trim()),
                    DBHelper.Parameter("@PasswordHash", passwordHash),
                    DBHelper.Parameter("@RoleID",       roleId),
                    DBHelper.Parameter("@IsActive",     chkActive.Checked));

                ShowMsg(userId == 0 ? "New user created." : "User updated.");
                HideEditor();
                BindUsers();
            }
            catch (SqlException ex)
            {
                // sp_SaveUser raises a friendly error on duplicate email.
                ShowErr(ex.Message);
                pnlEditor.Visible = true;
            }
        }

        protected void lbCancel_Click(object sender, EventArgs e)
        {
            HideEditor();
        }

        // ── Helpers ──────────────────────────────────────────────────

        private void HideEditor()
        {
            pnlEditor.Visible = false;
        }

        private void ShowMsg(string text)
        {
            lblMsg.Text    = text;
            lblMsg.Visible = true;
            lblErr.Visible = false;
        }

        private void ShowErr(string text)
        {
            lblErr.Text    = text;
            lblErr.Visible = true;
            lblMsg.Visible = false;
        }
    }
}
