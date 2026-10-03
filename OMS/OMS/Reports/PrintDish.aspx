<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="PrintDish.aspx.cs" Inherits="OMS.Reports.PrintDish" %>
<!DOCTYPE html>
<html>
<head runat="server">
  <title>Print Dish</title>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <%-- Kitchen ticket for ONE dish, 80 mm thermal roll (same sizing as PrintInvoice). --%>
  <style>
    @page { size: 80mm auto; margin: 0; }
    * { box-sizing: border-box; }
    html, body { margin: 0; padding: 0; background: #fff; color: #000; }
    body { font-family: Arial, Helvetica, sans-serif; font-size: 12px; line-height: 1.3; }
    .ticket { width: 72mm; margin: 0 auto; padding: 3mm 0; }
    .center { text-align: center; }
    .bold { font-weight: bold; }
    .rule { border: 0; border-top: 1px dashed #000; margin: 2mm 0; }
    .big  { font-size: 18px; font-weight: bold; }
    .qty  { font-size: 22px; font-weight: bold; }
    .mod  { padding-left: 3mm; }
    .row  { display: flex; justify-content: space-between; gap: 2mm; }
    .error { padding: 10px; font-family: Arial; }
    @media screen {
      body { background: #e5e7eb; }
      .ticket { background: #fff; margin: 12px auto; padding: 4mm 4mm 6mm; width: 80mm; box-shadow: 0 1px 6px rgba(0,0,0,.25); }
      .toolbar { width: 80mm; margin: 12px auto 0; text-align: right; }
      .toolbar button { font: inherit; padding: 6px 14px; cursor: pointer; }
    }
    @media print { .no-print { display: none !important; } }
  </style>
</head>
<body>
  <form runat="server">
    <div class="toolbar no-print">
      <button type="button" onclick="window.print()">Print</button>
    </div>
    <asp:Literal ID="litTicket" runat="server" />
    <asp:Literal ID="litScript" runat="server" />
  </form>
</body>
</html>
