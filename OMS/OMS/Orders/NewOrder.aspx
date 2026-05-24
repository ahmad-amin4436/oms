<%@ Page Title="New Order" Language="C#" MasterPageFile="~/Site.Master" AutoEventWireup="true" CodeBehind="NewOrder.aspx.cs" Inherits="OMS.Orders.NewOrder" %>
<asp:Content ID="BodyContent" ContentPlaceHolderID="MainContent" runat="server">

  <%-- ── Page header ── --%>
  <div class="d-flex align-items-center justify-content-between mb-3">
    <div>
      <h4 class="mb-0">New Order</h4>
      <p class="text-600 fs--1 mb-0">Select menu items, review cart, then place the order.</p>
    </div>
  </div>

  <asp:Label ID="lblError" runat="server" CssClass="alert alert-danger d-block mb-3"
    Visible="false" EnableViewState="false" />

  <div class="row g-3 align-items-start">

    <%-- ══════════════════════════════════════════════
         LEFT COLUMN — Menu Catalog
         ══════════════════════════════════════════════ --%>
    <div class="col-xl-7 col-lg-7">
      <div class="card">

        <%-- Category tabs --%>
        <div class="card-header py-2">
          <ul class="nav nav-pills flex-wrap gap-1 mb-0">
            <li class="nav-item">
              <asp:LinkButton ID="lbAllCat" runat="server" CssClass="nav-link py-1 px-2 fs--1 active"
                OnClick="lbAllCat_Click" CausesValidation="false">All</asp:LinkButton>
            </li>
            <asp:Repeater ID="rptCategories" runat="server"
              OnItemCommand="rptCategories_ItemCommand">
              <ItemTemplate>
                <li class="nav-item">
                  <asp:LinkButton ID="lbCat" runat="server"
                    CommandName="Filter"
                    CommandArgument='<%# Eval("CategoryID") %>'
                    CssClass='<%# GetCatCss(Eval("CategoryID")) %>'
                    CausesValidation="false"><%# Eval("CategoryName") %></asp:LinkButton>
                </li>
              </ItemTemplate>
            </asp:Repeater>
          </ul>
        </div>

        <%-- Menu items grid --%>
        <div class="card-body p-3">

          <asp:Panel ID="pnlNoItems" runat="server" Visible="false"
            CssClass="text-center text-600 py-5 fs--1">
            No menu items available for this category.
          </asp:Panel>

          <div class="row g-2">
            <asp:Repeater ID="rptMenu" runat="server" OnItemCommand="rptMenu_ItemCommand">
              <ItemTemplate>
                <div class="col-sm-6 col-md-4">
                  <div class="card h-100 border shadow-none">
                    <div class="card-body p-2 d-flex flex-column">
                      <p class="fw-semibold fs--1 mb-1 text-truncate"
                         title='<%# Eval("Name") %>'><%# Eval("Name") %></p>
                      <p class="text-600 fs--2 mb-auto"
                         style="min-height:2.2rem;overflow:hidden"><%# Eval("Description") %></p>
                      <div class="d-flex align-items-center justify-content-between mt-2">
                        <span class="fw-bold text-primary fs--1">
                          Rs.&#160;<%# Eval("BasePrice", "{0:N0}") %>
                        </span>
                        <asp:LinkButton ID="lbAdd" runat="server"
                          CommandName="Add"
                          CommandArgument='<%# EncodeArg(Eval("ItemID"), Eval("BasePrice"), Eval("Name")) %>'
                          CssClass="btn btn-sm btn-primary px-2 py-1 fs--2"
                          CausesValidation="false">+ Add</asp:LinkButton>
                      </div>
                    </div>
                  </div>
                </div>
              </ItemTemplate>
            </asp:Repeater>
          </div>

        </div>
      </div>
    </div>

    <%-- ══════════════════════════════════════════════
         RIGHT COLUMN — Order Summary
         ══════════════════════════════════════════════ --%>
    <div class="col-xl-5 col-lg-5">
      <div class="card">

        <div class="card-header py-2 d-flex align-items-center justify-content-between">
          <h5 class="mb-0 fs-0">Order Summary</h5>
          <asp:LinkButton ID="lbClearCart" runat="server" CssClass="btn btn-sm btn-falcon-default"
            OnClick="lbClearCart_Click" CausesValidation="false">Clear Cart</asp:LinkButton>
        </div>

        <div class="card-body p-3">

          <%-- ── Customer info ── --%>
          <div class="row g-2 mb-3 pb-3 border-bottom">
            <div class="col-6">
              <label class="form-label fs--1 mb-1">Customer Name</label>
              <asp:TextBox ID="txtCustomerName" runat="server"
                CssClass="form-control form-control-sm" placeholder="Optional" />
            </div>
            <div class="col-6">
              <label class="form-label fs--1 mb-1">Phone</label>
              <asp:TextBox ID="txtPhone" runat="server"
                CssClass="form-control form-control-sm" placeholder="Optional" />
            </div>
            <div class="col-6">
              <label class="form-label fs--1 mb-1">Order Type</label>
              <asp:DropDownList ID="ddlOrderType" runat="server"
                CssClass="form-select form-select-sm"
                AutoPostBack="true"
                OnSelectedIndexChanged="ddlOrderType_Changed">
                <asp:ListItem Value="DineIn">Dine In</asp:ListItem>
                <asp:ListItem Value="Takeaway">Takeaway</asp:ListItem>
                <asp:ListItem Value="Delivery">Delivery</asp:ListItem>
              </asp:DropDownList>
            </div>
            <%-- Shown for DineIn --%>
            <asp:Panel ID="pnlTableNo" runat="server" CssClass="col-6">
              <label class="form-label fs--1 mb-1">Table No.</label>
              <asp:TextBox ID="txtTableNo" runat="server"
                CssClass="form-control form-control-sm" placeholder="e.g. 5" />
            </asp:Panel>
            <%-- Shown for Delivery --%>
            <asp:Panel ID="pnlAddress" runat="server" CssClass="col-12" Visible="false">
              <label class="form-label fs--1 mb-1">Delivery Address</label>
              <asp:TextBox ID="txtAddress" runat="server"
                CssClass="form-control form-control-sm"
                TextMode="MultiLine" Rows="2" placeholder="Street, area..." />
            </asp:Panel>
          </div>

          <%-- ── Cart ── --%>
          <asp:Panel ID="pnlEmptyCart" runat="server"
            CssClass="text-center text-600 py-4 fs--1 mb-3 border rounded">
            No items added yet.
          </asp:Panel>

          <asp:Panel ID="pnlCart" runat="server" Visible="false" CssClass="mb-3">
            <div class="table-responsive" style="max-height:240px;overflow-y:auto;">
              <table class="table table-sm table-borderless mb-0 fs--1 align-middle">
                <thead>
                  <tr class="border-bottom">
                    <th class="ps-0 text-600 fw-medium">Item</th>
                    <th class="text-center text-600 fw-medium" style="width:100px">Qty</th>
                    <th class="text-end text-600 fw-medium pe-0" style="width:76px">Total</th>
                    <th style="width:30px"></th>
                  </tr>
                </thead>
                <tbody>
                  <asp:Repeater ID="rptCart" runat="server" OnItemCommand="rptCart_ItemCommand">
                    <ItemTemplate>
                      <tr>
                        <td class="ps-0"><%# Eval("Name") %></td>
                        <td class="text-center">
                          <div class="d-flex align-items-center justify-content-center gap-1">
                            <asp:LinkButton ID="lbMinus" runat="server"
                              CommandName="Minus"
                              CommandArgument='<%# Eval("ItemID") %>'
                              CssClass="btn btn-sm btn-falcon-default px-2 py-0 lh-sm"
                              CausesValidation="false">&#8722;</asp:LinkButton>
                            <span class="fw-semibold px-1" style="min-width:20px;text-align:center"><%# Eval("Qty") %></span>
                            <asp:LinkButton ID="lbPlus" runat="server"
                              CommandName="Plus"
                              CommandArgument='<%# Eval("ItemID") %>'
                              CssClass="btn btn-sm btn-falcon-default px-2 py-0 lh-sm"
                              CausesValidation="false">+</asp:LinkButton>
                          </div>
                        </td>
                        <td class="text-end pe-0 fw-semibold">Rs.&#160;<%# Eval("LineTotal", "{0:N0}") %></td>
                        <td class="text-center">
                          <asp:LinkButton ID="lbRemove" runat="server"
                            CommandName="Remove"
                            CommandArgument='<%# Eval("ItemID") %>'
                            CssClass="btn btn-sm btn-falcon-danger p-1 lh-1"
                            CausesValidation="false">&times;</asp:LinkButton>
                        </td>
                      </tr>
                    </ItemTemplate>
                  </asp:Repeater>
                </tbody>
              </table>
            </div>
          </asp:Panel>

          <%-- ── Totals ── --%>
          <div class="border-top pt-2 mb-3">
            <div class="d-flex justify-content-between fs--1 mb-1">
              <span class="text-600">Subtotal</span>
              <asp:Label ID="lblSubtotal" runat="server" Text="Rs. 0" />
            </div>
            <div class="d-flex justify-content-between align-items-center fs--1 mb-1">
              <span class="text-600">Discount&nbsp;(%)</span>
              <div class="d-flex align-items-center gap-2">
                <asp:TextBox ID="txtDiscountPct" runat="server"
                  CssClass="form-control form-control-sm text-end"
                  Text="0" Width="58px"
                  AutoPostBack="true"
                  OnTextChanged="txtDiscountPct_Changed" />
                <asp:Label ID="lblDiscountAmt" runat="server"
                  Text="Rs. 0" CssClass="text-nowrap text-danger" />
              </div>
            </div>
            <div class="d-flex justify-content-between fs--1 mb-2">
              <span class="text-600">Tax (16%)</span>
              <asp:Label ID="lblTax" runat="server" Text="Rs. 0" />
            </div>
            <div class="d-flex justify-content-between fw-bold fs-0 border-top pt-2">
              <span>Total</span>
              <asp:Label ID="lblTotal" runat="server" Text="Rs. 0" CssClass="text-primary" />
            </div>
          </div>

          <%-- ── Payment & Notes ── --%>
          <div class="row g-2 mb-3">
            <div class="col-12">
              <label class="form-label fs--1 mb-1">Payment Method</label>
              <asp:DropDownList ID="ddlPaymentMethod" runat="server"
                CssClass="form-select form-select-sm">
                <asp:ListItem Value="Cash">Cash</asp:ListItem>
                <asp:ListItem Value="Card">Card</asp:ListItem>
                <asp:ListItem Value="Wallet">Wallet</asp:ListItem>
                <asp:ListItem Value="BankTransfer">Bank Transfer</asp:ListItem>
              </asp:DropDownList>
            </div>
            <div class="col-12">
              <label class="form-label fs--1 mb-1">Notes</label>
              <asp:TextBox ID="txtNotes" runat="server"
                CssClass="form-control form-control-sm"
                TextMode="MultiLine" Rows="2"
                placeholder="Special instructions..." />
            </div>
          </div>

          <%-- ── Submit ── --%>
          <asp:Button ID="btnPlaceOrder" runat="server"
            CssClass="btn btn-primary w-100"
            Text="Place Order"
            OnClick="btnPlaceOrder_Click" />

        </div>
      </div>
    </div>

  </div>

</asp:Content>