<%@ Page Title="Departments" Language="C#" MasterPageFile="~/Site.Master" AutoEventWireup="true"
   CodeBehind="Departments.aspx.cs" Inherits="OMS.Admin.Departments" %>

<asp:Content ID="Content1" ContentPlaceHolderID="MainContent" runat="server">

  <div class="d-flex align-items-center justify-content-between mb-3">
    <div>
      <h4 class="mb-0">Departments</h4>
      <p class="text-600 fs--1 mb-0">Create departments, then create menu categories under them.</p>
    </div>
    <a href="../Menu/MenuItems.aspx" class="btn btn-sm btn-falcon-default">
      <span class="fas fa-tags me-1"></span> Menu &amp; Categories
    </a>
  </div>

  <%-- Partial-page updates: actions refresh this panel only, never the whole page. --%>
  <asp:UpdatePanel ID="updDepartments" runat="server" UpdateMode="Always"><ContentTemplate>

    <asp:Label ID="lblMsg" runat="server" Visible="false" EnableViewState="false"
      CssClass="alert alert-success d-block mb-3 py-2 fs--1" />
    <asp:Label ID="lblErr" runat="server" Visible="false" EnableViewState="false"
      CssClass="alert alert-danger d-block mb-3 py-2 fs--1" />

    <asp:Panel ID="pnlEditor" runat="server" Visible="false" CssClass="card mb-3 border-primary">
      <div class="card-header py-2 bg-light d-flex align-items-center justify-content-between">
        <h5 class="mb-0 fs-0"><asp:Literal ID="litEditorTitle" runat="server" Text="Add Department" /></h5>
        <asp:LinkButton ID="lbCloseEditor" runat="server" CssClass="btn btn-sm btn-falcon-default p-1 lh-1"
          CausesValidation="false" OnClick="btnCancel_Click" ToolTip="Close">&times;</asp:LinkButton>
      </div>
      <div class="card-body">
        <asp:HiddenField ID="hfDepartmentID" runat="server" Value="0" />
        <div class="row g-3">
          <div class="col-md-5">
            <label class="form-label fs--1 mb-1">Department Name<span class="text-danger ms-1">*</span></label>
            <asp:TextBox ID="txtName" runat="server" CssClass="form-control form-control-sm" MaxLength="80" />
            <asp:RequiredFieldValidator runat="server" ControlToValidate="txtName" ValidationGroup="Dept"
              Display="Dynamic" CssClass="text-danger fs--2" Text="Name is required." />
          </div>
          <div class="col-md-5">
            <label class="form-label fs--1 mb-1">Description</label>
            <asp:TextBox ID="txtDescription" runat="server" CssClass="form-control form-control-sm" MaxLength="250" />
          </div>
          <div class="col-md-2">
            <label class="form-label fs--1 mb-1">Display Order</label>
            <asp:TextBox ID="txtOrder" runat="server" CssClass="form-control form-control-sm" TextMode="Number" Text="0" />
            <asp:RangeValidator runat="server" ControlToValidate="txtOrder" ValidationGroup="Dept" Display="Dynamic"
              Type="Integer" MinimumValue="0" MaximumValue="9999" CssClass="text-danger fs--2" Text="0–9999." />
          </div>
          <div class="col-12">
            <div class="form-check mb-0">
              <asp:CheckBox ID="chkActive" runat="server" CssClass="form-check-input" Checked="true" />
              <label class="form-check-label fs--1">Active (available for categories and staff)</label>
            </div>
          </div>
          <div class="col-12 d-flex gap-2 border-top pt-3">
            <asp:Button ID="btnSave" runat="server" CssClass="btn btn-sm btn-primary" Text="Save Department"
              ValidationGroup="Dept" OnClick="btnSave_Click" />
            <asp:Button ID="btnCancel" runat="server" CssClass="btn btn-sm btn-falcon-default" Text="Cancel"
              CausesValidation="false" OnClick="btnCancel_Click" />
          </div>
        </div>
      </div>
    </asp:Panel>

    <div class="card mb-3">
      <div class="card-body py-2 d-flex flex-wrap gap-2 align-items-center">
        <span class="fs--1 text-600">Only the Admin can create and manage departments.</span>
        <asp:Button ID="btnAddNew" runat="server" CssClass="btn btn-sm btn-primary ms-auto"
          Text="+ Add Department" CausesValidation="false" OnClick="btnAddNew_Click" />
      </div>
    </div>

    <div class="card">
      <div class="table-responsive">
        <asp:GridView ID="gvDepartments" runat="server" CssClass="table table-sm table-hover align-middle mb-0"
          AutoGenerateColumns="False" GridLines="None" DataKeyNames="DepartmentID"
          EmptyDataText="No departments yet. Add one to get started." OnRowCommand="gvDepartments_RowCommand">
          <EmptyDataRowStyle CssClass="text-center text-600 py-4 fs--1" />
          <HeaderStyle CssClass="bg-light border-bottom" />
          <Columns>
            <asp:BoundField DataField="DepartmentName" HeaderText="Department"
              HeaderStyle-CssClass="ps-3 fw-medium" ItemStyle-CssClass="ps-3 fw-semibold" />
            <asp:BoundField DataField="Description" HeaderText="Description"
              HeaderStyle-CssClass="fw-medium" ItemStyle-CssClass="text-600" />
            <asp:BoundField DataField="CategoryCount" HeaderText="Categories"
              HeaderStyle-CssClass="text-center fw-medium" ItemStyle-CssClass="text-center text-600" />
            <asp:BoundField DataField="UserCount" HeaderText="Staff"
              HeaderStyle-CssClass="text-center fw-medium" ItemStyle-CssClass="text-center text-600" />
            <asp:TemplateField HeaderText="Status" HeaderStyle-CssClass="text-center fw-medium" ItemStyle-CssClass="text-center">
              <ItemTemplate>
                <span class='badge <%# (bool)Eval("IsActive") ? "badge-subtle-success" : "badge-subtle-secondary" %>'>
                  <%# (bool)Eval("IsActive") ? "Active" : "Inactive" %>
                </span>
              </ItemTemplate>
            </asp:TemplateField>
            <asp:TemplateField HeaderText="Actions" HeaderStyle-CssClass="text-end fw-medium pe-3" ItemStyle-CssClass="text-end pe-3">
              <ItemTemplate>
                <div class="d-inline-flex gap-1">
                  <asp:LinkButton runat="server" CommandName="EditDept" CommandArgument='<%# Eval("DepartmentID") %>'
                    CausesValidation="false" CssClass="btn btn-sm btn-falcon-default px-2 py-0 fs--2" ToolTip="Edit">
                    <span class="fas fa-edit"></span>
                  </asp:LinkButton>
                  <asp:LinkButton runat="server" CommandName="ToggleDept" CommandArgument='<%# Eval("DepartmentID") %>'
                    CausesValidation="false"
                    CssClass='<%# "btn btn-sm px-2 py-0 fs--2 " + ((bool)Eval("IsActive") ? "btn-falcon-warning" : "btn-falcon-success") %>'>
                    <%# (bool)Eval("IsActive") ? "Deactivate" : "Activate" %>
                  </asp:LinkButton>
                  <asp:LinkButton runat="server" CommandName="DeleteDept" CommandArgument='<%# Eval("DepartmentID") %>'
                    CausesValidation="false" CssClass="btn btn-sm btn-falcon-danger px-2 py-0 fs--2" ToolTip="Delete"
                    OnClientClick="return confirm('Delete this department? This cannot be undone.');">
                    <span class="fas fa-trash-alt"></span>
                  </asp:LinkButton>
                </div>
              </ItemTemplate>
            </asp:TemplateField>
          </Columns>
        </asp:GridView>
      </div>
    </div>

  </ContentTemplate></asp:UpdatePanel>

</asp:Content>
