<%@ Page Title="Deals" Language="C#" MasterPageFile="~/Site.Master" AutoEventWireup="true"
   CodeBehind="DealsList.aspx.cs" Inherits="OMS.Deals.DealsList" %>

<asp:Content ID="Content1" ContentPlaceHolderID="MainContent" runat="server">

  <%-- ── Page header ── --%>
  <div class="d-flex flex-wrap align-items-center justify-content-between gap-2 mb-3">
    <div>
      <h4 class="mb-0">Deals</h4>
      <p class="text-600 fs--1 mb-0">All promotional deals and their active windows.</p>
    </div>
    <a href="CreateDeals.aspx" class="btn btn-sm btn-primary flex-shrink-0">
      <span class="fas fa-plus me-1"></span> Create Deal
    </a>
  </div>

  <asp:UpdatePanel ID="updDeals" runat="server">
    <ContentTemplate>

      <asp:Label ID="lblMsg" runat="server" Visible="false"
        CssClass="alert alert-success d-block mb-3 py-2 fs--1"
        EnableViewState="false" />
      <asp:Label ID="lblErr" runat="server" Visible="false"
        CssClass="alert alert-danger d-block mb-3 py-2 fs--1"
        EnableViewState="false" />

      <%-- Filter --%>
      <div class="card mb-3">
        <div class="card-body py-2 d-flex gap-2">
          <asp:LinkButton ID="lbAll" runat="server" CssClass="btn btn-sm btn-primary"
            CausesValidation="false" OnClick="lbAll_Click">All</asp:LinkButton>
          <asp:LinkButton ID="lbActive" runat="server" CssClass="btn btn-sm btn-falcon-default"
            CausesValidation="false" OnClick="lbActive_Click">Active</asp:LinkButton>
          <asp:LinkButton ID="lbInactive" runat="server" CssClass="btn btn-sm btn-falcon-default"
            CausesValidation="false" OnClick="lbInactive_Click">Inactive</asp:LinkButton>
        </div>
      </div>

      <div class="card">
        <div class="table-responsive">
          <asp:GridView ID="gvDeals" runat="server"
            CssClass="table table-sm table-hover align-middle mb-0"
            AutoGenerateColumns="False" GridLines="None"
            DataKeyNames="DealID"
            EmptyDataText="No deals found."
            OnRowCommand="gvDeals_RowCommand">
            <EmptyDataRowStyle CssClass="text-center text-600 py-4 fs--1" />
            <HeaderStyle CssClass="bg-light border-bottom" />
            <Columns>
              <asp:BoundField DataField="Title" HeaderText="Title"
                HeaderStyle-CssClass="ps-3 fw-medium"
                ItemStyle-CssClass="ps-3 fw-semibold" />
              <asp:BoundField DataField="DealType" HeaderText="Type"
                HeaderStyle-CssClass="fw-medium"
                ItemStyle-CssClass="text-600" />
              <asp:TemplateField HeaderText="Value"
                HeaderStyle-CssClass="text-end fw-medium"
                ItemStyle-CssClass="text-end fw-semibold">
                <ItemTemplate>
                  <%# FormatDealValue(Eval("DealType").ToString(),
                        (decimal)Eval("DiscountValue"),
                        Eval("DealPrice")) %>
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
              <asp:TemplateField HeaderText="Actions"
                HeaderStyle-CssClass="text-end fw-medium pe-3"
                ItemStyle-CssClass="text-end pe-3">
                <ItemTemplate>
                  <div class="d-inline-flex gap-1">
                    <asp:HyperLink runat="server"
                      NavigateUrl='<%# "CreateDeals.aspx?id=" + Eval("DealID") %>'
                      CssClass="btn btn-sm btn-falcon-default px-2 py-0 fs--2" ToolTip="Edit">
                      <span class="fas fa-edit"></span>
                    </asp:HyperLink>
                    <asp:LinkButton runat="server"
                      CommandName="Toggle"
                      CommandArgument='<%# Eval("DealID") %>'
                      CausesValidation="false"
                      CssClass='<%# "btn btn-sm px-2 py-0 fs--2 " + ((bool)Eval("IsActive") ? "btn-falcon-warning" : "btn-falcon-success") %>'>
                      <%# (bool)Eval("IsActive") ? "Deactivate" : "Activate" %>
                    </asp:LinkButton>
                    <asp:LinkButton runat="server"
                      CommandName="DeleteDeal"
                      CommandArgument='<%# Eval("DealID") %>'
                      CausesValidation="false"
                      CssClass="btn btn-sm btn-falcon-danger px-2 py-0 fs--2"
                      ToolTip="Delete"
                      OnClientClick="return confirm('Permanently delete this deal?');">
                      <span class="fas fa-trash-alt"></span>
                    </asp:LinkButton>
                  </div>
                </ItemTemplate>
              </asp:TemplateField>
            </Columns>
          </asp:GridView>
        </div>
      </div>

    </ContentTemplate>
  </asp:UpdatePanel>

</asp:Content>
