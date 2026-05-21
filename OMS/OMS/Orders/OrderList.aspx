<%@ Page Title="All Orders" Language="C#" MasterPageFile="~/Site.Master" AutoEventWireup="true" CodeBehind="OrderList.aspx.cs" Inherits="OMS.Orders.OrderList" %>
<asp:Content ID="Content1" ContentPlaceHolderID="MainContent" runat="server">
  <div class="rms-page-header">
    <div><h3 class="mb-0">All Orders</h3><p class="mb-0 text-600">Filter, review, and update restaurant orders.</p></div>
    <a class="btn btn-primary" href="NewOrder.aspx"><span class="fas fa-plus me-1"></span>New Order</a>
  </div>
  <asp:UpdatePanel ID="updOrders" runat="server">
    <ContentTemplate>
      <div class="card mb-3">
        <div class="card-body row g-2">
          <div class="col-md-3"><asp:DropDownList ID="ddlStatus" runat="server" CssClass="form-select" AutoPostBack="true" OnSelectedIndexChanged="FiltersChanged" /></div>
          <div class="col-md-3"><asp:DropDownList ID="ddlOrderType" runat="server" CssClass="form-select" AutoPostBack="true" OnSelectedIndexChanged="FiltersChanged" /></div>
          <div class="col-md-3"><asp:TextBox ID="txtStartDate" runat="server" CssClass="form-control" TextMode="Date" AutoPostBack="true" OnTextChanged="FiltersChanged" /></div>
          <div class="col-md-3"><asp:TextBox ID="txtEndDate" runat="server" CssClass="form-control" TextMode="Date" AutoPostBack="true" OnTextChanged="FiltersChanged" /></div>
        </div>
      </div>
      <div class="card rms-card-table">
        <div class="table-responsive">
          <asp:GridView ID="gvOrders" runat="server" CssClass="table table-sm table-hover align-middle" AutoGenerateColumns="False" GridLines="None" EmptyDataText="No orders found.">
            <Columns>
              <asp:BoundField DataField="OrderNumber" HeaderText="Order #" />
              <asp:BoundField DataField="CustomerName" HeaderText="Customer" />
              <asp:BoundField DataField="OrderType" HeaderText="Type" />
              <asp:BoundField DataField="PaymentMethod" HeaderText="Payment" />
              <asp:BoundField DataField="TotalAmount" HeaderText="Total" DataFormatString="Rs. {0:N2}" />
              <asp:TemplateField HeaderText="Status"><ItemTemplate><span class='badge rounded-pill <%# OMS.App_Code.Helpers.UiHelper.StatusBadgeClass(Eval("Status").ToString()) %>'><%# Eval("Status") %></span></ItemTemplate></asp:TemplateField>
              <asp:HyperLinkField Text="View" DataNavigateUrlFields="OrderID" DataNavigateUrlFormatString="OrderDetail.aspx?id={0}" ControlStyle-CssClass="btn btn-sm btn-falcon-default" />
            </Columns>
          </asp:GridView>
        </div>
      </div>
    </ContentTemplate>
  </asp:UpdatePanel>
</asp:Content>
