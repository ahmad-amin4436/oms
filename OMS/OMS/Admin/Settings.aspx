<%@ Page Title="Settings" Language="C#" MasterPageFile="~/Site.Master" AutoEventWireup="true"
   CodeBehind="Settings.aspx.cs" Inherits="OMS.Admin.Settings" %>

<asp:Content ID="Content1" ContentPlaceHolderID="MainContent" runat="server">

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
      <h5 class="mb-0 fs-0">Tax</h5>
    </div>
    <div class="card-body">
      <label for="<%= txtTaxPercent.ClientID %>" class="form-label fs--1">Tax percentage (%)</label>
      <div class="input-group input-group-sm mb-1">
        <asp:TextBox ID="txtTaxPercent" runat="server" CssClass="form-control" MaxLength="6" />
        <span class="input-group-text">%</span>
      </div>
      <asp:RangeValidator ID="rngTax" runat="server" ControlToValidate="txtTaxPercent"
        MinimumValue="0" MaximumValue="100" Type="Double" ValidationGroup="Settings"
        ErrorMessage="Enter a number between 0 and 100." Display="Dynamic"
        CssClass="text-danger fs--2 d-block mb-1" />
      <asp:RequiredFieldValidator ID="rfvTax" runat="server" ControlToValidate="txtTaxPercent"
        ValidationGroup="Settings" ErrorMessage="Tax percentage is required." Display="Dynamic"
        CssClass="text-danger fs--2 d-block mb-1" />
      <p class="fs--2 text-600 mb-3">
        Applies to new orders only. Orders already placed keep the tax they were created with.
      </p>
      <asp:Button ID="btnSave" runat="server" Text="Save" ValidationGroup="Settings"
        CssClass="btn btn-primary btn-sm" OnClick="btnSave_Click" />
    </div>
  </div>

</asp:Content>
