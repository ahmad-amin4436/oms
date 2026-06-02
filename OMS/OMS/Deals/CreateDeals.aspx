<%@ Page Title="Create Deal" Language="C#" MasterPageFile="~/Site.Master" AutoEventWireup="true"
   CodeBehind="CreateDeals.aspx.cs" Inherits="OMS.Deals.CreateDeals" %>

<asp:Content ID="Content1" ContentPlaceHolderID="MainContent" runat="server">

  <%-- ── Page header ── --%>
  <div class="d-flex flex-wrap align-items-center justify-content-between gap-2 mb-3">
    <div>
      <h4 class="mb-0"><asp:Literal ID="litTitle" runat="server" Text="Create Deal" /></h4>
      <p class="text-600 fs--1 mb-0">Define a promotional deal and its active window.</p>
    </div>
    <a href="DealsList.aspx" class="btn btn-sm btn-falcon-default flex-shrink-0">
      <span class="fas fa-list me-1"></span> Deals List
    </a>
  </div>

  <asp:UpdatePanel ID="updDeal" runat="server">
    <ContentTemplate>

      <asp:Label ID="lblMsg" runat="server" Visible="false"
        CssClass="alert alert-success d-block mb-3 py-2 fs--1"
        EnableViewState="false" />
      <asp:Label ID="lblErr" runat="server" Visible="false"
        CssClass="alert alert-danger d-block mb-3 py-2 fs--1"
        EnableViewState="false" />

      <div class="card">
        <div class="card-body">
          <asp:HiddenField ID="hfDealID" runat="server" Value="0" />
          <div class="row g-3">

            <div class="col-md-8">
              <label class="form-label fs--1 mb-1">Title<span class="text-danger ms-1">*</span></label>
              <asp:TextBox ID="txtTitle" runat="server" CssClass="form-control form-control-sm" MaxLength="150" />
              <asp:RequiredFieldValidator runat="server" ControlToValidate="txtTitle"
                ValidationGroup="Deal" Display="Dynamic"
                CssClass="text-danger fs--2" Text="Title is required." />
            </div>

            <div class="col-md-4">
              <label class="form-label fs--1 mb-1">Deal Type<span class="text-danger ms-1">*</span></label>
              <asp:DropDownList ID="ddlDealType" runat="server" CssClass="form-select form-select-sm"
                AutoPostBack="true" OnSelectedIndexChanged="ddlDealType_SelectedIndexChanged">
                <asp:ListItem Text="Percentage Off" Value="Percentage" />
                <asp:ListItem Text="Flat Amount Off" Value="Flat" />
                <asp:ListItem Text="Bundle Price" Value="BundlePrice" />
              </asp:DropDownList>
            </div>

            <%-- Discount value (Percentage / Flat) --%>
            <asp:Panel ID="pnlDiscount" runat="server" CssClass="col-md-4">
              <label class="form-label fs--1 mb-1">
                <asp:Literal ID="litValueLabel" runat="server" Text="Discount Value" /><span class="text-danger ms-1">*</span>
              </label>
              <asp:TextBox ID="txtDiscountValue" runat="server" CssClass="form-control form-control-sm"
                TextMode="Number" />
            </asp:Panel>

            <%-- Bundle price --%>
            <asp:Panel ID="pnlBundle" runat="server" Visible="false" CssClass="col-md-4">
              <label class="form-label fs--1 mb-1">Bundle Price (Rs.)<span class="text-danger ms-1">*</span></label>
              <asp:TextBox ID="txtDealPrice" runat="server" CssClass="form-control form-control-sm"
                TextMode="Number" />
            </asp:Panel>

            <div class="col-md-4">
              <label class="form-label fs--1 mb-1">Start Date<span class="text-danger ms-1">*</span></label>
              <asp:TextBox ID="txtStartDate" runat="server" CssClass="form-control form-control-sm" TextMode="Date" />
              <asp:RequiredFieldValidator runat="server" ControlToValidate="txtStartDate"
                ValidationGroup="Deal" Display="Dynamic"
                CssClass="text-danger fs--2" Text="Start date is required." />
            </div>

            <div class="col-md-4">
              <label class="form-label fs--1 mb-1">End Date<span class="text-danger ms-1">*</span></label>
              <asp:TextBox ID="txtEndDate" runat="server" CssClass="form-control form-control-sm" TextMode="Date" />
              <asp:RequiredFieldValidator runat="server" ControlToValidate="txtEndDate"
                ValidationGroup="Deal" Display="Dynamic"
                CssClass="text-danger fs--2" Text="End date is required." />
            </div>

            <div class="col-12">
              <label class="form-label fs--1 mb-1">Description</label>
              <asp:TextBox ID="txtDescription" runat="server" CssClass="form-control form-control-sm"
                TextMode="MultiLine" Rows="2" MaxLength="500" placeholder="Optional" />
            </div>

            <%-- ── Menu items in this deal ── --%>
            <div class="col-12">
              <label class="form-label fs--1 mb-1 d-block">Menu Items in this Deal</label>
              <p class="fs--2 text-600 mb-2">
                Tick the menu items to include. Both available and unavailable items can be added.
              </p>
              <div class="border rounded p-2" style="max-height:320px; overflow-y:auto;">
                <asp:Repeater ID="rptDealCats" runat="server" OnItemDataBound="rptDealCats_ItemDataBound">
                  <ItemTemplate>
                    <div class="mb-2">
                      <div class="fw-semibold fs--1 text-700 border-bottom pb-1 mb-1">
                        <%# Server.HtmlEncode(Convert.ToString(Eval("CategoryName"))) %>
                      </div>
                      <input type="hidden" runat="server" id="hfCategoryId" value='<%# Eval("CategoryID") %>' />
                      <div class="ms-2">
                        <asp:Repeater runat="server" ID="rptDealItems">
                          <ItemTemplate>
                            <div class="form-check py-1">
                              <asp:CheckBox runat="server" ID="chkItem" CssClass="form-check-input"
                                Checked='<%# (bool)Eval("Selected") %>' />
                              <input type="hidden" runat="server" id="hfItemId" value='<%# Eval("ItemID") %>' />
                              <label class="form-check-label fs--1">
                                <%# Server.HtmlEncode(Convert.ToString(Eval("ItemName"))) %>
                                <span class='badge ms-1 fs--2 <%# (bool)Eval("IsAvailable") ? "badge-subtle-success" : "badge-subtle-danger" %>'>
                                  <%# (bool)Eval("IsAvailable") ? "Available" : "Unavailable" %>
                                </span>
                              </label>
                            </div>
                          </ItemTemplate>
                        </asp:Repeater>
                      </div>
                    </div>
                  </ItemTemplate>
                </asp:Repeater>
                <asp:Panel ID="pnlNoItems" runat="server" Visible="false" CssClass="text-center text-600 py-3 fs--1">
                  No menu items exist yet.
                </asp:Panel>
              </div>
            </div>

            <div class="col-12">
              <div class="form-check mb-0">
                <asp:CheckBox ID="chkActive" runat="server" CssClass="form-check-input" Checked="true" />
                <label class="form-check-label fs--1">Active</label>
              </div>
            </div>

            <div class="col-12 d-flex gap-2 border-top pt-3">
              <asp:Button ID="btnSave" runat="server" CssClass="btn btn-sm btn-primary"
                Text="Save Deal" ValidationGroup="Deal" OnClick="btnSave_Click" />
              <asp:Button ID="btnReset" runat="server" CssClass="btn btn-sm btn-falcon-default"
                Text="Reset" CausesValidation="false" OnClick="btnReset_Click" />
            </div>

          </div>
        </div>
      </div>

    </ContentTemplate>
  </asp:UpdatePanel>

</asp:Content>
