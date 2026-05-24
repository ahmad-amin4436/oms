<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="PrintInvoice.aspx.cs" Inherits="OMS.Reports.PrintInvoice" %>
<!DOCTYPE html>
<html>
<head runat="server">
  <title>Print Invoice</title>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <link runat="server" rel="stylesheet" href="~/assets/css/theme.min.css" />
  <link runat="server" rel="stylesheet" href="~/assets/css/rms-custom.css" />
  <style>
    body { background: #fff; font-size: 13px; }
    .invoice-wrap { max-width: 680px; margin: 0 auto; padding: 24px; }
    .inv-header { border-bottom: 2px solid #e2e8f0; padding-bottom: 12px; margin-bottom: 16px; }
    .inv-totals td { padding: 2px 6px; }
    @media print {
      .no-print { display: none !important; }
    }
  </style>
</head>
<body>
  <form runat="server">

    <div class="invoice-wrap">

      <%-- Print button (hidden on print) --%>
      <div class="text-end mb-3 no-print">
        <button type="button" onclick="window.print()" class="btn btn-sm btn-primary">
          Print / Save PDF
        </button>
      </div>

      <%-- Invoice header --%>
      <div class="inv-header d-flex align-items-start justify-content-between">
        <div>
          <img runat="server" src="~/assets/img/icons/spot-illustrations/logo.png"
               alt="Logo" height="40" />
          <h5 class="mt-2 mb-1">Order Invoice</h5>
          <p class="mb-0 text-600 fs--1">
            <asp:Label ID="lblOrderNumber" runat="server" />
          </p>
          <p class="mb-0 text-600 fs--1">
            <asp:Label ID="lblOrderDate" runat="server" />
          </p>
        </div>
        <div class="text-end fs--1">
          <div><strong>Customer:</strong> <asp:Label ID="lblCustomer" runat="server" /></div>
          <div><strong>Phone:</strong> <asp:Label ID="lblPhone" runat="server" /></div>
          <div><strong>Type:</strong> <asp:Label ID="lblOrderType" runat="server" /></div>
          <asp:Panel ID="pnlTable" runat="server" Visible="false">
            <div><strong>Table:</strong> <asp:Label ID="lblTable" runat="server" /></div>
          </asp:Panel>
        </div>
      </div>

      <%-- Items grid --%>
      <asp:GridView ID="gvInvoiceItems" runat="server"
        CssClass="table table-sm w-100"
        AutoGenerateColumns="False" GridLines="None"
        EmptyDataText="No items.">
        <HeaderStyle CssClass="bg-light" />
        <Columns>
          <asp:BoundField DataField="ItemName"  HeaderText="Item"
            HeaderStyle-CssClass="ps-0 fw-medium" ItemStyle-CssClass="ps-0" />
          <asp:BoundField DataField="Quantity"  HeaderText="Qty"
            HeaderStyle-CssClass="text-center fw-medium" ItemStyle-CssClass="text-center" />
          <asp:BoundField DataField="UnitPrice" HeaderText="Unit"
            DataFormatString="Rs. {0:N0}"
            HeaderStyle-CssClass="text-end fw-medium" ItemStyle-CssClass="text-end" />
          <asp:BoundField DataField="LineTotal" HeaderText="Total"
            DataFormatString="Rs. {0:N0}"
            HeaderStyle-CssClass="text-end fw-medium" ItemStyle-CssClass="text-end fw-semibold" />
        </Columns>
      </asp:GridView>

      <%-- Totals --%>
      <div class="d-flex justify-content-end mt-2">
        <table class="inv-totals fs--1">
          <tr>
            <td class="text-600 pe-4">Subtotal</td>
            <td class="text-end"><asp:Label ID="lblSubtotal" runat="server" /></td>
          </tr>
          <tr>
            <td class="text-600 pe-4">Discount</td>
            <td class="text-end text-danger"><asp:Label ID="lblDiscount" runat="server" /></td>
          </tr>
          <tr>
            <td class="text-600 pe-4">Tax</td>
            <td class="text-end"><asp:Label ID="lblTax" runat="server" /></td>
          </tr>
          <tr class="border-top">
            <td class="fw-bold pe-4 pt-1">Total</td>
            <td class="text-end fw-bold text-primary pt-1">
              <asp:Label ID="lblTotal" runat="server" />
            </td>
          </tr>
        </table>
      </div>

      <%-- Footer --%>
      <div class="text-center text-600 fs--2 mt-4 border-top pt-3">
        Thank you for your order!
      </div>

    </div>

  </form>
</body>
</html>
