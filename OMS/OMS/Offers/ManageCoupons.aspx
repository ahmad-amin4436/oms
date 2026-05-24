<%@ Page Title="Coupons" Language="C#" MasterPageFile="~/Site.Master" AutoEventWireup="true"
   CodeBehind="ManageCoupons.aspx.cs" Inherits="OMS.Offers.ManageCoupons" %>

<asp:Content ID="Content1" ContentPlaceHolderID="MainContent" runat="server">

  <%-- ── Page header ── --%>
  <div class="d-flex align-items-center justify-content-between mb-3">
    <div>
      <h4 class="mb-0">Coupons</h4>
      <p class="text-600 fs--1 mb-0">Coupon codes, usage limits, and expiry dates.</p>
    </div>
  </div>

  <asp:UpdatePanel ID="updCoupons" runat="server">
    <ContentTemplate>

      <asp:Label ID="lblMsg" runat="server" Visible="false"
        CssClass="alert alert-success d-block mb-3 py-2 fs--1"
        EnableViewState="false" />

      <div class="card">
        <div class="table-responsive">
          <asp:GridView ID="gvCoupons" runat="server"
            CssClass="table table-sm table-hover align-middle mb-0"
            AutoGenerateColumns="False" GridLines="None"
            EmptyDataText="No coupons defined."
            OnRowCommand="gvCoupons_RowCommand">
            <EmptyDataRowStyle CssClass="text-center text-600 py-4 fs--1" />
            <HeaderStyle CssClass="bg-light border-bottom" />
            <Columns>
              <asp:BoundField DataField="Code" HeaderText="Code"
                HeaderStyle-CssClass="ps-3 fw-medium"
                ItemStyle-CssClass="ps-3 fw-bold font-monospace text-primary" />
              <asp:BoundField DataField="DiscountType" HeaderText="Type"
                HeaderStyle-CssClass="fw-medium"
                ItemStyle-CssClass="text-600" />
              <asp:TemplateField HeaderText="Discount"
                HeaderStyle-CssClass="text-end fw-medium"
                ItemStyle-CssClass="text-end fw-semibold">
                <ItemTemplate>
                  <%# FormatDiscount(Eval("DiscountType").ToString(), (decimal)Eval("DiscountValue")) %>
                </ItemTemplate>
              </asp:TemplateField>
              <asp:TemplateField HeaderText="Usage"
                HeaderStyle-CssClass="text-center fw-medium"
                ItemStyle-CssClass="text-center text-600">
                <ItemTemplate>
                  <%# Eval("UsedCount") %> / <%# Convert.ToInt32(Eval("MaxUses")) == 0 ? "∞" : Eval("MaxUses").ToString() %>
                </ItemTemplate>
              </asp:TemplateField>
              <asp:BoundField DataField="ExpiryDate" HeaderText="Expires"
                DataFormatString="{0:dd MMM yyyy}"
                HeaderStyle-CssClass="fw-medium"
                ItemStyle-CssClass="text-600" />
              <asp:TemplateField HeaderText="Status"
                HeaderStyle-CssClass="text-center fw-medium"
                ItemStyle-CssClass="text-center">
                <ItemTemplate>
                  <span class='badge <%# (bool)Eval("IsActive") ? "badge-subtle-success" : "badge-subtle-secondary" %>'>
                    <%# (bool)Eval("IsActive") ? "Active" : "Inactive" %>
                  </span>
                </ItemTemplate>
              </asp:TemplateField>
              <asp:TemplateField
                HeaderStyle-CssClass="text-center fw-medium"
                ItemStyle-CssClass="text-center pe-3">
                <ItemTemplate>
                  <asp:LinkButton runat="server"
                    CommandName="Toggle"
                    CommandArgument='<%# Eval("CouponID") %>'
                    CssClass='<%# "btn btn-sm px-2 py-0 fs--2 " + ((bool)Eval("IsActive") ? "btn-falcon-warning" : "btn-falcon-success") %>'>
                    <%# (bool)Eval("IsActive") ? "Disable" : "Enable" %>
                  </asp:LinkButton>
                </ItemTemplate>
              </asp:TemplateField>
            </Columns>
          </asp:GridView>
        </div>
      </div>

    </ContentTemplate>
  </asp:UpdatePanel>

</asp:Content>
