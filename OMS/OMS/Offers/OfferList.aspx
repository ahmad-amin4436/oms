<%@ Page Title="Offers" Language="C#" MasterPageFile="~/Site.Master" AutoEventWireup="true"
   CodeBehind="OfferList.aspx.cs" Inherits="OMS.Offers.OfferList" %>

<asp:Content ID="Content1" ContentPlaceHolderID="MainContent" runat="server">

  <%-- ── Page header ── --%>
  <div class="d-flex align-items-center justify-content-between mb-3">
    <div>
      <h4 class="mb-0">Offers &amp; Coupons</h4>
      <p class="text-600 fs--1 mb-0">Promotional discounts and deals.</p>
    </div>
  </div>

  <asp:UpdatePanel ID="updOffers" runat="server">
    <ContentTemplate>

      <asp:Label ID="lblMsg" runat="server" Visible="false"
        CssClass="alert alert-success d-block mb-3 py-2 fs--1"
        EnableViewState="false" />

      <%-- Filter --%>
      <div class="card mb-3">
        <div class="card-body py-2 d-flex gap-2">
          <asp:LinkButton ID="lbAll" runat="server" CssClass="btn btn-sm btn-primary"
            OnClick="lbAll_Click">All</asp:LinkButton>
          <asp:LinkButton ID="lbActive" runat="server" CssClass="btn btn-sm btn-falcon-default"
            OnClick="lbActive_Click">Active</asp:LinkButton>
          <asp:LinkButton ID="lbInactive" runat="server" CssClass="btn btn-sm btn-falcon-default"
            OnClick="lbInactive_Click">Inactive</asp:LinkButton>
        </div>
      </div>

      <div class="card">
        <div class="table-responsive">
          <asp:GridView ID="gvOffers" runat="server"
            CssClass="table table-sm table-hover align-middle mb-0"
            AutoGenerateColumns="False" GridLines="None"
            EmptyDataText="No offers found."
            OnRowCommand="gvOffers_RowCommand">
            <EmptyDataRowStyle CssClass="text-center text-600 py-4 fs--1" />
            <HeaderStyle CssClass="bg-light border-bottom" />
            <Columns>
              <asp:BoundField DataField="Title" HeaderText="Title"
                HeaderStyle-CssClass="ps-3 fw-medium"
                ItemStyle-CssClass="ps-3 fw-semibold" />
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
              <asp:BoundField DataField="StartDate" HeaderText="Start"
                DataFormatString="{0:dd MMM yyyy}"
                HeaderStyle-CssClass="fw-medium"
                ItemStyle-CssClass="text-600" />
              <asp:BoundField DataField="EndDate" HeaderText="End"
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
                    CommandArgument='<%# Eval("OfferID") %>'
                    CssClass='<%# "btn btn-sm px-2 py-0 fs--2 " + ((bool)Eval("IsActive") ? "btn-falcon-warning" : "btn-falcon-success") %>'>
                    <%# (bool)Eval("IsActive") ? "Deactivate" : "Activate" %>
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
