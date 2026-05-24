<%@ Page Title="All Orders" Language="C#" MasterPageFile="~/Site.Master" AutoEventWireup="true"
   CodeBehind="OrderList.aspx.cs" Inherits="OMS.Orders.OrderList" %>

<asp:Content ID="Content1" ContentPlaceHolderID="MainContent" runat="server">

  <%-- ── Page header ── --%>
  <div class="d-flex align-items-center justify-content-between mb-3">
    <div>
      <h4 class="mb-0">All Orders</h4>
      <p class="text-600 fs--1 mb-0">Filter, review, and update restaurant orders.</p>
    </div>
    <a runat="server" href="~/Orders/NewOrder.aspx" class="btn btn-primary btn-sm">
      + New Order
    </a>
  </div>

  <asp:UpdatePanel ID="updOrders" runat="server">
    <ContentTemplate>

      <%-- ── Filters ── --%>
      <div class="card mb-3">
        <div class="card-body row g-2 align-items-end">
          <div class="col-sm-6 col-md-3">
            <label class="form-label fs--1 mb-1">Status</label>
            <asp:DropDownList ID="ddlStatus" runat="server" CssClass="form-select form-select-sm"
              AutoPostBack="true" OnSelectedIndexChanged="FiltersChanged" />
          </div>
          <div class="col-sm-6 col-md-3">
            <label class="form-label fs--1 mb-1">Order Type</label>
            <asp:DropDownList ID="ddlOrderType" runat="server" CssClass="form-select form-select-sm"
              AutoPostBack="true" OnSelectedIndexChanged="FiltersChanged" />
          </div>
          <div class="col-sm-6 col-md-3">
            <label class="form-label fs--1 mb-1">From Date</label>
            <asp:TextBox ID="txtStartDate" runat="server" CssClass="form-control form-control-sm"
              TextMode="Date" AutoPostBack="true" OnTextChanged="FiltersChanged" />
          </div>
          <div class="col-sm-6 col-md-3">
            <label class="form-label fs--1 mb-1">To Date</label>
            <asp:TextBox ID="txtEndDate" runat="server" CssClass="form-control form-control-sm"
              TextMode="Date" AutoPostBack="true" OnTextChanged="FiltersChanged" />
          </div>
        </div>
      </div>

      <%-- ── Orders table ── --%>
      <div class="card mb-3">
        <div class="card-header">
          <div class="row flex-between-center">
            <div class="col-4 col-sm-auto d-flex align-items-center pe-0">
              <h5 class="fs-0 mb-0 text-nowrap py-2 py-xl-0">Orders</h5>
            </div>
          </div>
        </div>
        <div class="card-body p-0">
          <div class="table-responsive scrollbar">
            <asp:GridView ID="gvOrders" runat="server"
              CssClass="table table-sm table-striped fs--1 mb-0 overflow-hidden align-middle"
              AutoGenerateColumns="False" GridLines="None"
              EmptyDataText="No orders found.">
              <EmptyDataRowStyle CssClass="text-center text-600 py-4 fs--1" />
              <HeaderStyle CssClass="bg-200 text-900" />
              <Columns>
                <asp:TemplateField HeaderText="Order"
                  HeaderStyle-CssClass="ps-3 align-middle white-space-nowrap"
                  ItemStyle-CssClass="ps-3 py-2 align-middle white-space-nowrap">
                  <ItemTemplate>
                    <strong class="text-primary"><%# Eval("OrderNumber") %></strong>
                    <span class="text-600"> by </span>
                    <strong><%# OMS.Common.Helpers.UiHelper.HtmlEncode(Eval("CustomerName")) %></strong>
                  </ItemTemplate>
                </asp:TemplateField>
                <asp:TemplateField HeaderText="Date"
                  HeaderStyle-CssClass="align-middle white-space-nowrap"
                  ItemStyle-CssClass="py-2 align-middle white-space-nowrap text-600">
                  <ItemTemplate>
                    <%# Eval("CreatedAt", "{0:dd MMM yyyy, hh:mm tt}") %>
                  </ItemTemplate>
                </asp:TemplateField>
                <asp:BoundField DataField="OrderType" HeaderText="Type"
                  HeaderStyle-CssClass="align-middle"
                  ItemStyle-CssClass="py-2 align-middle" />
                <asp:BoundField DataField="PaymentMethod" HeaderText="Payment"
                  HeaderStyle-CssClass="align-middle"
                  ItemStyle-CssClass="py-2 align-middle" />
                <asp:TemplateField HeaderText="Status"
                  HeaderStyle-CssClass="text-center align-middle white-space-nowrap"
                  ItemStyle-CssClass="text-center py-2 align-middle fs-0 white-space-nowrap">
                  <ItemTemplate>
                    <span class='badge rounded-pill d-block <%# OMS.Common.Helpers.UiHelper.StatusBadgeClass(Eval("Status").ToString()) %>'>
                      <%# Eval("Status") %><span class='ms-1 <%# OMS.Common.Helpers.UiHelper.StatusBadgeIcon(Eval("Status").ToString()) %>' data-fa-transform="shrink-2"></span>
                    </span>
                  </ItemTemplate>
                </asp:TemplateField>
                <asp:TemplateField HeaderText="Amount"
                  HeaderStyle-CssClass="text-end align-middle white-space-nowrap"
                  ItemStyle-CssClass="text-end py-2 align-middle fs-0 fw-medium white-space-nowrap">
                  <ItemTemplate>
                    <%# Eval("TotalAmount", "Rs. {0:N0}") %>
                  </ItemTemplate>
                </asp:TemplateField>
                <asp:TemplateField
                  HeaderStyle-CssClass="text-end pe-3 align-middle"
                  ItemStyle-CssClass="text-end pe-3 py-2 align-middle white-space-nowrap">
                  <ItemTemplate>
                    <asp:HyperLink runat="server"
                      NavigateUrl='<%# "~/Orders/OrderDetail.aspx?id=" + Eval("OrderID") %>'
                      CssClass="btn btn-sm btn-falcon-default px-2 py-0 fs--2">View</asp:HyperLink>
                  </ItemTemplate>
                </asp:TemplateField>
              </Columns>
            </asp:GridView>
          </div>
        </div>
      </div>

    </ContentTemplate>
  </asp:UpdatePanel>

</asp:Content>
