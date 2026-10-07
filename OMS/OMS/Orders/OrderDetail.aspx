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
      <a runat="server" id="lnkAllOrders" href="~/Orders/OrderList.aspx"
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
                  <asp:TemplateField HeaderStyle-CssClass="border-0" ItemStyle-CssClass="align-middle text-end">
                    <ItemTemplate>
                      <a href="#" class="btn btn-falcon-default btn-sm px-2 py-0 fs--2" title="Print this dish"
                         onclick="return printDish(<%# Eval("OrderItemID") %>);">
                        <span class="fas fa-print"></span> Print
                      </a>
                    </ItemTemplate>
                  </asp:TemplateField>
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
                    <th class="text-900"><asp:Label ID="lblTaxLabel" runat="server" Text="Tax" />:</th>
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

        <%-- Add dishes: allowed until the order is Delivered/Cancelled; dishes can only be added, never removed --%>
        <asp:Panel ID="pnlAddDish" runat="server" CssClass="card mb-3">
          <div class="card-header py-2">
            <h5 class="mb-0 fs-0">Add Dish</h5>
          </div>
          <div class="card-body">
            <asp:Label ID="lblAddMsg" runat="server" Visible="false" EnableViewState="false"
              CssClass="alert alert-success d-block py-2 fs--1" />
            <div class="row g-2 align-items-end">
              <div class="col-sm-7">
                <label class="form-label fs--1 mb-1">Dish</label>
                <%-- Click to see the whole menu, type to narrow it. The chosen ItemID lands in the hidden field. --%>
                <div class="position-relative">
                  <input type="text" id="txtDishSearch" autocomplete="off"
                    class="form-control form-control-sm" placeholder="Click to browse, or type to search dishes..." />
                  <div id="dishMenu" class="list-group shadow position-absolute w-100 d-none"
                    style="max-height:280px;overflow-y:auto;z-index:1050;">
                    <asp:Literal ID="litDishList" runat="server" />
                  </div>
                </div>
                <asp:HiddenField ID="hfAddItem" runat="server" />
                <span id="dishPickError" class="text-danger fs--2 d-none">Pick a dish from the list.</span>
              </div>
              <div class="col-5 col-sm-2">
                <label class="form-label fs--1 mb-1">Qty</label>
                <asp:TextBox ID="txtAddQty" runat="server" Text="1" TextMode="Number" CssClass="form-control form-control-sm"
                  ValidationGroup="AddDish" />
                <asp:RangeValidator ID="rngAddQty" runat="server" ControlToValidate="txtAddQty" Type="Integer"
                  MinimumValue="1" MaximumValue="100" ValidationGroup="AddDish" Display="Dynamic"
                  ErrorMessage="1-100" CssClass="text-danger fs--2" />
              </div>
              <div class="col-7 col-sm-3">
                <asp:Button ID="btnAddDish" runat="server" Text="+ Add" CssClass="btn btn-primary btn-sm w-100"
                  ValidationGroup="AddDish" OnClick="btnAddDish_Click" OnClientClick="return dishPicked();" />
              </div>
            </div>
            <p class="fs--2 text-600 mb-0 mt-2">Totals are recalculated with this order's discount and tax rate.</p>
          </div>
        </asp:Panel>

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

            <%-- Cancellation audit — shown only for cancelled orders --%>
            <asp:Panel ID="pnlCancelInfo" runat="server" Visible="false"
              CssClass="border-top pt-2 mt-2 text-danger">
              <div class="d-flex justify-content-between mb-1">
                <span>Cancelled</span>
                <asp:Label ID="lblCancelledAt" runat="server" />
              </div>
              <div class="d-flex justify-content-between mb-1">
                <span>Cancelled by</span>
                <asp:Label ID="lblCancelledBy" runat="server" />
              </div>
              <div>Reason: <asp:Label ID="lblCancelReason" runat="server" /></div>
            </asp:Panel>

          </div>
        </div>

        <%-- Update Status (hidden once the order is cancelled) --%>
        <asp:Panel ID="pnlUpdateStatus" runat="server" CssClass="card mb-3">
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
        </asp:Panel>

        <%-- Cancel Order (Admin only; not shown for Cancelled / Delivered orders) --%>
        <asp:Panel ID="pnlCancel" runat="server" Visible="false" CssClass="card border border-danger">
          <div class="card-header py-2">
            <h5 class="mb-0 fs-0 text-danger">Cancel Order</h5>
          </div>
          <div class="card-body py-3">
            <asp:TextBox ID="txtCancelReason" runat="server" TextMode="MultiLine" Rows="2"
              MaxLength="500" CssClass="form-control form-control-sm mb-2"
              placeholder="Reason for cancellation (required)" ValidationGroup="CancelOrder" />
            <asp:RequiredFieldValidator ID="rfvCancelReason" runat="server"
              ControlToValidate="txtCancelReason" ValidationGroup="CancelOrder"
              ErrorMessage="Please enter a reason." Display="Dynamic"
              CssClass="text-danger fs--2 d-block mb-2" />
            <asp:Button ID="btnCancelOrder" runat="server"
              CssClass="btn btn-danger btn-sm w-100" Text="Cancel Order"
              ValidationGroup="CancelOrder"
              OnClientClick="return confirm('Cancel this order? This cannot be undone.');"
              OnClick="btnCancelOrder_Click" />
          </div>
        </asp:Panel>

      </div>
    </div>
  </asp:Panel>

  <script>
    // Add Dish picker: the full menu opens on click/focus; typing narrows it; choosing sets the ItemID.
    (function () {
      var box = document.getElementById('txtDishSearch');
      var menu = document.getElementById('dishMenu');
      if (!box || !menu) return;
      var hf = document.getElementById('<%= hfAddItem.ClientID %>');
      var rows = menu.children;                      // category headers + dish buttons, in menu order

      function filter() {
        var q = box.value.trim().toLowerCase(), header = null, headerHasMatch = false;
        for (var i = 0; i < rows.length; i++) {
          var r = rows[i];
          if (r.getAttribute('data-header')) {       // a category header: show only if a dish under it matches
            if (header) header.classList.toggle('d-none', !headerHasMatch);
            header = r; headerHasMatch = false;
          } else {
            var show = q === '' || r.textContent.toLowerCase().indexOf(q) !== -1;
            r.classList.toggle('d-none', !show);
            if (show) headerHasMatch = true;
          }
        }
        if (header) header.classList.toggle('d-none', !headerHasMatch);
      }
      function open()  { filter(); menu.classList.remove('d-none'); }
      function close() { menu.classList.add('d-none'); }

      box.addEventListener('focus', open);
      box.addEventListener('click', open);
      box.addEventListener('input', function () {
        hf.value = '';                               // typing invalidates the previous choice
        document.getElementById('dishPickError').classList.add('d-none');
        open();
      });
      box.addEventListener('keydown', function (e) {
        if (e.key === 'Escape') close();
        if (e.key === 'Enter') {                     // Enter picks the first match; never submits the page
          e.preventDefault();
          for (var i = 0; i < rows.length; i++)
            if (!rows[i].getAttribute('data-header') && !rows[i].classList.contains('d-none')) { rows[i].click(); break; }
        }
      });
      menu.addEventListener('click', function (e) {
        var b = e.target.closest('button[data-id]');
        if (!b) return;
        hf.value = b.getAttribute('data-id');
        box.value = b.getAttribute('data-label');
        document.getElementById('dishPickError').classList.add('d-none');
        close();
      });
      document.addEventListener('click', function (e) {
        if (e.target !== box && !menu.contains(e.target)) close();
      });
    })();
    function dishPicked() {
      var hf = document.getElementById('<%= hfAddItem.ClientID %>');
      var ok = hf && hf.value !== '';
      document.getElementById('dishPickError').classList.toggle('d-none', ok);
      return ok;
    }
    // One kitchen ticket per dish; the browser print dialog lets the user pick the printer.
    function printDish(orderItemId) {
      var url = '<%= ResolveUrl("~/Reports/PrintDish.aspx") %>?id=<%= Server.UrlEncode(Request.QueryString["id"] ?? "") %>&item=' + orderItemId;
      window.open(url, 'printDish', 'width=420,height=640');
      return false;
    }
  </script>
</asp:Content>