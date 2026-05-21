<%@ Page Title="New Order" Language="C#" MasterPageFile="~/Site.Master" AutoEventWireup="true" CodeBehind="NewOrder.aspx.cs" Inherits="OMS.Orders.NewOrder" %>
<asp:Content ID="Content1" ContentPlaceHolderID="MainContent" runat="server">
  <div class="rms-page-header">
    <div><h3 class="mb-0">New Order</h3><p class="mb-0 text-600">Wizard scaffold for customer, menu selection, and payment.</p></div>
  </div>
  <div class="card">
    <div class="card-body">
      <ul class="nav nav-tabs" role="tablist">
        <li class="nav-item"><a class="nav-link active" data-bs-toggle="tab" href="#customer">Customer</a></li>
        <li class="nav-item"><a class="nav-link" data-bs-toggle="tab" href="#menu">Menu</a></li>
        <li class="nav-item"><a class="nav-link" data-bs-toggle="tab" href="#payment">Payment</a></li>
      </ul>
      <div class="tab-content border-x border-bottom p-3">
        <div class="tab-pane fade show active" id="customer">
          <div class="row g-3">
            <div class="col-md-4"><label class="form-label">Customer Name</label><asp:TextBox ID="txtCustomerName" runat="server" CssClass="form-control" /></div>
            <div class="col-md-4"><label class="form-label">Phone</label><asp:TextBox ID="txtPhone" runat="server" CssClass="form-control" /></div>
            <div class="col-md-4"><label class="form-label">Order Type</label><asp:DropDownList ID="ddlOrderType" runat="server" CssClass="form-select"><asp:ListItem>DineIn</asp:ListItem><asp:ListItem>Takeaway</asp:ListItem><asp:ListItem>Delivery</asp:ListItem></asp:DropDownList></div>
            <div class="col-12"><label class="form-label">Address / Notes</label><asp:TextBox ID="txtAddress" runat="server" CssClass="form-control" TextMode="MultiLine" Rows="2" /></div>
          </div>
        </div>
        <div class="tab-pane fade" id="menu">
          <asp:Repeater ID="rptMenu" runat="server">
            <HeaderTemplate><div class="row g-3"></HeaderTemplate>
            <ItemTemplate><div class="col-md-4"><div class="card h-100"><div class="card-body"><h5><%# Eval("Name") %></h5><p class="text-600"><%# Eval("Description") %></p><strong>Rs. <%# Eval("BasePrice", "{0:N2}") %></strong></div></div></div></ItemTemplate>
            <FooterTemplate></div></FooterTemplate>
          </asp:Repeater>
        </div>
        <div class="tab-pane fade" id="payment">
          <div class="row g-3">
            <div class="col-md-4"><label class="form-label">Payment Method</label><asp:DropDownList ID="ddlPaymentMethod" runat="server" CssClass="form-select"><asp:ListItem>Cash</asp:ListItem><asp:ListItem>Card</asp:ListItem><asp:ListItem>Wallet</asp:ListItem><asp:ListItem>BankTransfer</asp:ListItem></asp:DropDownList></div>
            <div class="col-md-4"><label class="form-label">Subtotal</label><asp:TextBox ID="txtSubTotal" runat="server" CssClass="form-control" Text="0" /></div>
            <div class="col-md-4 d-flex align-items-end"><asp:Button ID="btnPlaceOrder" runat="server" CssClass="btn btn-primary w-100" Text="Place Order" OnClick="btnPlaceOrder_Click" /></div>
          </div>
        </div>
      </div>
    </div>
  </div>
</asp:Content>
