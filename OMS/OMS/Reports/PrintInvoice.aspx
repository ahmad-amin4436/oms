<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="PrintInvoice.aspx.cs" Inherits="OMS.Reports.PrintInvoice" %>
<!DOCTYPE html>
<html><head runat="server"><title>Print Invoice</title><link href="../assets/css/theme.min.css" rel="stylesheet" /><link href="../Assets/css/rms-custom.css" rel="stylesheet" /></head>
<body onload="window.print()"><form runat="server"><div class="rms-receipt p-3"><div class="text-center"><img src="../assets/img/icons/spot-illustrations/logo.png" width="180" /><h5>Order Invoice</h5><p><asp:Label ID="lblOrderNumber" runat="server" /></p></div><asp:GridView ID="gvInvoiceItems" runat="server" CssClass="table table-sm" AutoGenerateColumns="true" GridLines="None" /></div></form></body></html>
