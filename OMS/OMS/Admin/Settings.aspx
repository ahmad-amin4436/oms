<%@ Page Title="Settings" Language="C#" MasterPageFile="~/Site.Master" AutoEventWireup="true"
   CodeBehind="Settings.aspx.cs" Inherits="OMS.Admin.Settings" %>

<asp:Content ID="Content1" ContentPlaceHolderID="MainContent" runat="server">
  <%-- Partial-page updates: actions refresh this panel only, never the whole page. --%>
  <asp:UpdatePanel ID="updSettings" runat="server" UpdateMode="Always"><ContentTemplate>

  <div class="d-flex align-items-center justify-content-between mb-3">
    <div>
      <h4 class="mb-0">Settings</h4>
      <p class="text-600 fs--1 mb-0">System-wide order settings.</p>
    </div>
  </div>

  <asp:Label ID="lblMsg" runat="server" Visible="false" EnableViewState="false"
    CssClass="alert alert-success d-block mb-3 py-2 fs--1" />

  <div class="card" style="max-width:480px;">
    <div class="card-header py-2">
      <h5 class="mb-0 fs-0">Tax by payment method</h5>
    </div>
    <div class="card-body">

      <label class="form-label fs--1 mb-1">Cash</label>
      <div class="input-group input-group-sm mb-1">
        <asp:TextBox ID="txtTaxCash" runat="server" CssClass="form-control" MaxLength="6" />
        <span class="input-group-text">%</span>
      </div>
      <asp:RangeValidator ID="rngCash" runat="server" ControlToValidate="txtTaxCash" MinimumValue="0" MaximumValue="100"
        Type="Double" ValidationGroup="Settings" ErrorMessage="Cash: enter 0 to 100." Display="Dynamic" CssClass="text-danger fs--2 d-block" />
      <asp:RequiredFieldValidator ID="rfvCash" runat="server" ControlToValidate="txtTaxCash" ValidationGroup="Settings"
        ErrorMessage="Cash rate is required." Display="Dynamic" CssClass="text-danger fs--2 d-block" />

      <label class="form-label fs--1 mb-1 mt-2">Card</label>
      <div class="input-group input-group-sm mb-1">
        <asp:TextBox ID="txtTaxCard" runat="server" CssClass="form-control" MaxLength="6" />
        <span class="input-group-text">%</span>
      </div>
      <asp:RangeValidator ID="rngCard" runat="server" ControlToValidate="txtTaxCard" MinimumValue="0" MaximumValue="100"
        Type="Double" ValidationGroup="Settings" ErrorMessage="Card: enter 0 to 100." Display="Dynamic" CssClass="text-danger fs--2 d-block" />
      <asp:RequiredFieldValidator ID="rfvCard" runat="server" ControlToValidate="txtTaxCard" ValidationGroup="Settings"
        ErrorMessage="Card rate is required." Display="Dynamic" CssClass="text-danger fs--2 d-block" />

      <label class="form-label fs--1 mb-1 mt-2">Wallet</label>
      <div class="input-group input-group-sm mb-1">
        <asp:TextBox ID="txtTaxWallet" runat="server" CssClass="form-control" MaxLength="6" />
        <span class="input-group-text">%</span>
      </div>
      <asp:RangeValidator ID="rngWallet" runat="server" ControlToValidate="txtTaxWallet" MinimumValue="0" MaximumValue="100"
        Type="Double" ValidationGroup="Settings" ErrorMessage="Wallet: enter 0 to 100." Display="Dynamic" CssClass="text-danger fs--2 d-block" />
      <asp:RequiredFieldValidator ID="rfvWallet" runat="server" ControlToValidate="txtTaxWallet" ValidationGroup="Settings"
        ErrorMessage="Wallet rate is required." Display="Dynamic" CssClass="text-danger fs--2 d-block" />

      <label class="form-label fs--1 mb-1 mt-2">Bank Transfer</label>
      <div class="input-group input-group-sm mb-1">
        <asp:TextBox ID="txtTaxBank" runat="server" CssClass="form-control" MaxLength="6" />
        <span class="input-group-text">%</span>
      </div>
      <asp:RangeValidator ID="rngBank" runat="server" ControlToValidate="txtTaxBank" MinimumValue="0" MaximumValue="100"
        Type="Double" ValidationGroup="Settings" ErrorMessage="Bank Transfer: enter 0 to 100." Display="Dynamic" CssClass="text-danger fs--2 d-block" />
      <asp:RequiredFieldValidator ID="rfvBank" runat="server" ControlToValidate="txtTaxBank" ValidationGroup="Settings"
        ErrorMessage="Bank Transfer rate is required." Display="Dynamic" CssClass="text-danger fs--2 d-block" />

      <p class="fs--2 text-600 mb-3 mt-2">
        The order's payment method decides which rate applies. Applies to new orders only: orders already
        placed keep the tax they were created with.
      </p>
      <asp:Button ID="btnSave" runat="server" Text="Save" ValidationGroup="Settings"
        CssClass="btn btn-primary btn-sm" OnClick="btnSave_Click" />
    </div>
  </div>

  </ContentTemplate></asp:UpdatePanel>

</asp:Content>
