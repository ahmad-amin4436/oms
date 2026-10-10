using System;
using System.Data;
using System.Data.SqlClient;
using System.Web.UI.WebControls;
using OMS.Common.DAL;
using OMS.Common.Helpers;

namespace OMS.Admin
{
    public partial class Departments : System.Web.UI.Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {
            SecurityHelper.RequireRoles("Admin");
            if (!IsPostBack)
                BindGrid();
        }

        private DataTable LoadAll()
        {
            return DBHelper.ExecuteDataTable("sp_GetDepartments", DBHelper.Parameter("@ActiveOnly", false));
        }

        private void BindGrid()
        {
            gvDepartments.DataSource = LoadAll();
            gvDepartments.DataBind();
        }

        protected void gvDepartments_RowCommand(object sender, GridViewCommandEventArgs e)
        {
            SecurityHelper.RequireRoles("Admin");
            int id;
            if (!int.TryParse(Convert.ToString(e.CommandArgument), out id)) return;

            switch (e.CommandName)
            {
                case "EditDept":   OpenEditor(id); break;
                case "ToggleDept": Toggle(id);     break;
                case "DeleteDept": Delete(id);     break;
            }
        }

        private DataRow Find(int id)
        {
            foreach (DataRow r in LoadAll().Rows)
                if (Convert.ToInt32(r["DepartmentID"]) == id) return r;
            return null;
        }

        private void OpenEditor(int id)
        {
            var row = Find(id);
            if (row == null) { ShowErr("That department no longer exists."); BindGrid(); return; }

            hfDepartmentID.Value = id.ToString();
            litEditorTitle.Text  = "Edit Department";
            txtName.Text         = Convert.ToString(row["DepartmentName"]);
            txtDescription.Text  = Convert.ToString(row["Description"]);
            txtOrder.Text        = Convert.ToString(row["DisplayOrder"]);
            chkActive.Checked    = Convert.ToBoolean(row["IsActive"]);
            pnlEditor.Visible    = true;
            BindGrid();
        }

        private void Toggle(int id)
        {
            var row = Find(id);
            if (row == null) { ShowErr("That department no longer exists."); BindGrid(); return; }

            bool nowActive = !Convert.ToBoolean(row["IsActive"]);
            var idParam = DBHelper.OutputParameter("@DepartmentID", SqlDbType.Int);
            idParam.Value = id;
            DBHelper.ExecuteNonQuery("sp_SaveDepartment", idParam,
                DBHelper.Parameter("@Name",         Convert.ToString(row["DepartmentName"])),
                DBHelper.Parameter("@Description",  row["Description"] == DBNull.Value ? (object)DBNull.Value : Convert.ToString(row["Description"])),
                DBHelper.Parameter("@DisplayOrder", Convert.ToInt32(row["DisplayOrder"])),
                DBHelper.Parameter("@IsActive",     nowActive));

            ShowMsg(nowActive ? "Department activated." : "Department deactivated.");
            BindGrid();
        }

        private void Delete(int id)
        {
            try
            {
                DBHelper.ExecuteNonQuery("sp_DeleteDepartment", DBHelper.Parameter("@DepartmentID", id));
                ShowMsg("Department deleted.");
                pnlEditor.Visible = false;
            }
            catch (SqlException ex) { ShowErr(ex.Message); }
            BindGrid();
        }

        protected void btnAddNew_Click(object sender, EventArgs e)
        {
            SecurityHelper.RequireRoles("Admin");
            hfDepartmentID.Value = "0";
            litEditorTitle.Text  = "Add Department";
            txtName.Text = ""; txtDescription.Text = ""; txtOrder.Text = "0";
            chkActive.Checked = true;
            pnlEditor.Visible = true;
            BindGrid();
        }

        protected void btnSave_Click(object sender, EventArgs e)
        {
            SecurityHelper.RequireRoles("Admin");
            if (!Page.IsValid) { pnlEditor.Visible = true; BindGrid(); return; }

            int id = 0; int.TryParse(hfDepartmentID.Value, out id);
            int order = 0; int.TryParse(txtOrder.Text.Trim(), out order);

            try
            {
                var idParam = DBHelper.OutputParameter("@DepartmentID", SqlDbType.Int);
                idParam.Value = id;
                DBHelper.ExecuteNonQuery("sp_SaveDepartment", idParam,
                    DBHelper.Parameter("@Name",         txtName.Text.Trim()),
                    DBHelper.Parameter("@Description",  txtDescription.Text.Trim()),
                    DBHelper.Parameter("@DisplayOrder", order),
                    DBHelper.Parameter("@IsActive",     chkActive.Checked),
                    DBHelper.Parameter("@CreatedBy",    SecurityHelper.UserID == 0 ? (object)DBNull.Value : SecurityHelper.UserID));

                ShowMsg(id == 0 ? "Department created." : "Department updated.");
                pnlEditor.Visible = false;
            }
            catch (SqlException ex)
            {
                ShowErr(ex.Message);
                pnlEditor.Visible = true;
            }
            BindGrid();
        }

        protected void btnCancel_Click(object sender, EventArgs e)
        {
            pnlEditor.Visible = false;
            BindGrid();
        }

        private void ShowMsg(string text) { lblMsg.Text = text; lblMsg.Visible = true; lblErr.Visible = false; }
        private void ShowErr(string text) { lblErr.Text = text; lblErr.Visible = true; lblMsg.Visible = false; }
    }
}

