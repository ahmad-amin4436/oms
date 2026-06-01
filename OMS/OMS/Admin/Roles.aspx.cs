using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.Linq;
using System.Web.UI;
using System.Web.UI.HtmlControls;
using System.Web.UI.WebControls;
using OMS.Common.DAL;
using OMS.Common.Helpers;

namespace OMS.Admin
{
    public partial class Roles : System.Web.UI.Page
    {
        // RoleName whose rights are currently shown in the matrix.
        private string SelectedRoleName
        {
            get { return ViewState["RightsRole"] as string; }
            set { ViewState["RightsRole"] = value; }
        }

        protected void Page_Load(object sender, EventArgs e)
        {
            SecurityHelper.RequireRoles("Admin");
            if (!IsPostBack)
            {
                BindRolesGrid();
                BindRightsRoleDropdown();
            }
        }

        // ══════════════════════════════════════════════════════════════
        //  ROLES CRUD
        // ══════════════════════════════════════════════════════════════

        private void BindRolesGrid()
        {
            gvRoles.DataSource = DBHelper.ExecuteDataTable("sp_GetRoles");
            gvRoles.DataBind();
        }

        protected void btnAddRole_Click(object sender, EventArgs e)
        {
            hfRoleID.Value   = "0";
            txtRoleName.Text = "";
            pnlRoleEditor.Visible = true;
        }

        protected void gvRoles_RowCommand(object sender, GridViewCommandEventArgs e)
        {
            int roleId = Convert.ToInt32(e.CommandArgument);

            switch (e.CommandName)
            {
                case "EditRole":
                    OpenRoleEditor(roleId);
                    break;
                case "DeleteRole":
                    DeleteRole(roleId);
                    break;
                case "RightsRole":
                    // Jump straight to the rights matrix for this role.
                    var item = ddlRightsRole.Items.FindByValue(roleId.ToString());
                    if (item != null)
                    {
                        ddlRightsRole.ClearSelection();
                        item.Selected = true;
                        LoadRights(item.Text);
                    }
                    break;
            }
        }

        private void OpenRoleEditor(int roleId)
        {
            var dt = DBHelper.ExecuteDataTable("sp_GetRoles");
            DataRow row = dt.Select("RoleID = " + roleId).FirstOrDefault();
            if (row == null)
            {
                ShowErr("That role no longer exists.");
                BindRolesGrid();
                return;
            }

            hfRoleID.Value   = roleId.ToString();
            txtRoleName.Text = Convert.ToString(row["RoleName"]);
            pnlRoleEditor.Visible = true;
        }

        protected void btnSaveRole_Click(object sender, EventArgs e)
        {
            if (!Page.IsValid) { pnlRoleEditor.Visible = true; return; }

            int roleId = 0;
            int.TryParse(hfRoleID.Value, out roleId);

            try
            {
                var idParam = DBHelper.OutputParameter("@RoleID", SqlDbType.Int);
                idParam.Value = roleId;

                DBHelper.ExecuteNonQuery("sp_SaveRole",
                    idParam,
                    DBHelper.Parameter("@RoleName", txtRoleName.Text.Trim()));

                ShowMsg(roleId == 0 ? "Role created." : "Role updated.");
                pnlRoleEditor.Visible = false;
                BindRolesGrid();
                BindRightsRoleDropdown();
            }
            catch (SqlException ex)
            {
                ShowErr(ex.Message);
                pnlRoleEditor.Visible = true;
            }
        }

        protected void btnCancelRole_Click(object sender, EventArgs e)
        {
            pnlRoleEditor.Visible = false;
        }

        private void DeleteRole(int roleId)
        {
            try
            {
                // sp_DeleteRole blocks deletion while users still hold the role.
                DBHelper.ExecuteNonQuery("sp_DeleteRole", DBHelper.Parameter("@RoleID", roleId));
                ShowMsg("Role deleted.");
                pnlRoleEditor.Visible = false;
                BindRolesGrid();
                BindRightsRoleDropdown();
            }
            catch (SqlException ex)
            {
                ShowErr(ex.Message);
                BindRolesGrid();
            }
        }

