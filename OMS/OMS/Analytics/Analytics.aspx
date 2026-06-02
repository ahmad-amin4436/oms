<%@ Page Title="Analytics" Language="C#" MasterPageFile="~/Site.Master" AutoEventWireup="true"
   CodeBehind="Analytics.aspx.cs" Inherits="OMS.Analytics.Analytics" %>

<asp:Content ID="Content1" ContentPlaceHolderID="MainContent" runat="server">

  <%-- ── Page header ── --%>
  <div class="d-flex flex-wrap align-items-center justify-content-between gap-2 mb-3">
    <div>
      <h4 class="mb-0">Analytics</h4>
      <p class="text-600 fs--1 mb-0">Sales, orders, and menu performance for the selected period.</p>
    </div>
    <span class="badge badge-subtle-secondary fs--2">
      <span class="fas fa-calendar-alt me-1"></span><asp:Literal ID="litRangeLabel" runat="server" />
    </span>
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
      <div class="col-auto d-flex gap-1">
        <asp:LinkButton ID="lb7" runat="server" CssClass="btn btn-falcon-default btn-sm"
          OnClick="lbPreset_Click" CommandArgument="7">7d</asp:LinkButton>
        <asp:LinkButton ID="lb30" runat="server" CssClass="btn btn-falcon-default btn-sm"
          OnClick="lbPreset_Click" CommandArgument="30">30d</asp:LinkButton>
        <asp:LinkButton ID="lb90" runat="server" CssClass="btn btn-falcon-default btn-sm"
          OnClick="lbPreset_Click" CommandArgument="90">90d</asp:LinkButton>
      </div>
    </div>
  </div>

  <%-- ── KPI summary cards ── --%>
  <div class="row g-3 mb-1">
    <div class="col-sm-6 col-xl-3">
      <div class="card h-100">
        <div class="card-body">
          <h6 class="text-600 fs--2 text-uppercase mb-2">Total Revenue</h6>
          <div class="d-flex align-items-end justify-content-between">
            <h4 class="mb-0 text-primary"><asp:Literal ID="litRevenue" runat="server" Text="Rs. 0" /></h4>
            <asp:Literal ID="litRevenueDelta" runat="server" />
          </div>
          <p class="fs--2 text-600 mb-0 mt-1">Gross, all orders</p>
        </div>
      </div>
    </div>
    <div class="col-sm-6 col-xl-3">
      <div class="card h-100">
        <div class="card-body">
          <h6 class="text-600 fs--2 text-uppercase mb-2">Total Orders</h6>
          <div class="d-flex align-items-end justify-content-between">
            <h4 class="mb-0"><asp:Literal ID="litOrders" runat="server" Text="0" /></h4>
            <asp:Literal ID="litOrdersDelta" runat="server" />
          </div>
          <p class="fs--2 text-600 mb-0 mt-1">All statuses</p>
        </div>
      </div>
    </div>
    <div class="col-sm-6 col-xl-3">
      <div class="card h-100">
        <div class="card-body">
          <h6 class="text-600 fs--2 text-uppercase mb-2">Avg Order Value</h6>
          <h4 class="mb-0"><asp:Literal ID="litAov" runat="server" Text="Rs. 0" /></h4>
          <p class="fs--2 text-600 mb-0 mt-1">Per order</p>
        </div>
      </div>
    </div>
    <div class="col-sm-6 col-xl-3">
      <div class="card h-100">
        <div class="card-body">
          <h6 class="text-600 fs--2 text-uppercase mb-2">Completed / Active</h6>
          <h4 class="mb-0">
            <span class="text-success"><asp:Literal ID="litCompleted" runat="server" Text="0" /></span>
            <span class="text-400 fs-0">/</span>
            <span class="text-warning"><asp:Literal ID="litActive" runat="server" Text="0" /></span>
          </h4>
          <p class="fs--2 text-600 mb-0 mt-1">Delivered vs in-progress orders</p>
        </div>
      </div>
    </div>
  </div>

  <div class="row g-3 mt-0">

    <%-- ── Revenue trend (line chart) ── --%>
    <div class="col-lg-8">
      <div class="card h-100">
        <div class="card-header py-2 border-bottom">
          <h5 class="mb-0 fs-0">Revenue Trend</h5>
        </div>
        <div class="card-body">
          <canvas id="revenueChart" height="110"></canvas>
        </div>
      </div>
    </div>

    <%-- ── Payment mix (doughnut) ── --%>
    <div class="col-lg-4">
      <div class="card h-100">
        <div class="card-header py-2 border-bottom">
          <h5 class="mb-0 fs-0">Payment Mix</h5>
        </div>
        <div class="card-body d-flex align-items-center justify-content-center">
          <canvas id="paymentChart" height="200"></canvas>
        </div>
      </div>
    </div>

    <%-- ── Top items (bar chart) ── --%>
    <div class="col-lg-7">
      <div class="card h-100">
        <div class="card-header py-2 border-bottom">
          <h5 class="mb-0 fs-0">Top Selling Items</h5>
        </div>
        <div class="card-body">
          <canvas id="topItemsChart" height="220"></canvas>
        </div>
      </div>
    </div>

    <%-- ── Top items table ── --%>
    <div class="col-lg-5">
      <div class="card h-100">
        <div class="card-header py-2 border-bottom">
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
                HeaderStyle-CssClass="ps-3 fw-medium" ItemStyle-CssClass="ps-3" />
              <asp:BoundField DataField="OrderCount" HeaderText="Sold"
                HeaderStyle-CssClass="text-center fw-medium" ItemStyle-CssClass="text-center fw-semibold" />
              <asp:BoundField DataField="Revenue" HeaderText="Revenue"
                DataFormatString="Rs.&#160;{0:N0}"
                HeaderStyle-CssClass="text-end pe-3 fw-medium" ItemStyle-CssClass="text-end pe-3 text-primary" />
            </Columns>
          </asp:GridView>
        </div>
      </div>
    </div>

    <%-- ── Revenue by day table ── --%>
    <div class="col-lg-8">
      <div class="card">
        <div class="card-header py-2 border-bottom">
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
                HeaderStyle-CssClass="ps-3 fw-medium" ItemStyle-CssClass="ps-3" />
              <asp:BoundField DataField="OrderCount" HeaderText="Orders"
                HeaderStyle-CssClass="text-center fw-medium" ItemStyle-CssClass="text-center fw-semibold" />
              <asp:BoundField DataField="Revenue" HeaderText="Revenue"
                DataFormatString="Rs.&#160;{0:N0}"
                HeaderStyle-CssClass="text-end pe-3 fw-medium" ItemStyle-CssClass="text-end pe-3 fw-semibold text-primary" />
            </Columns>
          </asp:GridView>
        </div>
      </div>
    </div>

    <%-- ── Orders by hour table ── --%>
    <div class="col-lg-4">
      <div class="card">
        <div class="card-header py-2 border-bottom">
          <h5 class="mb-0 fs-0">Orders by Hour</h5>
          <span class="fs--2 text-600">Across the selected range</span>
        </div>
        <div class="table-responsive" style="max-height:360px;overflow-y:auto;">
          <asp:GridView ID="gvHourly" runat="server"
            CssClass="table table-sm table-hover align-middle mb-0"
            AutoGenerateColumns="False" GridLines="None"
            EmptyDataText="No orders placed today.">
            <EmptyDataRowStyle CssClass="text-center text-600 py-4 fs--1" />
            <HeaderStyle CssClass="bg-light border-bottom" />
            <Columns>
              <asp:BoundField DataField="HourLabel" HeaderText="Hour"
                HeaderStyle-CssClass="ps-3 fw-medium" ItemStyle-CssClass="ps-3 text-600" />
              <asp:BoundField DataField="OrderCount" HeaderText="Orders"
                HeaderStyle-CssClass="text-center fw-medium" ItemStyle-CssClass="text-center fw-semibold" />
              <asp:BoundField DataField="Revenue" HeaderText="Revenue"
                DataFormatString="Rs.&#160;{0:N0}"
                HeaderStyle-CssClass="text-end pe-3 fw-medium" ItemStyle-CssClass="text-end pe-3" />
            </Columns>
          </asp:GridView>
        </div>
      </div>
    </div>

  </div>

  <%-- ── Chart.js (bundled with the Falcon theme) ── --%>
  <script src="<%= ResolveUrl("~/vendors/chart/chart.min.js") %>"></script>
  <script>
    (function () {
      // Live data injected from the code-behind for the selected range.
      var revenue  = <%= RevenueChartJson %>;   // { labels:[], data:[] }
      var payments = <%= PaymentChartJson %>;    // { labels:[], data:[] }
      var topItems = <%= TopItemsChartJson %>;   // { labels:[], data:[] }

      var moneyTick = function (v) { return 'Rs. ' + Number(v).toLocaleString(); };
      var palette = ['#2c7be5', '#27bcfd', '#00d27a', '#f5803e', '#e63757', '#a16eff', '#d8e2ef'];

      function make(id, cfg) {
        var el = document.getElementById(id);
        if (el && window.Chart) new Chart(el.getContext('2d'), cfg);
      }

      make('revenueChart', {
        type: 'line',
        data: {
          labels: revenue.labels,
          datasets: [{
            label: 'Revenue', data: revenue.data,
            borderColor: '#2c7be5', backgroundColor: 'rgba(44,123,229,.12)',
            fill: true, tension: 0.3, pointRadius: 2, borderWidth: 2
          }]
        },
        options: {
          responsive: true, maintainAspectRatio: false,
          plugins: { legend: { display: false },
            tooltip: { callbacks: { label: function (c) { return moneyTick(c.parsed.y); } } } },
          scales: { y: { beginAtZero: true, ticks: { callback: moneyTick } } }
        }
      });

      make('paymentChart', {
        type: 'doughnut',
        data: {
          labels: payments.labels,
          datasets: [{ data: payments.data, backgroundColor: palette, borderWidth: 1 }]
        },
        options: {
          responsive: true, maintainAspectRatio: false,
          plugins: { legend: { position: 'bottom', labels: { boxWidth: 12, font: { size: 11 } } },
            tooltip: { callbacks: { label: function (c) { return c.label + ': ' + moneyTick(c.parsed); } } } },
          cutout: '62%'
        }
      });

      make('topItemsChart', {
        type: 'bar',
        data: {
          labels: topItems.labels,
          datasets: [{ label: 'Units sold', data: topItems.data, backgroundColor: '#2c7be5', borderRadius: 4 }]
        },
        options: {
          indexAxis: 'y', responsive: true, maintainAspectRatio: false,
          plugins: { legend: { display: false } },
          scales: { x: { beginAtZero: true, ticks: { precision: 0 } } }
        }
      });
    })();
  </script>

</asp:Content>
