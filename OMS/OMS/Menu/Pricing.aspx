<%@ Page Title="Pricing" Language="C#" MasterPageFile="~/Site.Master" AutoEventWireup="true"
   CodeBehind="Pricing.aspx.cs" Inherits="OMS.Menu.Pricing" %>

<asp:Content ID="Content1" ContentPlaceHolderID="MainContent" runat="server">

  <div class="d-flex align-items-center justify-content-between mb-3">
    <div>
      <h4 class="mb-0">Sizes &amp; Pricing</h4>
      <p class="text-600 fs--1 mb-0">Per-item size pricing matrix — calculated vs. custom.</p>
    </div>
  </div>

  <div class="card">
    <div class="table-responsive">
      <asp:GridView ID="gvPricing" runat="server"
        CssClass="table table-sm table-hover align-middle mb-0"
        AutoGenerateColumns="False" GridLines="None"
        EmptyDataText="No pricing data found.">
        <EmptyDataRowStyle CssClass="text-center text-600 py-4 fs--1" />
        <HeaderStyle CssClass="bg-light border-bottom" />
        <Columns>
          <asp:BoundField DataField="ItemName" HeaderText="Item"
            HeaderStyle-CssClass="ps-3 fw-medium"
            ItemStyle-CssClass="ps-3 fw-semibold" />
          <asp:BoundField DataField="SizeName" HeaderText="Size"
            HeaderStyle-CssClass="fw-medium"
            ItemStyle-CssClass="text-600" />
          <asp:BoundField DataField="CalculatedPrice" HeaderText="Calculated"
            DataFormatString="Rs.&#160;{0:N0}"
            HeaderStyle-CssClass="text-end fw-medium"
            ItemStyle-CssClass="text-end text-600" />
          <asp:TemplateField HeaderText="Custom Price"
            HeaderStyle-CssClass="text-end fw-medium"
            ItemStyle-CssClass="text-end">
            <ItemTemplate>
              <%# DBNull.Value.Equals(Eval("CustomPrice")) ? "<span class=\"text-300\">—</span>" : "Rs.&#160;" + string.Format("{0:N0}", Eval("CustomPrice")) %>
            </ItemTemplate>
          </asp:TemplateField>
          <asp:BoundField DataField="EffectivePrice" HeaderText="Effective"
            DataFormatString="Rs.&#160;{0:N0}"
            HeaderStyle-CssClass="text-end pe-3 fw-medium"
            ItemStyle-CssClass="text-end pe-3 fw-semibold text-primary" />
        </Columns>
      </asp:GridView>
    </div>
  </div>

</asp:Content>
