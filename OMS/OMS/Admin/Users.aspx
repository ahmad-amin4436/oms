<%@ Page Title="Users" Language="C#" MasterPageFile="~/Site.Master" AutoEventWireup="true"
   CodeBehind="Users.aspx.cs" Inherits="OMS.Admin.Users" %>

<asp:Content ID="Content1" ContentPlaceHolderID="MainContent" runat="server">

  <%-- ── Page header ── --%>
  <div class="d-flex align-items-center justify-content-between mb-3">
    <div>
      <h4 class="mb-0">Users</h4>
      <p class="text-600 fs--1 mb-0">Manage staff accounts and roles.</p>
    </div>
  </div>

  <asp:UpdatePanel ID="updUsers" runat="server">
    <ContentTemplate>

      <asp:Label ID="lblMsg" runat="server" Visible="false"
        CssClass="alert alert-success d-block mb-3 py-2 fs--1"
        EnableViewState="false" />

      <div class="card">
        <div class="table-responsive">
          <asp:GridView ID="gvUsers" runat="server"
            CssClass="table table-sm table-hover align-middle mb-0"
            AutoGenerateColumns="False" GridLines="None"
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
              <asp:TemplateField
                HeaderStyle-CssClass="text-center fw-medium"
                ItemStyle-CssClass="text-center pe-3">
                <ItemTemplate>
                  <asp:LinkButton runat="server"
                    CommandName="Toggle"
                    CommandArgument='<%# Eval("UserID") %>'
                    CssClass='<%# "btn btn-sm px-2 py-0 fs--2 " + ((bool)Eval("IsActive") ? "btn-falcon-warning" : "btn-falcon-success") %>'>
                    <%# (bool)Eval("IsActive") ? "Deactivate" : "Activate" %>
                  </asp:LinkButton>
                </ItemTemplate>
              </asp:TemplateField>
            </Columns>
          </asp:GridView>
        </div>
      </div>

    </ContentTemplate>
  </asp:UpdatePanel>

</asp:Content>
