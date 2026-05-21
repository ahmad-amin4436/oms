<%@ Page Title="Order Detail" Language="C#" MasterPageFile="~/Site.Master" AutoEventWireup="true" CodeBehind="OrderDetail.aspx.cs" Inherits="OMS.Orders.OrderDetail" %>
<asp:Content ID="Content1" ContentPlaceHolderID="MainContent" runat="server">
  <div class="rms-page-header">
    <div><h3 class="mb-0">Order Detail</h3><p class="mb-0 text-600"><asp:Label ID="lblOrderNumber" runat="server" /></p></div>
    <a class="btn btn-falcon-default" target="_blank" href='../Reports/PrintInvoice.aspx?id=<%= Request.QueryString["id"] %>'><span class="fas fa-print me-1"></span>Print Invoice</a>
  </div>
  <div class="row g-3">
    <div class="col-lg-8">
      <div class="card rms-card-table">
        <div class="card-header"><h5 class="mb-0">Items</h5></div>
        <asp:GridView ID="gvItems" runat="server" CssClass="table table-sm" AutoGenerateColumns="true" GridLines="None" />
      </div>
    </div>
    <div class="col-lg-4">
      <div class="card"><div class="card-body">
        <h5>Status</h5>
        <asp:DropDownList ID="ddlStatus" runat="server" CssClass="form-select mb-3" />
        <asp:Button ID="btnUpdateStatus" runat="server" CssClass="btn btn-primary w-100" Text="Update Status" OnClick="btnUpdateStatus_Click" />
      </div></div>
    </div>
  </div>
</asp:Content>
