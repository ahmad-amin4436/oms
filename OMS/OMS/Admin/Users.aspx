<%@ Page Title="Users" Language="C#" MasterPageFile="~/Site.Master" AutoEventWireup="true"
   CodeBehind="Users.aspx.cs" Inherits="OMS.Admin.Users" %>

<asp:Content ID="Content1" ContentPlaceHolderID="MainContent" runat="server">

  <%-- ── Page header ── --%>
  <div class="d-flex align-items-center justify-content-between mb-3">
    <div>
      <h4 class="mb-0">Users</h4>
      <p class="text-600 fs--1 mb-0">Create, edit and manage staff accounts and roles.</p>
    </div>
    <a href="Roles.aspx" class="btn btn-sm btn-falcon-default">
      <span class="fas fa-user-shield me-1"></span> Roles &amp; Rights
    </a>
  </div>

  <asp:UpdatePanel ID="updUsers" runat="server">
    <ContentTemplate>

      <%-- ── Feedback ── --%>
      <asp:Label ID="lblMsg" runat="server" Visible="false"
        CssClass="alert alert-success d-block mb-3 py-2 fs--1"
        EnableViewState="false" />
      <asp:Label ID="lblErr" runat="server" Visible="false"
        CssClass="alert alert-danger d-block mb-3 py-2 fs--1"
        EnableViewState="false" />

      <%-- ══════════════════════════════════════════════════════════════
           ADD / EDIT EDITOR  (hidden until Add New / Edit is clicked)
           ══════════════════════════════════════════════════════════════ --%>
      <asp:Panel ID="pnlEditor" runat="server" Visible="false" CssClass="card mb-3 border-primary">
        <div class="card-header py-2 bg-light d-flex align-items-center justify-content-between">
          <h5 class="mb-0 fs-0"><asp:Literal ID="litEditorTitle" runat="server" Text="Add New User" /></h5>
          <asp:LinkButton ID="lbCloseEditor" runat="server" CssClass="btn btn-sm btn-falcon-default p-1 lh-1"
            CausesValidation="false" OnClick="lbCancel_Click" ToolTip="Close">&times;</asp:LinkButton>
        </div>
        <div class="card-body">
          <asp:HiddenField ID="hfUserID" runat="server" Value="0" />
          <div class="row g-3">

            <div class="col-md-6">
              <label class="form-label fs--1 mb-1">Full Name<span class="text-danger ms-1">*</span></label>
              <asp:TextBox ID="txtFullName" runat="server" CssClass="form-control form-control-sm" MaxLength="120" />
              <asp:RequiredFieldValidator runat="server" ControlToValidate="txtFullName"
                ValidationGroup="Editor" Display="Dynamic"
                CssClass="text-danger fs--2" Text="Full name is required." />
            </div>

            <div class="col-md-6">
              <label class="form-label fs--1 mb-1">Email<span class="text-danger ms-1">*</span></label>
              <asp:TextBox ID="txtEmail" runat="server" CssClass="form-control form-control-sm"
                TextMode="Email" MaxLength="150" />
              <asp:RequiredFieldValidator runat="server" ControlToValidate="txtEmail"
                ValidationGroup="Editor" Display="Dynamic"
                CssClass="text-danger fs--2" Text="Email is required." />
              <asp:RegularExpressionValidator runat="server" ControlToValidate="txtEmail"
                ValidationGroup="Editor" Display="Dynamic"
                ValidationExpression="^[^@\s]+@[^@\s]+\.[^@\s]+$"
                CssClass="text-danger fs--2" Text="Enter a valid email address." />
            </div>

            <div class="col-md-6">
              <label class="form-label fs--1 mb-1">
                Password<span class="text-danger ms-1">*</span>
                <asp:Literal ID="litPwdHint" runat="server" />
              </label>
              <asp:TextBox ID="txtPassword" runat="server" CssClass="form-control form-control-sm"
                TextMode="Password" MaxLength="100" autocomplete="new-password" />
              <asp:RequiredFieldValidator ID="rfvPassword" runat="server" ControlToValidate="txtPassword"
                ValidationGroup="Editor" Display="Dynamic"
                CssClass="text-danger fs--2" Text="Password is required for a new user." />
            </div>

            <div class="col-md-6">
              <label class="form-label fs--1 mb-1">Role<span class="text-danger ms-1">*</span></label>
              <asp:DropDownList ID="ddlRole" runat="server" CssClass="form-select form-select-sm" />
              <asp:RequiredFieldValidator runat="server" ControlToValidate="ddlRole"
                ValidationGroup="Editor" Display="Dynamic" InitialValue=""
                CssClass="text-danger fs--2" Text="Select a role." />
            </div>

            <div class="col-12">
              <div class="form-check mb-0">
                <asp:CheckBox ID="chkActive" runat="server" CssClass="form-check-input" Checked="true" />
                <label class="form-check-label fs--1">Active (can sign in)</label>
              </div>
            </div>

            <div class="col-12 d-flex gap-2 border-top pt-3">
              <asp:Button ID="btnSave" runat="server" CssClass="btn btn-sm btn-primary"
                Text="Save User" ValidationGroup="Editor" OnClick="btnSave_Click" />
              <asp:Button ID="btnCancel" runat="server" CssClass="btn btn-sm btn-falcon-default"
                Text="Cancel" CausesValidation="false" OnClick="lbCancel_Click" />
            </div>

          </div>
        </div>
      </asp:Panel>

      <%-- ── Toolbar ── --%>
      <div class="card mb-3">
        <div class="card-body py-2 d-flex flex-wrap gap-2 align-items-center">
          <span class="fs--1 text-600">Showing all staff accounts.</span>
          <asp:Button ID="btnAddNew" runat="server" CssClass="btn btn-sm btn-primary ms-auto"
            Text="+ Add New User" CausesValidation="false" OnClick="btnAddNew_Click" />
        </div>
      </div>

      <%-- ── Users table ── --%>
      <div class="card">
        <div class="table-responsive">
          <asp:GridView ID="gvUsers" runat="server"
            CssClass="table table-sm table-hover align-middle mb-0"
            AutoGenerateColumns="False" GridLines="None"
            DataKeyNames="UserID"
            EmptyDataText="No users found."
            OnRowCommand="gvUsers_RowCommand">
            <EmptyDataRowStyle CssClass="text-center text-600 py-4 fs--1" />
            <HeaderStyle CssClass="bg-light border-bottom" />
            <Columns>
              <asp:BoundField DataField="FullName" HeaderText="Name"
                HeaderStyle-CssClass="ps-3 fw-medium"
                ItemStyle-CssClass="ps-3 fw-semibold" />
              <asp:BoundField DataField="Email" HeaderText="Email"
                HeaderStyle-CssClass="fw-medium"
                ItemStyle-CssClass="text-600" />
              <asp:BoundField DataField="RoleName" HeaderText="Role"
                HeaderStyle-CssClass="fw-medium" />
              <asp:TemplateField HeaderText="Status"
                HeaderStyle-CssClass="text-center fw-medium"
                ItemStyle-CssClass="text-center">
                <ItemTemplate>
                  <span class='badge <%# (bool)Eval("IsActive") ? "badge-subtle-success" : "badge-subtle-danger" %>'>
                    <%# (bool)Eval("IsActive") ? "Active" : "Inactive" %>
                  </span>
                </ItemTemplate>
              </asp:TemplateField>
              <asp:BoundField DataField="CreatedAt" HeaderText="Joined"
                DataFormatString="{0:dd MMM yyyy}"
                HeaderStyle-CssClass="fw-medium"
                ItemStyle-CssClass="text-600" />
              <asp:TemplateField HeaderText="Actions"
                HeaderStyle-CssClass="text-end fw-medium pe-3"
                ItemStyle-CssClass="text-end pe-3">
                <ItemTemplate>
                  <div class="d-inline-flex gap-1">
                    <asp:LinkButton runat="server"
                      CommandName="EditUser"
                      CommandArgument='<%# Eval("UserID") %>'
                      CausesValidation="false"
                      CssClass="btn btn-sm btn-falcon-default px-2 py-0 fs--2"
                      ToolTip="Edit">
                      <span class="fas fa-edit"></span>
                    </asp:LinkButton>
                    <asp:LinkButton runat="server"
                      CommandName="Toggle"
                      CommandArgument='<%# Eval("UserID") %>'
                      CausesValidation="false"
                      CssClass='<%# "btn btn-sm px-2 py-0 fs--2 " + ((bool)Eval("IsActive") ? "btn-falcon-warning" : "btn-falcon-success") %>'>
                      <%# (bool)Eval("IsActive") ? "Deactivate" : "Activate" %>
                    </asp:LinkButton>
                    <asp:LinkButton runat="server"
                      CommandName="DeleteUser"
                      CommandArgument='<%# Eval("UserID") %>'
                      CausesValidation="false"
                      CssClass="btn btn-sm btn-falcon-danger px-2 py-0 fs--2"
                      ToolTip="Delete"
                      OnClientClick="return confirm('Permanently delete this user? This cannot be undone.');">
                      <span class="fas fa-trash-alt"></span>
                    </asp:LinkButton>
                  </div>
                </ItemTemplate>
              </asp:TemplateField>
            </Columns>
          </asp:GridView>
        </div>
      </div>

    </ContentTemplate>
  </asp:UpdatePanel>

</asp:Content>