        // ══════════════════════════════════════════════════════════════
        //  RIGHTS MATRIX
        // ══════════════════════════════════════════════════════════════

        private void BindRightsRoleDropdown()
        {
            string current = ddlRightsRole.SelectedValue;

            var dt = DBHelper.ExecuteDataTable("sp_GetRoles");
            ddlRightsRole.DataSource     = dt;
            ddlRightsRole.DataTextField  = "RoleName";
            ddlRightsRole.DataValueField = "RoleID";
            ddlRightsRole.DataBind();
            ddlRightsRole.Items.Insert(0, new ListItem("- Select role -", ""));

            // Preserve the previous selection if it still exists.
            if (!string.IsNullOrEmpty(current))
            {
                var item = ddlRightsRole.Items.FindByValue(current);
                if (item != null) { ddlRightsRole.ClearSelection(); item.Selected = true; }
            }
        }

        protected void ddlRightsRole_SelectedIndexChanged(object sender, EventArgs e)
        {
            if (string.IsNullOrEmpty(ddlRightsRole.SelectedValue))
            {
                SelectedRoleName     = null;
                pnlRights.Visible    = false;
                pnlNoRole.Visible    = true;
                return;
            }
            LoadRights(ddlRightsRole.SelectedItem.Text);
        }

        // Items grouped by GroupID, used to bind the nested per-group item repeater
        // during the same LoadRights call (rptRights_ItemDataBound reads from this).
        private Dictionary<int, DataTable> _itemsByGroup;

        // Builds the group list (with a Granted flag) plus, per group, its items
        // (each with a Granted flag) for the chosen role, then binds the matrix.
        private void LoadRights(string roleName)
        {
            SelectedRoleName = roleName;

            var groups     = DBHelper.ExecuteDataTable("sp_GetNavGroups");
            var groupGrant = DBHelper.ExecuteDataTable("sp_GetNavGroupRoles");
            var items      = DBHelper.ExecuteDataTable("sp_GetNavItems");
            var itemGrant  = DBHelper.ExecuteDataTable("sp_GetNavItemRoles");

            // GroupIDs currently granted to this role.
            var grantedGroups = groupGrant.AsEnumerable()
                .Where(r => RoleMatch(r["RoleName"], roleName))
                .Select(r => Convert.ToInt32(r["GroupID"]))
                .ToHashSet();

            // ItemIDs explicitly granted to this role.
            var grantedItems = itemGrant.AsEnumerable()
                .Where(r => RoleMatch(r["RoleName"], roleName))
                .Select(r => Convert.ToInt32(r["ItemID"]))
                .ToHashSet();

            // ItemIDs that are restricted for *someone* (have at least one explicit row).
            var restrictedItems = itemGrant.AsEnumerable()
                .Select(r => Convert.ToInt32(r["ItemID"]))
                .ToHashSet();

            // Group items by GroupID with a per-role Granted flag.
            // Inherit-unless-overridden: an unrestricted item is "on" whenever its
            // group is granted; a restricted item is "on" only if granted to this role.
            _itemsByGroup = new Dictionary<int, DataTable>();
            foreach (DataRow it in items.Rows)
            {
                int itemId  = Convert.ToInt32(it["ItemID"]);
                int groupId = Convert.ToInt32(it["GroupID"]);

                if (!_itemsByGroup.TryGetValue(groupId, out var tbl))
                {
                    tbl = NewItemTable();
                    _itemsByGroup[groupId] = tbl;
                }

                bool granted = restrictedItems.Contains(itemId)
                    ? grantedItems.Contains(itemId)
                    : grantedGroups.Contains(groupId);

                tbl.Rows.Add(itemId, Convert.ToString(it["ItemName"]), granted);
            }

            var view = new DataTable();
            view.Columns.Add("GroupID", typeof(int));
            view.Columns.Add("GroupName", typeof(string));
            view.Columns.Add("SectionName", typeof(string));
            view.Columns.Add("Granted", typeof(bool));

            foreach (DataRow g in groups.Rows)
            {
                int groupId = Convert.ToInt32(g["GroupID"]);
                view.Rows.Add(groupId,
                    Convert.ToString(g["GroupName"]),
                    Convert.ToString(g["SectionName"]),
                    grantedGroups.Contains(groupId));
            }

            rptRights.DataSource = view;
            rptRights.DataBind();

            pnlRights.Visible = true;
            pnlNoRole.Visible = false;
        }

