<%@ Page Title="Roles &amp; Rights" Language="C#" MasterPageFile="~/Site.Master" AutoEventWireup="true"
   CodeBehind="Roles.aspx.cs" Inherits="OMS.Admin.Roles" %>

<asp:Content ID="Content1" ContentPlaceHolderID="MainContent" runat="server">

  <%-- ── Page header ── --%>
  <div class="d-flex flex-wrap align-items-center justify-content-between gap-2 mb-3">
    <div>
      <h4 class="mb-0">Roles &amp; Rights</h4>
      <p class="text-600 fs--1 mb-0">Manage roles and control which menu sections each role can see.</p>
    </div>
    <a href="Users.aspx" class="btn btn-sm btn-falcon-default flex-shrink-0">
      <span class="fas fa-users me-1"></span> Users
    </a>
  </div>

  <asp:UpdatePanel ID="updRoles" runat="server">
    <ContentTemplate>

      <%-- ── Feedback ── --%>
      <asp:Label ID="lblMsg" runat="server" Visible="false"
        CssClass="alert alert-success d-block mb-3 py-2 fs--1"
        EnableViewState="false" />
      <asp:Label ID="lblErr" runat="server" Visible="false"
        CssClass="alert alert-danger d-block mb-3 py-2 fs--1"
        EnableViewState="false" />

      <div class="row g-3">

        <%-- ══════════════════════════════════════════════════════════
             LEFT: ROLES CRUD
             ══════════════════════════════════════════════════════════ --%>
        <div class="col-lg-5">
          <div class="card h-lg-100">
            <div class="card-header py-2 d-flex flex-wrap align-items-center justify-content-between gap-2">
              <h5 class="mb-0 fs-0"><span class="fas fa-user-tag me-2 text-600"></span>Roles</h5>
              <asp:Button ID="btnAddRole" runat="server" CssClass="btn btn-sm btn-primary flex-shrink-0"
                CausesValidation="false" Text="+ Add Role" OnClick="btnAddRole_Click" />
            </div>
            <div class="card-body pt-2">

              <%-- Role add/edit editor --%>
              <asp:Panel ID="pnlRoleEditor" runat="server" Visible="false" CssClass="border rounded p-3 mb-3 bg-light">
                <asp:HiddenField ID="hfRoleID" runat="server" Value="0" />
                <label class="form-label fs--1 mb-1">Role Name<span class="text-danger ms-1">*</span></label>
                <div class="d-flex flex-column flex-sm-row gap-2">
                  <asp:TextBox ID="txtRoleName" runat="server" CssClass="form-control form-control-sm flex-grow-1" MaxLength="50" />
                  <div class="d-flex gap-2">
                    <asp:Button ID="btnSaveRole" runat="server" CssClass="btn btn-sm btn-primary flex-grow-1"
                      Text="Save" ValidationGroup="RoleEditor" OnClick="btnSaveRole_Click" />
                    <asp:Button ID="btnCancelRole" runat="server" CssClass="btn btn-sm btn-falcon-default flex-grow-1"
                      Text="Cancel" CausesValidation="false" OnClick="btnCancelRole_Click" />
                  </div>
                </div>
                <asp:RequiredFieldValidator runat="server" ControlToValidate="txtRoleName"
                  ValidationGroup="RoleEditor" Display="Dynamic"
                  CssClass="text-danger fs--2" Text="Role name is required." />
              </asp:Panel>

              <div class="table-responsive">
                <asp:GridView ID="gvRoles" runat="server"
                  CssClass="table table-sm table-hover align-middle mb-0"
                  AutoGenerateColumns="False" GridLines="None"
                  DataKeyNames="RoleID"
                  EmptyDataText="No roles defined."
                  OnRowCommand="gvRoles_RowCommand">
                  <EmptyDataRowStyle CssClass="text-center text-600 py-4 fs--1" />
                  <HeaderStyle CssClass="bg-light border-bottom" />
                  <Columns>
                    <asp:BoundField DataField="RoleName" HeaderText="Role"
                      HeaderStyle-CssClass="ps-3 fw-medium" ItemStyle-CssClass="ps-3 fw-semibold" />
                    <asp:BoundField DataField="UserCount" HeaderText="Users"
                      HeaderStyle-CssClass="text-center fw-medium" ItemStyle-CssClass="text-center text-600" />
                    <asp:TemplateField HeaderText="Actions"
                      HeaderStyle-CssClass="text-end fw-medium pe-3" ItemStyle-CssClass="text-end pe-3">
                      <ItemTemplate>
                        <div class="d-inline-flex gap-1">
                          <asp:LinkButton runat="server" CommandName="EditRole"
                            CommandArgument='<%# Eval("RoleID") %>' CausesValidation="false"
                            CssClass="btn btn-sm btn-falcon-default px-2 py-0 fs--2" ToolTip="Rename">
                            <span class="fas fa-edit"></span>
                          </asp:LinkButton>
                          <asp:LinkButton runat="server" CommandName="RightsRole"
                            CommandArgument='<%# Eval("RoleID") %>' CausesValidation="false"
                            CssClass="btn btn-sm btn-falcon-info px-2 py-0 fs--2" ToolTip="Edit rights">
                            <span class="fas fa-key"></span>
                          </asp:LinkButton>
                          <asp:LinkButton runat="server" CommandName="DeleteRole"
                            CommandArgument='<%# Eval("RoleID") %>' CausesValidation="false"
                            CssClass="btn btn-sm btn-falcon-danger px-2 py-0 fs--2" ToolTip="Delete"
                            OnClientClick="return confirm('Delete this role? Only allowed when no users hold it.');">
                            <span class="fas fa-trash-alt"></span>
                          </asp:LinkButton>
                        </div>
                      </ItemTemplate>
                    </asp:TemplateField>
                  </Columns>
                </asp:GridView>
              </div>
            </div>
          </div>
        </div>

        <%-- ══════════════════════════════════════════════════════════
             RIGHT: RIGHTS MATRIX  (nav-group visibility for selected role)
             ══════════════════════════════════════════════════════════ --%>
        <div class="col-lg-7">
          <div class="card h-100">
            <div class="card-header py-2">
              <h5 class="mb-0 fs-0"><span class="fas fa-shield-alt me-2 text-600"></span>Menu Rights</h5>
            </div>
            <div class="card-body pt-2">

              <div class="row g-2 align-items-end mb-3">
                <div class="col-sm-8">
                  <label class="form-label fs--1 mb-1">Role</label>
                  <asp:DropDownList ID="ddlRightsRole" runat="server" CssClass="form-select form-select-sm"
                    AutoPostBack="true" OnSelectedIndexChanged="ddlRightsRole_SelectedIndexChanged" />
                </div>
              </div>

              <asp:Panel ID="pnlRights" runat="server" Visible="false">
                <p class="fs--2 text-600 mb-2">
                  Tick the menu groups this role may see in the sidebar, and the pages within each group.
                  Groups shared with <em>everyone</em> (like Dashboard) always appear regardless.
                  A group with no ticked pages is hidden entirely.
                </p>

                <div class="border rounded p-2 mb-3" style="max-height:420px; overflow-y:auto;">
                  <asp:Repeater ID="rptRights" runat="server" OnItemDataBound="rptRights_ItemDataBound">
                    <ItemTemplate>
                      <div class="mb-2">
                        <%-- Group row --%>
                        <div class="form-check py-1">
                          <asp:CheckBox runat="server" ID="chkGroup" CssClass="form-check-input"
                            Checked='<%# (bool)Eval("Granted") %>' />
                          <input type="hidden" runat="server" id="hfGroupId" value='<%# Eval("GroupID") %>' />
                          <label class="form-check-label fs--1 fw-semibold">
                            <%# Server.HtmlEncode(Convert.ToString(Eval("GroupName"))) %>
                            <span class="badge badge-subtle-secondary ms-1 fs--2"><%# Server.HtmlEncode(Convert.ToString(Eval("SectionName"))) %></span>
                          </label>
                        </div>

                        <%-- Sub-items (pages) for this group — indent the whole block --%>
                        <div class="ms-4">
                          <asp:Repeater runat="server" ID="rptItems">
                            <ItemTemplate>
                              <div class="form-check py-1">
                                <asp:CheckBox runat="server" ID="chkItem" CssClass="form-check-input"
                                  Checked='<%# (bool)Eval("Granted") %>' />
                                <input type="hidden" runat="server" id="hfItemId" value='<%# Eval("ItemID") %>' />
                                <label class="form-check-label fs--1 text-700">
                                  <span class="fas fa-angle-right me-1 text-400"></span>
                                  <%# Server.HtmlEncode(Convert.ToString(Eval("ItemName"))) %>
                                </label>
                              </div>
                            </ItemTemplate>
                          </asp:Repeater>
                        </div>
                      </div>
                    </ItemTemplate>
                  </asp:Repeater>
                </div>

                <asp:Button ID="btnSaveRights" runat="server" CssClass="btn btn-sm btn-primary"
                  CausesValidation="false" Text="Save Rights" OnClick="btnSaveRights_Click" />
              </asp:Panel>

              <asp:Panel ID="pnlNoRole" runat="server" CssClass="text-center text-600 py-5 fs--1">
                Select a role above to view and edit its menu rights.
              </asp:Panel>

            </div>
          </div>
        </div>

      </div>

    </ContentTemplate>
  </asp:UpdatePanel>

</asp:Content>
