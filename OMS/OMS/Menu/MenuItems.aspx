<%@ Page Title="Menu Items" Language="C#" MasterPageFile="~/Site.Master" AutoEventWireup="true" CodeBehind="MenuItems.aspx.cs" Inherits="OMS.Menu.MenuItems" %>
<asp:Content ID="Content1" ContentPlaceHolderID="MainContent" runat="server">
  <div class="rms-page-header"><div><h3 class="mb-0">Menu Items</h3><p class="mb-0 text-600">Manage item availability and pricing.</p></div></div>
  <div class="card rms-card-table"><div class="table-responsive">
    <asp:GridView ID="gvMenuItems" runat="server" CssClass="table table-sm table-hover" AutoGenerateColumns="False" GridLines="None">
      <Columns>
        <asp:BoundField DataField="Name" HeaderText="Name" />
        <asp:BoundField DataField="CategoryName" HeaderText="Category" />
        <asp:BoundField DataField="BasePrice" HeaderText="Base Price" DataFormatString="Rs. {0:N2}" />
        <asp:CheckBoxField DataField="IsAvailable" HeaderText="Available" />
        <asp:CheckBoxField DataField="IsFeatured" HeaderText="Featured" />
      </Columns>
    </asp:GridView>
  </div></div>
</asp:Content>
