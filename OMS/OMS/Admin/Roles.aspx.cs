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

        protected void Page_Init(object sender, EventArgs e)
        {
            // Page_Init runs before Page_Load and touches the database, so the
            // View permission must be enforced here too.
            SecurityHelper.RequirePermission("Administration.Roles.View");

            // Recreate dynamic repeater controls before postback data is
            // applied. Without this, btnSaveRights_Click sees no checkboxes
            // and every save silently clears or ignores the submitted rights.
            if (!IsPostBack) return;

            BindRightsRoleDropdown();
            string roleId = Request.Form[ddlRightsRole.UniqueID];
            ListItem selected = ddlRightsRole.Items.FindByValue(roleId);
            if (selected != null)
            {
                ddlRightsRole.ClearSelection();
                selected.Selected = true;
                LoadRights(selected.Text);
            }
        }

        protected void Page_Load(object sender, EventArgs e)
        {
            SecurityHelper.RequirePermission("Administration.Roles.View");
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
            SecurityHelper.RequirePermission("Administration.Roles.Add");
            hfRoleID.Value = "0";
            txtRoleName.Text = "";
            pnlRoleEditor.Visible = true;
        }

        protected void gvRoles_RowCommand(object sender, GridViewCommandEventArgs e)
        {
            int roleId = Convert.ToInt32(e.CommandArgument);

            switch (e.CommandName)
            {
                case "EditRole":
                    SecurityHelper.RequirePermission("Administration.Roles.Edit");
                    OpenRoleEditor(roleId);
                    break;
                case "DeleteRole":
                    SecurityHelper.RequirePermission("Administration.Roles.Delete");
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

            hfRoleID.Value = roleId.ToString();
            txtRoleName.Text = Convert.ToString(row["RoleName"]);
            pnlRoleEditor.Visible = true;
        }

        protected void btnSaveRole_Click(object sender, EventArgs e)
        {
            SecurityHelper.RequirePermission(string.IsNullOrEmpty(hfRoleID.Value) || hfRoleID.Value == "0" ? "Administration.Roles.Add" : "Administration.Roles.Edit");
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

                // If the deleted role was the one open in the matrix, close the matrix.
                if (string.IsNullOrEmpty(ddlRightsRole.SelectedValue))
                {
                    SelectedRoleName = null;
                    pnlRights.Visible = false;
                    pnlNoRole.Visible = true;
                }
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
            ddlRightsRole.DataSource = dt;
            ddlRightsRole.DataTextField = "RoleName";
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
                SelectedRoleName = null;
                pnlRights.Visible = false;
                pnlNoRole.Visible = true;
                return;
            }
            LoadRights(ddlRightsRole.SelectedItem.Text);
        }

        // Items grouped by GroupID, used to bind the nested per-group item repeater
        // during the same LoadRights call (rptRights_ItemDataBound reads from this).
        private Dictionary<int, DataTable> _itemsByGroup;

        // The exact tables the repeaters were bound to in this request. The save
        // handler reads IDs from these (by repeater item index) instead of trusting
        // any ID posted back from the browser.
        private DataTable _groupsView;
        private DataTable _permissionsView;

        // Builds the group list (with a Granted flag) plus, per group, its items
        // (each with a Granted flag) for the chosen role, then binds the matrix.
        private void LoadRights(string roleName)
        {
            SecurityHelper.RequirePermission("Roles.ManageRights");
            SelectedRoleName = roleName;

            var groups = DBHelper.ExecuteDataTable("sp_GetNavGroups");
            var groupGrant = DBHelper.ExecuteDataTable("sp_GetNavGroupRoles");
            var items = DBHelper.ExecuteDataTable("sp_GetNavItems");
            var itemGrant = DBHelper.ExecuteDataTable("sp_GetNavItemRoles");

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
                int itemId = Convert.ToInt32(it["ItemID"]);
                int groupId = Convert.ToInt32(it["GroupID"]);

                if (!_itemsByGroup.TryGetValue(groupId, out var tbl))
                {
                    tbl = NewItemTable();
                    _itemsByGroup[groupId] = tbl;
                }

                bool granted = restrictedItems.Contains(itemId)
                    ? grantedItems.Contains(itemId)
                    : grantedGroups.Contains(groupId);

                tbl.Rows.Add(itemId, groupId, Convert.ToString(it["ItemName"]), granted);
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

            _groupsView = view;
            rptRights.DataSource = view;
            rptRights.DataBind();

            var permissions = DBHelper.ExecuteDataTable("sp_GetPermissionCatalog",
                DBHelper.Parameter("@RoleID", ddlRightsRole.SelectedValue));
            if (!permissions.Columns.Contains("PageItemID"))
                permissions.Columns.Add("PageItemID", typeof(int));

            if (!permissions.Columns.Contains("LinkGroupID"))
                permissions.Columns.Add("LinkGroupID", typeof(int));

            foreach (DataRow permission in permissions.Rows)
            {
                string moduleKey = Convert.ToString(permission["ModuleKey"]);
                int pageItemId = ResolvePermissionPageItemId(moduleKey, items);
                permission["PageItemID"] = pageItemId == 0 ? (object)DBNull.Value : pageItemId;

                // No page found: fall back to the module's sidebar group, if it has one.
                int linkGroupId = pageItemId == 0 ? ResolvePermissionGroupId(moduleKey, groups) : 0;
                permission["LinkGroupID"] = linkGroupId == 0 ? (object)DBNull.Value : linkGroupId;
            }

            DataTable linkedPermissions = permissions.Clone();

            foreach (DataRow permission in permissions.Rows)
            {
                if (permission["PageItemID"] != DBNull.Value ||
                    permission["LinkGroupID"] != DBNull.Value)
                {
                    linkedPermissions.ImportRow(permission);
                }
            }

            _permissionsView = linkedPermissions;
            rptPermissions.DataSource = linkedPermissions;
            rptPermissions.DataBind();

            // Group → page → operation cascading (check all / uncheck all / hide / disable)
            // is handled by the single client script in Roles.aspx. The save handler below
            // re-applies the same rules on the server.

            pnlRights.Visible = true;
            pnlNoRole.Visible = false;
        }

        // Binds each group row's nested item repeater from the per-group lookup.
        protected void rptRights_ItemDataBound(object sender, RepeaterItemEventArgs e)
        {
            if (e.Item.ItemType != ListItemType.Item && e.Item.ItemType != ListItemType.AlternatingItem)
                return;

            var rptItems = (Repeater)e.Item.FindControl("rptItems");
            var row = e.Item.DataItem as DataRowView;
            if (rptItems == null || row == null) return;

            int groupId = Convert.ToInt32(row["GroupID"]);
            if (_itemsByGroup != null && _itemsByGroup.TryGetValue(groupId, out var tbl))
            {
                rptItems.DataSource = tbl;
                rptItems.DataBind();
            }
        }

        protected void btnSaveRights_Click(object sender, EventArgs e)
        {
            SecurityHelper.RequirePermission("Roles.ManageRights");

            // The role comes from the dropdown the matrix was rebuilt for in Page_Init
            // (not from a client-supplied hidden field).
            int roleId;
            if (!int.TryParse(ddlRightsRole.SelectedValue, out roleId) || roleId <= 0)
            {
                ShowErr("Select a role before saving rights.");
                return;
            }
            string roleName = ddlRightsRole.SelectedItem.Text;

            // Safety net: if the matrix was not rebuilt, saving would wipe the role's rights.
            if (_groupsView == null || _permissionsView == null || _itemsByGroup == null
                || rptRights.Items.Count != _groupsView.Rows.Count
                || rptPermissions.Items.Count != _permissionsView.Rows.Count)
            {
                ShowErr("The rights matrix is out of date. Please re-select the role and try again.");
                return;
            }

            var groupIds = new List<string>();   // groups this role may see
            var grantItems = new List<string>();   // checked items in visible groups
            var scopeItems = new List<string>();   // all items in selected groups
            var selectedItemIds = new HashSet<int>();   // pages that are actually selected
            var selectedGroupIds = new HashSet<int>();  // groups that are actually selected

            // IDs are read from the server-side tables by index, never from posted values.
            for (int g = 0; g < rptRights.Items.Count; g++)
            {
                RepeaterItem grp = rptRights.Items[g];
                var chkGroup = (HtmlInputCheckBox)grp.FindControl("chkGroup");
                if (chkGroup == null) continue;

                // Unchecked group => the group and everything beneath it is not granted.
                if (!chkGroup.Checked) continue;

                int groupId = Convert.ToInt32(_groupsView.Rows[g]["GroupID"]);
                groupIds.Add(groupId.ToString());
                selectedGroupIds.Add(groupId);

                var rptItems = (Repeater)grp.FindControl("rptItems");
                DataTable tbl;
                if (rptItems == null || !_itemsByGroup.TryGetValue(groupId, out tbl)) continue;

                if (rptItems.Items.Count != tbl.Rows.Count)
                {
                    ShowErr("The rights matrix is out of date. Please re-select the role and try again.");
                    return;
                }

                for (int i = 0; i < rptItems.Items.Count; i++)
                {
                    var chkItem = (HtmlInputCheckBox)rptItems.Items[i].FindControl("chkItem");
                    if (chkItem == null) continue;

                    int itemId = Convert.ToInt32(tbl.Rows[i]["ItemID"]);
                    scopeItems.Add(itemId.ToString());
                    if (chkItem.Checked)
                    {
                        grantItems.Add(itemId.ToString());
                        selectedItemIds.Add(itemId);
                    }
                }
            }

            // An operation is saved only if it is checked AND its page is selected
            // (which in turn requires its group to be selected). Operations linked
            // to a group (no page) need that group selected. General operations
            // (Dashboard, Messages, Notifications) are saved exactly as ticked.
            var permissionIds = new List<string>();
            for (int p = 0; p < rptPermissions.Items.Count; p++)
            {
                var chk = (HtmlInputCheckBox)rptPermissions.Items[p].FindControl("chkPermission");
                if (chk == null || !chk.Checked) continue;

                DataRow permission = _permissionsView.Rows[p];
                int permissionId = Convert.ToInt32(permission["PermissionID"]);

                if (permission["PageItemID"] != DBNull.Value)
                {
                    if (selectedItemIds.Contains(Convert.ToInt32(permission["PageItemID"])))
                        permissionIds.Add(permissionId.ToString());
                }
                else if (permission["LinkGroupID"] != DBNull.Value)
                {
                    if (selectedGroupIds.Contains(Convert.ToInt32(permission["LinkGroupID"])))
                        permissionIds.Add(permissionId.ToString());
                }
            }

            try
            {
                DBHelper.ExecuteNonQuery("sp_SetRoleNavGroups",
                    DBHelper.Parameter("@RoleName", roleName),
                    DBHelper.Parameter("@GroupIDs", groupIds.Count > 0
                        ? (object)string.Join(",", groupIds)
                        : DBNull.Value));

                DBHelper.ExecuteNonQuery("sp_SetRolePermissions",
                    DBHelper.Parameter("@RoleID", roleId),
                    DBHelper.Parameter("@PermissionIDs", permissionIds.Count > 0
                        ? (object)string.Join(",", permissionIds)
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
            t.Columns.Add("GroupID", typeof(int));
            t.Columns.Add("ItemName", typeof(string));
            t.Columns.Add("Granted", typeof(bool));
            return t;
        }

        private static int ResolvePermissionPageItemId(string moduleKey, DataTable items)
        {
            if (string.IsNullOrEmpty(moduleKey) || items == null) return 0;

            // Older versions of sp_GetNavItems do not return Url.  The rights
            // page must work with both result shapes; ItemName is the fallback
            // because it identifies the same page in the navigation catalog.
            bool hasUrl = items.Columns.Contains("Url");
            bool hasItemName = items.Columns.Contains("ItemName");
            bool hasItemId = items.Columns.Contains("ItemID");
            if (!hasItemId || (!hasUrl && !hasItemName)) return 0;

            string[] aliases =
            {
                moduleKey,
                moduleKey == "Kitchen" ? "KitchenOrders" : null,
                moduleKey == "Offers" ? "OfferList" : null,
                moduleKey == "Menu" ? "MenuItems" : null,
                moduleKey == "Administration" ? "AdminDashboard" : null,
                moduleKey == "Deals" ? "DealsList" : null,
                moduleKey == "Orders" ? "OrderList" : null
            };

            foreach (string alias in aliases.Where(a => !string.IsNullOrEmpty(a)))
            {
                foreach (DataRow item in items.Rows)
                {
                    string candidate = null;

                    if (hasUrl && item["Url"] != DBNull.Value)
                    {
                        string url = Convert.ToString(item["Url"]).Trim();
                        if (!string.IsNullOrEmpty(url))
                        {
                            int slash = url.LastIndexOf('/');
                            candidate = slash >= 0 ? url.Substring(slash + 1) : url;
                            if (candidate.EndsWith(".aspx", StringComparison.OrdinalIgnoreCase))
                                candidate = candidate.Substring(0, candidate.Length - 5);
                        }
                    }

                    if (string.IsNullOrEmpty(candidate) && hasItemName)
                        candidate = Convert.ToString(item["ItemName"]).Trim();

                    if ((string.Equals(candidate, alias, StringComparison.OrdinalIgnoreCase)
                        || string.Equals(NormalizePageKey(candidate), NormalizePageKey(alias), StringComparison.OrdinalIgnoreCase))
                        && item["ItemID"] != DBNull.Value)
                        return Convert.ToInt32(item["ItemID"]);
                }
            }

            return 0;
        }

        // Modules that have no page row in sp_GetNavItems but are standalone sidebar
        // groups: their operations follow the group checkbox instead of a page.
        // Modules not listed here (Dashboard, Messages, Notifications) stay general
        // (always shown, saved as ticked).
        private static readonly Dictionary<string, string> ModuleGroupNames =
            new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase)
            {
                { "Kitchen",    "Kitchen" },
                { "Reports",    "Print Invoice" },
                { "Categories", "Menu Management" },
                { "Offers",     "Deals" },
                { "Analytics",  "Analytics" }
            };

        private static int ResolvePermissionGroupId(string moduleKey, DataTable groups)
        {
            string groupName;
            if (string.IsNullOrEmpty(moduleKey) || groups == null
                || !ModuleGroupNames.TryGetValue(moduleKey, out groupName)) return 0;

            foreach (DataRow g in groups.Rows)
            {
                if (string.Equals(Convert.ToString(g["GroupName"]), groupName, StringComparison.OrdinalIgnoreCase))
                    return Convert.ToInt32(g["GroupID"]);
            }
            return 0;
        }

        private static string NormalizePageKey(string value)
        {
            if (string.IsNullOrEmpty(value)) return string.Empty;
            return new string(value.Where(char.IsLetterOrDigit).ToArray());
        }

        // ── Helpers ──────────────────────────────────────────────────

        private void ShowMsg(string text)
        {
            lblMsg.Text = text;
            lblMsg.Visible = true;
            lblErr.Visible = false;
        }

        private void ShowErr(string text)
        {
            lblErr.Text = text;
            lblErr.Visible = true;
            lblMsg.Visible = false;
        }
    }
}
