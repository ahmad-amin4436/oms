<%@ Page Title="Order Detail" Language="C#" MasterPageFile="~/Site.Master" AutoEventWireup="true"
   CodeBehind="OrderDetail.aspx.cs" Inherits="OMS.Orders.OrderDetail" %>

<asp:Content ID="Content1" ContentPlaceHolderID="MainContent" runat="server">

  <%-- ── Page header ── --%>
  <div class="d-flex align-items-center justify-content-between mb-3">
    <div>
      <h4 class="mb-0">Order Detail</h4>
      <p class="text-600 fs--1 mb-0">
        <asp:Label ID="lblOrderNumber" runat="server" />
      </p>
    </div>
    <div class="d-flex gap-2">
      <a runat="server" id="lnkPrint" href="#" target="_blank"
         class="btn btn-sm btn-falcon-default">Print Invoice</a>
      <a runat="server" href="~/Orders/OrderList.aspx"
         class="btn btn-sm btn-falcon-default">&#8592; All Orders</a>
    </div>
  </div>

  <asp:Label ID="lblError" runat="server" CssClass="alert alert-danger d-block mb-3"
    Visible="false" EnableViewState="false" />

  <asp:Panel ID="pnlNotFound" runat="server" Visible="false"
    CssClass="alert alert-warning">Order not found.</asp:Panel>

  <asp:Panel ID="pnlContent" runat="server">

    <%-- ══ Order summary header card (Falcon) ══ --%>
    <div class="card mb-3">
      <div class="bg-holder d-none d-lg-block bg-card"
        style="background-image:url('<%= ResolveUrl("~/assets/img/icons/spot-illustrations/corner-4.png") %>');opacity:0.7;"></div>
      <div class="card-body position-relative">
        <h5 class="mb-1">Order Details: <asp:Label ID="lblOrderNumberCard" runat="server" /></h5>
        <p class="fs--1 mb-2"><asp:Label ID="lblCreatedAtCard" runat="server" /></p>
        <div class="d-flex align-items-center">
          <strong class="me-2">Status:</strong>
          <span class='badge rounded-pill fs--2 <%= _statusBadgeClass %>'>
            <asp:Label ID="lblStatusBadge" runat="server" /><span class='ms-1 <%= _statusBadgeIcon %>' data-fa-transform="shrink-2"></span>
          </span>
        </div>
      </div>
    </div>

    <div class="row g-3">

      <%-- ══ LEFT: Items + Totals ══ --%>
      <div class="col-lg-8">

        <%-- Order items --%>
        <div class="card mb-3">
          <div class="card-header py-2">
            <h5 class="mb-0 fs-0">Order Items</h5>
          </div>
          <div class="card-body">
            <div class="table-responsive fs--1">
              <asp:GridView ID="gvItems" runat="server"
                CssClass="table table-striped border-bottom align-middle mb-0"
                AutoGenerateColumns="False" GridLines="None"
                EmptyDataText="No items on this order.">
                <EmptyDataRowStyle CssClass="text-center text-600 py-3 fs--1" />
                <HeaderStyle CssClass="bg-200 text-900" />
                <Columns>
                  <asp:BoundField DataField="ItemName" HeaderText="Products"
                    HeaderStyle-CssClass="border-0"
                    ItemStyle-CssClass="align-middle fw-semibold" />
                  <asp:BoundField DataField="Quantity" HeaderText="Quantity"
                    HeaderStyle-CssClass="border-0 text-center"
                    ItemStyle-CssClass="align-middle text-center" />
                  <asp:BoundField DataField="UnitPrice" HeaderText="Rate"
                    DataFormatString="Rs.&#160;{0:N0}"
                    HeaderStyle-CssClass="border-0 text-end"
                    ItemStyle-CssClass="align-middle text-end" />
                  <asp:BoundField DataField="LineTotal" HeaderText="Amount"
                    DataFormatString="Rs.&#160;{0:N0}"
                    HeaderStyle-CssClass="border-0 text-end"
                    ItemStyle-CssClass="align-middle text-end fw-semibold" />
                </Columns>
              </asp:GridView>
            </div>

            <%-- Totals --%>
            <div class="row g-0 justify-content-end mt-3">
              <div class="col-auto">
                <table class="table table-sm table-borderless fs--1 text-end mb-0">
                  <tr>
                    <th class="text-900">Subtotal:</th>
                    <td class="fw-semi-bold"><asp:Label ID="lblSubtotal" runat="server" /></td>
                  </tr>
                  <tr>
                    <th class="text-900">Discount:</th>
                    <td class="fw-semi-bold text-danger"><asp:Label ID="lblDiscount" runat="server" /></td>
                  </tr>
                  <tr>
                    <th class="text-900">Tax (16%):</th>
                    <td class="fw-semi-bold"><asp:Label ID="lblTax" runat="server" /></td>
                  </tr>
                  <tr class="border-top">
                    <th class="text-900">Total:</th>
                    <td class="fw-semi-bold text-primary"><asp:Label ID="lblTotal" runat="server" /></td>
                  </tr>
                </table>
              </div>
            </div>
          </div>
        </div>

      </div>

      <%-- ══ RIGHT: Order Info + Status ══ --%>
      <div class="col-lg-4">

        <%-- Order Info --%>
        <div class="card mb-3">
          <div class="card-header py-2">
            <h5 class="mb-0 fs-0">Order Info</h5>
          </div>
          <div class="card-body py-3 fs--1">

            <div class="d-flex justify-content-between mb-2">
              <span class="text-600">Customer</span>
              <asp:Label ID="lblCustomer" runat="server" Text="&mdash;" CssClass="text-end" />
            </div>
            <div class="d-flex justify-content-between mb-2">
              <span class="text-600">Phone</span>
              <asp:Label ID="lblPhone" runat="server" Text="&mdash;" CssClass="text-end" />
            </div>
            <div class="d-flex justify-content-between mb-2">
              <span class="text-600">Order Type</span>
              <asp:Label ID="lblOrderType" runat="server" />
            </div>

            <%-- DineIn only --%>
            <asp:Panel ID="pnlTableRow" runat="server" Visible="false"
              CssClass="d-flex justify-content-between mb-2">
              <span class="text-600">Table No.</span>
              <asp:Label ID="lblTableNo" runat="server" />
            </asp:Panel>

            <%-- Delivery only --%>
            <asp:Panel ID="pnlAddressRow" runat="server" Visible="false"
              CssClass="mb-2">
              <div class="text-600 mb-1">Delivery Address</div>
              <asp:Label ID="lblAddress" runat="server" CssClass="d-block" />
            </asp:Panel>

            <div class="d-flex justify-content-between mb-2">
              <span class="text-600">Payment</span>
              <asp:Label ID="lblPaymentMethod" runat="server" />
            </div>
            <div class="d-flex justify-content-between mb-2">
              <span class="text-600">Pay Status</span>
              <asp:Label ID="lblPaymentStatus" runat="server" />
            </div>

            <%-- Notes — hidden when empty --%>
            <asp:Panel ID="pnlNotes" runat="server" Visible="false"
              CssClass="border-top pt-2 mt-1">
              <div class="text-600 mb-1">Notes</div>
              <asp:Label ID="lblNotes" runat="server" CssClass="d-block text-700" />
            </asp:Panel>

            <div class="d-flex justify-content-between border-top pt-2 mt-1">
              <span class="text-600">Placed</span>
              <asp:Label ID="lblCreatedAt" runat="server" />
            </div>

          </div>
        </div>

        <%-- Update Status --%>
        <div class="card">
          <div class="card-header py-2">
            <h5 class="mb-0 fs-0">Update Status</h5>
          </div>
          <div class="card-body py-3">
            <asp:Label ID="lblStatusMsg" runat="server" EnableViewState="false"
              Visible="false" CssClass="alert alert-success d-block mb-2 py-2 fs--1" />
            <asp:DropDownList ID="ddlStatus" runat="server"
              CssClass="form-select form-select-sm mb-2" />
            <asp:Button ID="btnUpdateStatus" runat="server"
              CssClass="btn btn-primary btn-sm w-100"
              Text="Update Status"
              OnClick="btnUpdateStatus_Click" />
          </div>
        </div>

      </div>
    </div>
  </asp:Panel>

</asp:Content>
