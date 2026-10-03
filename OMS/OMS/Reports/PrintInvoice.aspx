<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="PrintInvoice.aspx.cs" Inherits="OMS.Reports.PrintInvoice" %>
<!DOCTYPE html>
<html>
<head runat="server">
  <title>Print Invoice</title>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <%-- Self-contained, black-and-white stylesheet sized for an 80 mm thermal roll
       (about 72 mm printable). The site theme is intentionally not loaded: its
       margins, colours and fonts only add whitespace and clipping on a receipt. --%>
  <style>
    /* Page = the roll: 80 mm wide, height follows the content, no printer margins. */
    @page { size: 80mm auto; margin: 0; }

    * { box-sizing: border-box; }
    html, body { margin: 0; padding: 0; background: #fff; color: #000; }
    body { font-family: Arial, Helvetica, sans-serif; font-size: 11px; line-height: 1.3; }

    .receipt { width: 72mm; margin: 0 auto; padding: 3mm 0; }
    .center  { text-align: center; }
    .right   { text-align: right; }
    .bold    { font-weight: bold; }
    .small   { font-size: 10px; }
    .rule    { border: 0; border-top: 1px dashed #000; margin: 2mm 0; }

    .logo    { display: block; margin: 0 auto 1mm; max-width: 40mm; max-height: 14mm; height: auto; }
    .title   { font-size: 14px; font-weight: bold; margin: 0; }

    table { width: 100%; border-collapse: collapse; }
    td, th { padding: 0.6mm 0; vertical-align: top; }
    th { font-weight: bold; text-align: left; border-bottom: 1px solid #000; }
    th.right, td.right { text-align: right; white-space: nowrap; padding-left: 2mm; }
    .item-name { word-break: break-word; }
    .item-sub  { font-size: 10px; }

    .meta td:first-child { width: 17mm; }
    .totals td { padding: 0.4mm 0; }
    .grand td  { font-size: 13px; font-weight: bold; border-top: 1px solid #000; padding-top: 1mm; }
    .cancelled { border: 1px solid #000; text-align: center; font-weight: bold; margin: 1mm 0 2mm; padding: 1mm 0; }

    /* Screen preview: show the slip on a grey desk at its real width. */
    @media screen {
      body { background: #e5e7eb; }
      .receipt { background: #fff; margin: 12px auto; padding: 4mm 4mm 6mm; width: 80mm; box-shadow: 0 1px 6px rgba(0,0,0,.25); }
      .toolbar { width: 80mm; margin: 12px auto 0; text-align: right; }
      .toolbar button { font: inherit; padding: 6px 14px; cursor: pointer; }
    }
    @media print {
      .no-print { display: none !important; }
      .receipt { width: 72mm; margin: 0 auto; padding: 2mm 0; }
    }
  </style>
</head>
<body>
  <form runat="server">

    <div class="toolbar no-print">
      <button type="button" onclick="window.print()">Print</button>
    </div>

    <div class="receipt">

      <img runat="server" class="logo" src="~/assets/img/icons/spot-illustrations/logo.png" alt="" />
      <p class="title center">Order Invoice</p>
      <div class="center small">
        <asp:Label ID="lblOrderNumber" runat="server" /><br />
        <asp:Label ID="lblOrderDate" runat="server" />
      </div>

      <asp:Panel ID="pnlCancelled" runat="server" Visible="false" CssClass="cancelled">
        ORDER CANCELLED
      </asp:Panel>

      <hr class="rule" />

      <table class="meta">
        <tr><td class="bold">Customer</td><td><asp:Label ID="lblCustomer" runat="server" /></td></tr>
        <tr><td class="bold">Phone</td><td><asp:Label ID="lblPhone" runat="server" /></td></tr>
        <tr><td class="bold">Type</td><td><asp:Label ID="lblOrderType" runat="server" /></td></tr>
        <tr id="pnlTable" runat="server" visible="false"><td class="bold">Table</td><td><asp:Label ID="lblTable" runat="server" /></td></tr>
      </table>

      <hr class="rule" />

      <%-- Items: name with "qty x rate" beneath, amount on the right --%>
      <asp:GridView ID="gvInvoiceItems" runat="server"
        AutoGenerateColumns="False" GridLines="None" ShowHeaderWhenEmpty="false"
        EmptyDataText="No items.">
        <Columns>
          <asp:TemplateField HeaderText="Item">
            <ItemTemplate>
              <div class="item-name"><%# Server.HtmlEncode(Convert.ToString(Eval("ItemName"))) %></div>
              <div class="item-sub"><%# Eval("Quantity") %> x Rs. <%# string.Format("{0:N0}", Eval("UnitPrice")) %></div>
            </ItemTemplate>
          </asp:TemplateField>
          <asp:TemplateField HeaderText="Amount" HeaderStyle-CssClass="right" ItemStyle-CssClass="right bold">
            <ItemTemplate>Rs. <%# string.Format("{0:N0}", Eval("LineTotal")) %></ItemTemplate>
          </asp:TemplateField>
        </Columns>
      </asp:GridView>

      <hr class="rule" />

      <table class="totals">
        <tr>
          <td>Subtotal</td>
          <td class="right"><asp:Label ID="lblSubtotal" runat="server" /></td>
        </tr>
        <tr>
          <td>Discount</td>
          <td class="right"><asp:Label ID="lblDiscount" runat="server" /></td>
        </tr>
        <tr>
          <td><asp:Label ID="lblTaxLabel" runat="server" Text="Tax" /></td>
          <td class="right"><asp:Label ID="lblTax" runat="server" /></td>
        </tr>
        <tr class="grand">
          <td>Total</td>
          <td class="right"><asp:Label ID="lblTotal" runat="server" /></td>
        </tr>
      </table>

      <hr class="rule" />
      <div class="center small">Thank you for your order!</div>

    </div>

  </form>
</body>
</html>
