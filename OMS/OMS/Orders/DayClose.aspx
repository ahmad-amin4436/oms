<%@ Page Title="Day Close" Language="C#" MasterPageFile="~/Site.Master" AutoEventWireup="true"
   CodeBehind="DayClose.aspx.cs" Inherits="OMS.Orders.DayClose" %>

<asp:Content ID="Content1" ContentPlaceHolderID="MainContent" runat="server">
  <%-- Partial-page updates: actions refresh this panel only, never the whole page. --%>
  <asp:UpdatePanel ID="updDayClose" runat="server" UpdateMode="Always"><ContentTemplate>

  <div class="d-flex align-items-center justify-content-between mb-3">
    <div>
      <h4 class="mb-0">Day Close</h4>
      <p class="text-600 fs--1 mb-0">Finalize the business day so the next day's sales start from zero.</p>
    </div>
    <a runat="server" href="~/Orders/OrderList.aspx" class="btn btn-falcon-default btn-sm">All Orders</a>
  </div>

  <asp:Label ID="lblMsg" runat="server" Visible="false" EnableViewState="false"
    CssClass="alert alert-success d-block mb-3" />
  <asp:Label ID="lblError" runat="server" Visible="false" EnableViewState="false"
    CssClass="alert alert-danger d-block mb-3" />

  <%-- No day open: the next order starts one automatically --%>
  <asp:Panel ID="pnlNoOpen" runat="server" Visible="false" CssClass="alert alert-info mb-3">
    There is no open business day. A new business day starts automatically with the next order.
  </asp:Panel>

  <asp:Panel ID="pnlOpen" runat="server" Visible="false">

    <div class="card mb-3">
      <div class="card-header py-2 d-flex justify-content-between align-items-center">
        <h5 class="mb-0 fs-0">Current business day: <asp:Label ID="lblDay" runat="server" /></h5>
        <span class="fs--1 text-600"><asp:Label ID="lblOpened" runat="server" /></span>
      </div>
      <div class="card-body">
        <div class="row g-3">
          <div class="col-6 col-md-3">
            <div class="fs--2 text-600 text-uppercase">Sales (paid)</div>
            <div class="fs-1 fw-bold text-primary"><asp:Label ID="lblSales" runat="server" /></div>
          </div>
          <div class="col-6 col-md-3">
            <div class="fs--2 text-600 text-uppercase">Orders</div>
            <div class="fs-1 fw-bold"><asp:Label ID="lblOrders" runat="server" /></div>
            <div class="fs--2 text-600"><asp:Label ID="lblPaidCount" runat="server" /> paid</div>
          </div>
          <div class="col-6 col-md-3">
            <div class="fs--2 text-600 text-uppercase">Pending (unpaid)</div>
            <div class="fs-1 fw-bold text-warning"><asp:Label ID="lblPending" runat="server" /></div>
          </div>
          <div class="col-6 col-md-3">
            <div class="fs--2 text-600 text-uppercase">Cancelled</div>
            <div class="fs-1 fw-bold text-danger"><asp:Label ID="lblCancelled" runat="server" /></div>
            <div class="fs--2 text-600"><asp:Label ID="lblCancelledAmt" runat="server" /></div>
          </div>
        </div>
        <hr class="my-3" />
        <div class="row g-3 fs--1">
          <div class="col-4"><span class="text-600">Subtotal</span><br /><asp:Label ID="lblSubtotal" runat="server" /></div>
          <div class="col-4"><span class="text-600">Discounts</span><br /><asp:Label ID="lblDiscount" runat="server" /></div>
          <div class="col-4"><span class="text-600">Tax</span><br /><asp:Label ID="lblTax" runat="server" /></div>
        </div>
      </div>
    </div>

    <div class="row g-3 mb-3">
      <div class="col-md-6">
        <div class="card h-100">
          <div class="card-header py-2"><h5 class="mb-0 fs-0">By payment method</h5></div>
          <div class="card-body p-0">
            <asp:Repeater ID="rptPayments" runat="server">
              <HeaderTemplate><table class="table table-sm fs--1 mb-0"><thead class="bg-200"><tr><th class="ps-3">Method</th><th class="text-end">Orders</th><th class="text-end pe-3">Amount</th></tr></thead><tbody></HeaderTemplate>
              <ItemTemplate>
                <tr><td class="ps-3"><%# Server.HtmlEncode(Convert.ToString(Eval("PaymentMethod"))) %></td>
                    <td class="text-end"><%# Eval("Orders") %></td>
                    <td class="text-end pe-3">Rs. <%# string.Format("{0:N0}", Eval("Amount")) %></td></tr>
              </ItemTemplate>
              <FooterTemplate></tbody></table></FooterTemplate>
            </asp:Repeater>
            <asp:Label ID="lblNoPayments" runat="server" Visible="false" CssClass="d-block text-600 fs--1 p-3" Text="No paid orders yet." />
          </div>
        </div>
      </div>
      <div class="col-md-6">
        <div class="card h-100">
          <div class="card-header py-2"><h5 class="mb-0 fs-0">By order taker</h5></div>
          <div class="card-body p-0">
            <asp:Repeater ID="rptTakers" runat="server">
              <HeaderTemplate><table class="table table-sm fs--1 mb-0"><thead class="bg-200"><tr><th class="ps-3">Order taker</th><th class="text-end">Orders</th><th class="text-end pe-3">Sales</th></tr></thead><tbody></HeaderTemplate>
              <ItemTemplate>
                <tr><td class="ps-3"><%# Server.HtmlEncode(Convert.ToString(Eval("OrderTaker"))) %></td>
                    <td class="text-end"><%# Eval("Orders") %></td>
                    <td class="text-end pe-3">Rs. <%# string.Format("{0:N0}", Eval("Sales")) %></td></tr>
              </ItemTemplate>
              <FooterTemplate></tbody></table></FooterTemplate>
            </asp:Repeater>
            <asp:Label ID="lblNoTakers" runat="server" Visible="false" CssClass="d-block text-600 fs--1 p-3" Text="No paid orders yet." />
          </div>
        </div>
      </div>
    </div>

    <%-- Close --%>
    <div class="card mb-3 border border-danger">
      <div class="card-body">
        <asp:Panel ID="pnlBlocked" runat="server" Visible="false" CssClass="alert alert-warning py-2 fs--1">
          <asp:Label ID="lblBlocked" runat="server" />
          <a runat="server" href="~/Orders/OrderList.aspx" class="alert-link">Open the order list</a> to confirm or cancel them.
        </asp:Panel>
        <asp:Button ID="btnClose" runat="server" Text="Close Business Day" CssClass="btn btn-danger"
          UseSubmitBehavior="false" OnClick="btnClose_Click"
          OnClientClick="if (!confirm('Are you sure you want to close today\'s business day? This action will finalize today\'s sales.')) return false; this.disabled = true; this.value = 'Closing...'; __doPostBack(this.name, ''); return false;" />
        <p class="fs--2 text-600 mb-0 mt-2">Closing finalizes today's sales. The next order you take starts a new business day.</p>
      </div>
    </div>
  </asp:Panel>

  <%-- Closed days stay available here and in the reports --%>
  <div class="card mb-3">
    <div class="card-header py-2"><h5 class="mb-0 fs-0">Closed business days</h5></div>
    <div class="card-body p-0">
      <asp:GridView ID="gvDays" runat="server" AutoGenerateColumns="False" GridLines="None"
        CssClass="table table-sm table-striped fs--1 mb-0 align-middle" EmptyDataText="No closed business days yet.">
        <EmptyDataRowStyle CssClass="text-center text-600 py-3 fs--1" />
        <HeaderStyle CssClass="bg-200 text-900" />
        <Columns>
          <asp:BoundField DataField="BusinessDate" HeaderText="Business day" DataFormatString="{0:dd MMM yyyy}"
            HeaderStyle-CssClass="ps-3" ItemStyle-CssClass="ps-3 fw-semi-bold" />
          <asp:BoundField DataField="OpenedAt" HeaderText="Opened" DataFormatString="{0:dd MMM, hh:mm tt}" />
          <asp:BoundField DataField="ClosedAt" HeaderText="Closed" DataFormatString="{0:dd MMM, hh:mm tt}" />
          <asp:BoundField DataField="ClosedByName" HeaderText="Closed by" NullDisplayText="&mdash;" />
          <asp:BoundField DataField="TotalOrders" HeaderText="Orders" ItemStyle-CssClass="text-end" HeaderStyle-CssClass="text-end" />
          <asp:BoundField DataField="SalesAmount" HeaderText="Sales" DataFormatString="Rs.&#160;{0:N0}"
            ItemStyle-CssClass="text-end fw-semi-bold" HeaderStyle-CssClass="text-end" />
          <asp:BoundField DataField="CancelledOrders" HeaderText="Cancelled" ItemStyle-CssClass="text-end pe-3" HeaderStyle-CssClass="text-end pe-3" />
        </Columns>
      </asp:GridView>
    </div>
  </div>

  </ContentTemplate></asp:UpdatePanel>

</asp:Content>
