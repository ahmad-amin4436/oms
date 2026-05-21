<%@ Page Title="Pricing" Language="C#" MasterPageFile="~/Site.Master" AutoEventWireup="true" CodeBehind="Pricing.aspx.cs" Inherits="OMS.Menu.Pricing" %>
<asp:Content ID="Content1" ContentPlaceHolderID="MainContent" runat="server">
  <div class="rms-page-header"><div><h3 class="mb-0">Sizes & Pricing</h3><p class="mb-0 text-600">Matrix of calculated and custom prices.</p></div></div>
  <div class="card rms-card-table"><div class="table-responsive"><asp:GridView ID="gvPricing" runat="server" CssClass="table table-sm" AutoGenerateColumns="true" GridLines="None" /></div></div>
</asp:Content>