        // Binds each group row's nested item repeater from the per-group lookup.
        protected void rptRights_ItemDataBound(object sender, RepeaterItemEventArgs e)
        {
            if (e.Item.ItemType != ListItemType.Item && e.Item.ItemType != ListItemType.AlternatingItem)
                return;

            var hf = (HtmlInputHidden)e.Item.FindControl("hfGroupId");
            var rptItems = (Repeater)e.Item.FindControl("rptItems");
            if (hf == null || rptItems == null) return;

            int groupId = Convert.ToInt32(hf.Value);
            if (_itemsByGroup != null && _itemsByGroup.TryGetValue(groupId, out var tbl))
            {
                rptItems.DataSource = tbl;
                rptItems.DataBind();
            }
        }

        protected void btnSaveRights_Click(object sender, EventArgs e)
        {
            string roleName = SelectedRoleName;
            if (string.IsNullOrEmpty(roleName))
            {
                ShowErr("Select a role before saving rights.");
                return;
            }

            var groupIds   = new List<string>();   // groups this role may see
            var grantItems = new List<string>();   // checked items in visible groups
            var scopeItems = new List<string>();   // ALL items in visible groups (evaluation scope)

            foreach (RepeaterItem grp in rptRights.Items)
            {
                var chkGroup = (CheckBox)grp.FindControl("chkGroup");
                var hfGroup  = (HtmlInputHidden)grp.FindControl("hfGroupId");
                if (chkGroup == null || hfGroup == null) continue;

                bool groupChecked = chkGroup.Checked;
                if (groupChecked)
                    groupIds.Add(hfGroup.Value);

                var rptItems = (Repeater)grp.FindControl("rptItems");
                if (rptItems == null) continue;

                foreach (RepeaterItem it in rptItems.Items)
                {
                    var chkItem = (CheckBox)it.FindControl("chkItem");
                    var hfItem  = (HtmlInputHidden)it.FindControl("hfItemId");
                    if (chkItem == null || hfItem == null) continue;

                    // Item rights only matter for groups the role can see.
                    if (!groupChecked) continue;

                    scopeItems.Add(hfItem.Value);
                    if (chkItem.Checked) grantItems.Add(hfItem.Value);
                }
            }

            try
            {
                DBHelper.ExecuteNonQuery("sp_SetRoleNavGroups",
                    DBHelper.Parameter("@RoleName", roleName),
                    DBHelper.Parameter("@GroupIDs", groupIds.Count > 0
                        ? (object)string.Join(",", groupIds)
                        : DBNull.Value));

                DBHelper.ExecuteNonQuery("sp_SetRoleNavItems",
                    DBHelper.Parameter("@RoleName", roleName),
                    DBHelper.Parameter("@GrantItemIDs", grantItems.Count > 0
                        ? (object)string.Join(",", grantItems)
                        : DBNull.Value),
                    DBHelper.Parameter("@ScopeItemIDs", scopeItems.Count > 0
                        ? (object)string.Join(",", scopeItems)
                        : DBNull.Value));

                ShowMsg("Menu rights updated for the \"" + roleName + "\" role.");
                LoadRights(roleName);
            }
            catch (SqlException ex)
            {
                ShowErr(ex.Message);
            }
        }

        private static bool RoleMatch(object roleNameValue, string roleName)
            => string.Equals(Convert.ToString(roleNameValue), roleName, StringComparison.OrdinalIgnoreCase);

        private static DataTable NewItemTable()
        {
            var t = new DataTable();
            t.Columns.Add("ItemID", typeof(int));
            t.Columns.Add("ItemName", typeof(string));
            t.Columns.Add("Granted", typeof(bool));
            return t;
        }

        // ── Helpers ──────────────────────────────────────────────────

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
