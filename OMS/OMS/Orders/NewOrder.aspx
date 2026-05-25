<%@ Page Title="New Order" Language="C#" MasterPageFile="~/Site.Master" AutoEventWireup="true" CodeBehind="NewOrder.aspx.cs" Inherits="OMS.Orders.NewOrder" %>
<asp:Content ID="BodyContent" ContentPlaceHolderID="MainContent" runat="server">

  <%-- ── Page header ── --%>
  <div class="d-flex align-items-center justify-content-between mb-3">
    <div>
      <h4 class="mb-0">New Order</h4>
      <p class="text-600 fs--1 mb-0">Select menu items, review the cart, then place the order.</p>
    </div>
    <a href="OrderList.aspx" class="btn btn-sm btn-falcon-default">
      <span class="fas fa-list me-1"></span>All Orders
    </a>
  </div>

  <asp:Label ID="lblError" runat="server" CssClass="alert alert-danger d-flex align-items-center mb-3"
    Visible="false" EnableViewState="false" />

  <%-- A single validation summary keeps all field errors in one place --%>
  <asp:ValidationSummary ID="vsOrder" runat="server" ValidationGroup="PlaceOrder"
    CssClass="alert alert-warning mb-3" HeaderText="Please fix the following:"
    DisplayMode="BulletList" EnableViewState="false" />

  <div class="row g-3 align-items-start">

    <%-- ══════════════════════════════════════════════
         LEFT COLUMN — Menu Catalog
         ══════════════════════════════════════════════ --%>
    <div class="col-xl-7 col-lg-7">
      <div class="card">

        <%-- Category tabs + search --%>
        <div class="card-header py-2">
          <div class="row g-2 align-items-center">
            <div class="col-12 col-md">
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
            <div class="col-12 col-md-auto">
              <%-- DefaultButton makes Enter run the search without needing to blur the box --%>
              <asp:Panel ID="pnlSearch" runat="server" DefaultButton="lbSearch"
                CssClass="input-group input-group-sm" style="min-width:200px">
                <span class="input-group-text bg-transparent"><span class="fas fa-search text-600"></span></span>
                <asp:TextBox ID="txtSearch" runat="server"
                  CssClass="form-control form-control-sm"
                  placeholder="Search items..."
                  AutoPostBack="true"
                  OnTextChanged="txtSearch_Changed" CausesValidation="false" />
                <asp:Button ID="lbSearch" runat="server" CssClass="btn btn-sm btn-falcon-default"
                  OnClick="txtSearch_Changed" CausesValidation="false"
                  Text="Go" ToolTip="Search" />
              </asp:Panel>
            </div>
          </div>
        </div>

        <%-- Menu items grid --%>
        <div class="card-body p-3">

          <asp:Panel ID="pnlNoItems" runat="server" Visible="false"
            CssClass="text-center text-600 py-5 fs--1">
            <span class="fas fa-utensils fs-3 d-block mb-2 text-300"></span>
            No menu items match your selection.
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
                          CausesValidation="false"><span class="fas fa-plus me-1"></span>Add</asp:LinkButton>
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
          <h5 class="mb-0 fs-0">
            Order Summary
            <asp:Label ID="lblCartCount" runat="server" CssClass="badge badge-subtle-primary ms-1" Text="0 items" />
          </h5>
          <asp:LinkButton ID="lbClearCart" runat="server" CssClass="btn btn-sm btn-falcon-default"
            OnClick="lbClearCart_Click" CausesValidation="false"
            OnClientClick="return confirm('Clear all items from the cart?');">
            <span class="fas fa-trash-alt me-1"></span>Clear</asp:LinkButton>
        </div>

        <div class="card-body p-3">

          <%-- ── Customer info ── --%>
          <div class="row g-2 mb-3 pb-3 border-bottom">
            <div class="col-6">
              <label class="form-label fs--1 mb-1">Customer Name</label>
              <asp:TextBox ID="txtCustomerName" runat="server"
                CssClass="form-control form-control-sm" placeholder="Optional" MaxLength="120" />
            </div>
            <div class="col-6">
              <label class="form-label fs--1 mb-1">Phone</label>
              <asp:TextBox ID="txtPhone" runat="server"
                CssClass="form-control form-control-sm" placeholder="03xx-xxxxxxx"
                TextMode="Phone" MaxLength="30" />
              <asp:RegularExpressionValidator ID="revPhone" runat="server"
                ControlToValidate="txtPhone" ValidationGroup="PlaceOrder"
                ValidationExpression="^[0-9+\-\s()]{7,20}$"
                ErrorMessage="Phone number is not valid." Display="Dynamic"
                CssClass="text-danger fs--2" Text="Invalid phone" />
            </div>
            <div class="col-6">
              <label class="form-label fs--1 mb-1">Order Type</label>
              <asp:DropDownList ID="ddlOrderType" runat="server"
                CssClass="form-select form-select-sm"
                AutoPostBack="true" CausesValidation="false"
                OnSelectedIndexChanged="ddlOrderType_Changed">
                <asp:ListItem Value="DineIn">Dine In</asp:ListItem>
                <asp:ListItem Value="Takeaway">Takeaway</asp:ListItem>
                <asp:ListItem Value="Delivery">Delivery</asp:ListItem>
              </asp:DropDownList>
            </div>
            <%-- Shown for DineIn --%>
            <asp:Panel ID="pnlTableNo" runat="server" CssClass="col-6">
              <label class="form-label fs--1 mb-1">
                Table No.<span class="text-danger ms-1">*</span>
              </label>
              <asp:TextBox ID="txtTableNo" runat="server"
                CssClass="form-control form-control-sm" placeholder="e.g. 5" MaxLength="20" />
              <asp:RequiredFieldValidator ID="rfvTableNo" runat="server"
                ControlToValidate="txtTableNo" ValidationGroup="PlaceOrder"
                ErrorMessage="Table number is required for a Dine In order." Display="Dynamic"
                CssClass="text-danger fs--2" Text="Required" />
            </asp:Panel>
            <%-- Shown for Delivery --%>
            <asp:Panel ID="pnlAddress" runat="server" CssClass="col-12" Visible="false">
              <label class="form-label fs--1 mb-1">
                Delivery Address<span class="text-danger ms-1">*</span>
              </label>
              <asp:TextBox ID="txtAddress" runat="server"
                CssClass="form-control form-control-sm"
                TextMode="MultiLine" Rows="2" placeholder="Street, area..." MaxLength="300" />
              <asp:RequiredFieldValidator ID="rfvAddress" runat="server"
                ControlToValidate="txtAddress" ValidationGroup="PlaceOrder" Enabled="false"
                ErrorMessage="Delivery address is required for a Delivery order." Display="Dynamic"
                CssClass="text-danger fs--2" Text="Required" />
            </asp:Panel>
          </div>

          <%-- ── Cart ── --%>
          <asp:Panel ID="pnlEmptyCart" runat="server"
            CssClass="text-center text-600 py-4 fs--1 mb-3 border rounded">
            <span class="fas fa-shopping-cart fs-2 d-block mb-2 text-300"></span>
            No items added yet. Pick items from the menu.
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
                        <td class="ps-0">
                          <div class="text-truncate" style="max-width:140px" title='<%# Eval("Name") %>'><%# Eval("Name") %></div>
                          <div class="text-600 fs--2">Rs.&#160;<%# Eval("UnitPrice", "{0:N0}") %> ea.</div>
                        </td>
                        <td class="text-center">
                          <div class="d-flex align-items-center justify-content-center gap-1">
                            <asp:LinkButton ID="lbMinus" runat="server"
                              CommandName="Minus"
                              CommandArgument='<%# Eval("ItemID") %>'
                              CssClass="btn btn-sm btn-falcon-default px-2 py-0 lh-sm"
                              CausesValidation="false" ToolTip="Decrease">&#8722;</asp:LinkButton>
                            <span class="fw-semibold px-1" style="min-width:20px;text-align:center"><%# Eval("Qty") %></span>
                            <asp:LinkButton ID="lbPlus" runat="server"
                              CommandName="Plus"
                              CommandArgument='<%# Eval("ItemID") %>'
                              CssClass="btn btn-sm btn-falcon-default px-2 py-0 lh-sm"
                              CausesValidation="false" ToolTip="Increase">+</asp:LinkButton>
                          </div>
                        </td>
                        <td class="text-end pe-0 fw-semibold">Rs.&#160;<%# Eval("LineTotal", "{0:N0}") %></td>
                        <td class="text-center">
                          <asp:LinkButton ID="lbRemove" runat="server"
                            CommandName="Remove"
                            CommandArgument='<%# Eval("ItemID") %>'
                            CssClass="btn btn-sm btn-falcon-danger p-1 lh-1"
                            CausesValidation="false" ToolTip="Remove">&times;</asp:LinkButton>
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
                  Text="0" Width="58px" TextMode="Number"
                  AutoPostBack="true" CausesValidation="false"
                  OnTextChanged="txtDiscountPct_Changed" />
                <asp:Label ID="lblDiscountAmt" runat="server"
                  Text="Rs. 0" CssClass="text-nowrap text-danger" />
              </div>
            </div>
            <asp:RangeValidator ID="rngDiscount" runat="server"
              ControlToValidate="txtDiscountPct" ValidationGroup="PlaceOrder"
              MinimumValue="0" MaximumValue="100" Type="Double"
              ErrorMessage="Discount must be between 0 and 100." Display="Dynamic"
              CssClass="text-danger fs--2 d-block text-end mb-1" Text="0–100 only" />
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
                TextMode="MultiLine" Rows="2" MaxLength="500"
                placeholder="Special instructions..." />
            </div>
          </div>

          <%-- ── Submit ── --%>
          <asp:Button ID="btnPlaceOrder" runat="server"
            CssClass="btn btn-primary w-100"
            Text="Place Order"
            ValidationGroup="PlaceOrder"
            UseSubmitBehavior="true"
            OnClick="btnPlaceOrder_Click"
            OnClientClick="if(typeof Page_ClientValidate==='function' &amp;&amp; !Page_ClientValidate('PlaceOrder')){return false;}" />

        </div>
      </div>
    </div>

  </div>

</asp:Content>
