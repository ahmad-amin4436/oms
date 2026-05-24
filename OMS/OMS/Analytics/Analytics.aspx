<%@ Page Title="Analytics" Language="C#" MasterPageFile="~/Site.Master" AutoEventWireup="true"
   CodeBehind="Analytics.aspx.cs" Inherits="OMS.Analytics.Analytics" %>

<asp:Content ID="Content1" ContentPlaceHolderID="MainContent" runat="server">

  <%-- ── Page header ── --%>
  <div class="d-flex align-items-center justify-content-between mb-3">
    <div>
      <h4 class="mb-0">Analytics</h4>
      <p class="text-600 fs--1 mb-0">Sales, orders, and menu performance.</p>
    </div>
  </div>

  <%-- ── Date range filter ── --%>
  <div class="card mb-3">
    <div class="card-body row g-2 align-items-end">
      <div class="col-sm-4 col-md-3">
        <label class="form-label fs--1 mb-1">From Date</label>
        <asp:TextBox ID="txtStart" runat="server" CssClass="form-control form-control-sm" TextMode="Date" />
      </div>
      <div class="col-sm-4 col-md-3">
        <label class="form-label fs--1 mb-1">To Date</label>
        <asp:TextBox ID="txtEnd" runat="server" CssClass="form-control form-control-sm" TextMode="Date" />
      </div>
      <div class="col-auto">
        <asp:Button ID="btnApply" runat="server" CssClass="btn btn-primary btn-sm"
          Text="Apply" OnClick="btnApply_Click" />
      </div>
    </div>
  </div>

  <div class="row g-3">

    <%-- ── Revenue by Day ── --%>
    <div class="col-lg-8">
      <div class="card">
        <div class="card-header py-2">
          <h5 class="mb-0 fs-0">Revenue by Day</h5>
        </div>
        <div class="table-responsive">
          <asp:GridView ID="gvRevenue" runat="server"
            CssClass="table table-sm table-hover align-middle mb-0"
            AutoGenerateColumns="False" GridLines="None"
            EmptyDataText="No sales data for this period.">
            <EmptyDataRowStyle CssClass="text-center text-600 py-4 fs--1" />
            <HeaderStyle CssClass="bg-light border-bottom" />
            <Columns>
              <asp:BoundField DataField="SaleDate" HeaderText="Date"
                DataFormatString="{0:dd MMM yyyy}"
                HeaderStyle-CssClass="ps-3 fw-medium"
                ItemStyle-CssClass="ps-3" />
              <asp:BoundField DataField="OrderCount" HeaderText="Orders"
                HeaderStyle-CssClass="text-center fw-medium"
                ItemStyle-CssClass="text-center fw-semibold" />
              <asp:BoundField DataField="Revenue" HeaderText="Revenue"
                DataFormatString="Rs.&#160;{0:N0}"
                HeaderStyle-CssClass="text-end pe-3 fw-medium"
                ItemStyle-CssClass="text-end pe-3 fw-semibold text-primary" />
            </Columns>
          </asp:GridView>
        </div>
      </div>
    </div>

    <%-- ── Top Menu Items ── --%>
    <div class="col-lg-4">
      <div class="card">
        <div class="card-header py-2">
          <h5 class="mb-0 fs-0">Top 10 Items</h5>
        </div>
        <div class="table-responsive">
          <asp:GridView ID="gvTopItems" runat="server"
            CssClass="table table-sm table-hover align-middle mb-0"
            AutoGenerateColumns="False" GridLines="None"
            EmptyDataText="No sales yet.">
            <EmptyDataRowStyle CssClass="text-center text-600 py-4 fs--1" />
            <HeaderStyle CssClass="bg-light border-bottom" />
            <Columns>
              <asp:BoundField DataField="ItemName" HeaderText="Item"
                HeaderStyle-CssClass="ps-3 fw-medium"
                ItemStyle-CssClass="ps-3" />
              <asp:BoundField DataField="OrderCount" HeaderText="Sold"
                HeaderStyle-CssClass="text-center fw-medium"
                ItemStyle-CssClass="text-center fw-semibold" />
              <asp:BoundField DataField="Revenue" HeaderText="Revenue"
                DataFormatString="Rs.&#160;{0:N0}"
                HeaderStyle-CssClass="text-end pe-3 fw-medium"
                ItemStyle-CssClass="text-end pe-3 text-primary" />
            </Columns>
          </asp:GridView>
        </div>
      </div>
    </div>

    <%-- ── Orders by Hour ── --%>
    <div class="col-12">
      <div class="card">
        <div class="card-header py-2">
          <h5 class="mb-0 fs-0">Orders by Hour (Today)</h5>
        </div>
        <div class="table-responsive">
          <asp:GridView ID="gvHourly" runat="server"
            CssClass="table table-sm table-hover align-middle mb-0"
            AutoGenerateColumns="False" GridLines="None"
            EmptyDataText="No orders placed today.">
            <EmptyDataRowStyle CssClass="text-center text-600 py-4 fs--1" />
            <HeaderStyle CssClass="bg-light border-bottom" />
            <Columns>
              <asp:BoundField DataField="HourLabel" HeaderText="Hour"
                HeaderStyle-CssClass="ps-3 fw-medium"
                ItemStyle-CssClass="ps-3 text-600" />
              <asp:BoundField DataField="OrderCount" HeaderText="Orders"
                HeaderStyle-CssClass="text-center fw-medium"
                ItemStyle-CssClass="text-center fw-semibold" />
              <asp:BoundField DataField="Revenue" HeaderText="Revenue"
                DataFormatString="Rs.&#160;{0:N0}"
                HeaderStyle-CssClass="text-end pe-3 fw-medium"
                ItemStyle-CssClass="text-end pe-3" />
            </Columns>
          </asp:GridView>
        </div>
      </div>
    </div>

  </div>

</asp:Content>
