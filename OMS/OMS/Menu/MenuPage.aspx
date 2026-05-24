<%@ Page Title="Public Menu" Language="C#" MasterPageFile="~/Site.Master" AutoEventWireup="true"
   CodeBehind="MenuPage.aspx.cs" Inherits="OMS.Menu.MenuPage" %>

<asp:Content ID="Content1" ContentPlaceHolderID="MainContent" runat="server">

  <div class="d-flex align-items-center justify-content-between mb-3">
    <div>
      <h4 class="mb-0">Menu</h4>
      <p class="text-600 fs--1 mb-0">Customer-facing menu.</p>
    </div>
  </div>

  <asp:Panel ID="pnlNoItems" runat="server" Visible="false"
    CssClass="alert alert-info fs--1">No menu items available.</asp:Panel>

  <div class="row g-3">
    <asp:Repeater ID="rptPublicMenu" runat="server">
      <ItemTemplate>
        <div class="col-sm-6 col-xl-4">
          <div class="card h-100">
            <div class="card-body d-flex flex-column">
              <h5 class="mb-1 fs-0"><%# Eval("Name") %></h5>
              <p class="text-600 fs--1 mb-auto"><%# Eval("Description") %></p>
              <div class="d-flex align-items-center justify-content-between mt-3">
                <strong class="text-primary">Rs.&#160;<%# Eval("BasePrice", "{0:N0}") %></strong>
                <a runat="server"
                   href='<%# "~/Orders/NewOrder.aspx" %>'
                   class="btn btn-sm btn-primary">Order Now</a>
              </div>
            </div>
          </div>
        </div>
      </ItemTemplate>
    </asp:Repeater>
  </div>

</asp:Content>
