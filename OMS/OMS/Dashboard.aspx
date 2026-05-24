<%@ Page Title="Dashboard" Language="C#" MasterPageFile="~/Site.Master" AutoEventWireup="true" CodeBehind="Dashboard.aspx.cs" Inherits="OMS.Dashboard" %>

<asp:Content ID="DashboardContent" ContentPlaceHolderID="MainContent" runat="server">
  <asp:UpdatePanel ID="updDashboard" runat="server">
    <ContentTemplate>
      <asp:Timer ID="tmrDashboard" runat="server" Interval="60000" OnTick="tmrDashboard_Tick" />
      <div class="rms-page-header">
        <div>
          <h3 class="mb-0">Dashboard</h3>
          <p class="mb-0 text-600">Live overview for orders, revenue, kitchen, and menu performance.</p>
        </div>
        <span class="badge badge-subtle-primary">Auto-refresh: 60s</span>
      </div>

      <div class="row g-3 mb-3">
        <div class="col-sm-6 col-xl-3">
          <div class="card h-100">
            <div class="card-body">
              <div class="d-flex justify-content-between">
                <div>
                  <h6 class="text-600">Today's Orders</h6>
                  <h3><asp:Label ID="lblTodayOrders" runat="server" Text="0" /></h3>
                  <span class="badge badge-subtle-info"><asp:Label ID="lblOrderChange" runat="server" Text="0%" /></span>
                </div>
                <span class="rms-kpi-icon bg-primary-subtle text-primary"><span class="fas fa-receipt"></span></span>
              </div>
            </div>
          </div>
        </div>
        <div class="col-sm-6 col-xl-3">
          <div class="card h-100">
            <div class="card-body">
              <h6 class="text-600">Today's Revenue</h6>
              <h3 class="rms-money">Rs. <asp:Label ID="lblRevenue" runat="server" Text="0.00" /></h3>
            </div>
          </div>
        </div>
        <div class="col-sm-6 col-xl-3">
          <div class="card h-100">
            <div class="card-body">
              <h6 class="text-600">Pending Orders</h6>
              <h3><asp:Label ID="lblPendingOrders" runat="server" Text="0" /></h3>
              <span class="badge badge-subtle-warning">Needs action</span>
            </div>
          </div>
        </div>
        <div class="col-sm-6 col-xl-3">
          <div class="card h-100">
            <div class="card-body">
              <h6 class="text-600">Most Popular Item</h6>
              <h5 class="mb-1"><asp:Label ID="lblPopularItem" runat="server" Text="No sales yet" /></h5>
              <span class="badge badge-subtle-success"><asp:Label ID="lblPopularCount" runat="server" Text="0" /> sold</span>
            </div>
          </div>
        </div>
      </div>

      <div class="row g-3">
        <div class="col-lg-8">
          <div class="card rms-card-table">
            <div class="card-header">
              <h5 class="mb-0">Recent Orders</h5>
            </div>
            <div class="table-responsive">
              <asp:GridView ID="gvRecentOrders" runat="server" CssClass="table table-sm table-hover align-middle" AutoGenerateColumns="False" GridLines="None" EmptyDataText="No recent orders yet.">
                <Columns>
                  <asp:BoundField DataField="OrderNumber" HeaderText="Order #" />
                  <asp:BoundField DataField="CustomerName" HeaderText="Customer" />
                  <asp:BoundField DataField="OrderType" HeaderText="Type" />
                  <asp:BoundField DataField="TotalAmount" HeaderText="Total" DataFormatString="Rs. {0:N2}" />
                  <asp:TemplateField HeaderText="Status">
                    <ItemTemplate>
                      <span class='badge rounded-pill <%# OMS.Common.Helpers.UiHelper.StatusBadgeClass(Eval("Status").ToString()) %>'><%# Eval("Status") %></span>
                    </ItemTemplate>
                  </asp:TemplateField>
                  <asp:HyperLinkField Text="View" DataNavigateUrlFields="OrderID" DataNavigateUrlFormatString="Orders/OrderDetail.aspx?id={0}" ControlStyle-CssClass="btn btn-sm btn-falcon-default" />
                </Columns>
              </asp:GridView>
            </div>
          </div>
        </div>
        <div class="col-lg-4">
          <div class="card">
            <div class="card-header">
              <h5 class="mb-0">Unavailable Items</h5>
            </div>
            <div class="card-body">
              <asp:Repeater ID="rptUnavailable" runat="server">
                <ItemTemplate>
                  <div class="alert alert-warning py-2 mb-2"><%# Eval("Name") %></div>
                </ItemTemplate>
              </asp:Repeater>
              <asp:Panel ID="pnlNoUnavailable" runat="server" CssClass="text-600">All menu items are currently available.</asp:Panel>
            </div>
          </div>
        </div>
      </div>
    </ContentTemplate>
  </asp:UpdatePanel>
</asp:Content>
