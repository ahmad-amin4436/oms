<%@ Page Title="Menu Items" Language="C#" MasterPageFile="~/Site.Master" AutoEventWireup="true"
   CodeBehind="MenuItems.aspx.cs" Inherits="OMS.Menu.MenuItems" %>

<asp:Content ID="Content1" ContentPlaceHolderID="MainContent" runat="server">

  <%-- ── Page header ── --%>
  <div class="d-flex align-items-center justify-content-between mb-3">
    <div>
      <h4 class="mb-0">Menu Items</h4>
      <p class="text-600 fs--1 mb-0">Manage item availability, pricing, and details.</p>
    </div>
  </div>

  <asp:UpdatePanel ID="updMenu" runat="server">
    <ContentTemplate>

      <%-- ── Feedback ── --%>
      <asp:Label ID="lblMsg" runat="server" Visible="false"
        CssClass="alert alert-success d-block mb-3 py-2 fs--1"
        EnableViewState="false" />

      <%-- ── Category filter tabs ── --%>
      <div class="card mb-3">
        <div class="card-body py-2 d-flex flex-wrap gap-2 align-items-center">
          <asp:LinkButton ID="lbAllCat" runat="server" CssClass="btn btn-sm btn-falcon-default"
            OnClick="lbAllCat_Click">All Categories</asp:LinkButton>
          <asp:Repeater ID="rptCatTabs" runat="server" OnItemCommand="rptCatTabs_ItemCommand">
            <ItemTemplate>
              <asp:LinkButton runat="server" CssClass='<%# GetCatBtnCss((int)Eval("CategoryID")) %>'
                CommandName="Filter" CommandArgument='<%# Eval("CategoryID") %>'>
                <%# Eval("CategoryName") %>
              </asp:LinkButton>
            </ItemTemplate>
          </asp:Repeater>
        </div>
      </div>

      <%-- ── Items table ── --%>
      <div class="card">
        <div class="table-responsive">
          <asp:GridView ID="gvMenuItems" runat="server"
            CssClass="table table-sm table-hover align-middle mb-0"
            AutoGenerateColumns="False" GridLines="None"
            EmptyDataText="No items found."
            OnRowCommand="gvMenuItems_RowCommand">
            <EmptyDataRowStyle CssClass="text-center text-600 py-4 fs--1" />
            <HeaderStyle CssClass="bg-light border-bottom" />
            <Columns>
              <asp:BoundField DataField="Name" HeaderText="Item"
                HeaderStyle-CssClass="ps-3 fw-medium"
                ItemStyle-CssClass="ps-3 fw-semibold" />
              <asp:BoundField DataField="CategoryName" HeaderText="Category"
                HeaderStyle-CssClass="fw-medium"
                ItemStyle-CssClass="text-600" />
              <asp:BoundField DataField="BasePrice" HeaderText="Base Price"
                DataFormatString="Rs.&#160;{0:N0}"
                HeaderStyle-CssClass="text-end fw-medium"
                ItemStyle-CssClass="text-end" />
              <asp:TemplateField HeaderText="Available"
                HeaderStyle-CssClass="text-center fw-medium"
                ItemStyle-CssClass="text-center">
                <ItemTemplate>
                  <span class='badge <%# (bool)Eval("IsAvailable") ? "badge-subtle-success" : "badge-subtle-danger" %>'>
                    <%# (bool)Eval("IsAvailable") ? "Yes" : "No" %>
                  </span>
                </ItemTemplate>
              </asp:TemplateField>
              <asp:TemplateField HeaderText="Featured"
                HeaderStyle-CssClass="text-center fw-medium"
                ItemStyle-CssClass="text-center">
                <ItemTemplate>
                  <span class='badge <%# (bool)Eval("IsFeatured") ? "badge-subtle-primary" : "badge-subtle-secondary" %>'>
                    <%# (bool)Eval("IsFeatured") ? "Yes" : "—" %>
                  </span>
                </ItemTemplate>
              </asp:TemplateField>
              <asp:TemplateField
                HeaderStyle-CssClass="text-center fw-medium"
                ItemStyle-CssClass="text-center pe-3">
                <ItemTemplate>
                  <asp:LinkButton runat="server"
                    CommandName="Toggle"
                    CommandArgument='<%# Eval("ItemID") %>'
                    CssClass='<%# "btn btn-sm px-2 py-0 fs--2 " + ((bool)Eval("IsAvailable") ? "btn-falcon-warning" : "btn-falcon-success") %>'
                    OnClientClick="return true;">
                    <%# (bool)Eval("IsAvailable") ? "Mark Unavailable" : "Mark Available" %>
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
