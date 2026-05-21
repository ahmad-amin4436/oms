<%@ Page Title="Public Menu" Language="C#" MasterPageFile="~/Site.Master" AutoEventWireup="true" CodeBehind="MenuPage.aspx.cs" Inherits="OMS.Menu.MenuPage" %>
<asp:Content ID="Content1" ContentPlaceHolderID="MainContent" runat="server">
  <div class="rms-page-header"><div><h3 class="mb-0">Menu</h3><p class="mb-0 text-600">Customer-facing menu.</p></div></div>
  <asp:Repeater ID="rptPublicMenu" runat="server">
    <HeaderTemplate><div class="row g-3"></HeaderTemplate>
    <ItemTemplate><div class="col-sm-6 col-xl-4"><div class="card h-100"><div class="card-body"><h5><%# Eval("Name") %></h5><p><%# Eval("Description") %></p><strong>Rs. <%# Eval("BasePrice", "{0:N2}") %></strong><a class="btn btn-sm btn-primary float-end" href="../Orders/NewOrder.aspx?item=<%# Eval("ItemID") %>">Order Now</a></div></div></div></ItemTemplate>
    <FooterTemplate></div></FooterTemplate>
  </asp:Repeater>
</asp:Content>
