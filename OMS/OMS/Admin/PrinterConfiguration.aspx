<%@ Page Title="Printer Configuration" Language="C#" MasterPageFile="~/Site.Master" AutoEventWireup="true"
   CodeBehind="PrinterConfiguration.aspx.cs" Inherits="OMS.Admin.PrinterConfiguration" %>

<asp:Content ID="Content1" ContentPlaceHolderID="MainContent" runat="server">
  <asp:UpdatePanel ID="updPrinters" runat="server" UpdateMode="Always">
    <ContentTemplate>
      <div class="d-flex align-items-center justify-content-between mb-3">
        <div>
          <h4 class="mb-0">Printer Configuration</h4>
          <p class="text-600 fs--1 mb-0">Configure the local printer assigned to each kitchen department.</p>
        </div>
      </div>

      <asp:Label ID="lblMsg" runat="server" Visible="false" EnableViewState="false"
        CssClass="alert alert-success d-block mb-3 py-2 fs--1" />
      <asp:Label ID="lblErr" runat="server" Visible="false" EnableViewState="false"
        CssClass="alert alert-danger d-block mb-3 py-2 fs--1" />

      <div class="alert alert-info py-2 fs--1 mb-3">
        Printer connectivity must be tested by the Windows Service on the restaurant network.
        This page does not connect directly to local printers.
      </div>

      <div class="card">
        <div class="table-responsive">
          <asp:GridView ID="gvPrinters" runat="server" CssClass="table table-sm table-hover align-middle mb-0"
            AutoGenerateColumns="False" GridLines="None" DataKeyNames="DepartmentID"
            EmptyDataText="No departments have been configured." OnRowCommand="gvPrinters_RowCommand">
            <EmptyDataRowStyle CssClass="text-center text-600 py-4 fs--1" />
            <HeaderStyle CssClass="bg-light border-bottom" />
            <Columns>
              <asp:BoundField DataField="DepartmentName" HeaderText="Department"
                HeaderStyle-CssClass="ps-3 fw-medium" ItemStyle-CssClass="ps-3 fw-semibold" />
              <asp:TemplateField HeaderText="LAN host" HeaderStyle-CssClass="fw-medium">
                <ItemTemplate>
                  <asp:TextBox ID="txtPrinterIP" runat="server" Text='<%# Eval("PrinterIP") %>'
                    CssClass="form-control form-control-sm" MaxLength="255" placeholder="IP address or host name" />
                </ItemTemplate>
              </asp:TemplateField>
              <asp:TemplateField HeaderText="USB queue name" HeaderStyle-CssClass="fw-medium">
                <ItemTemplate>
                  <asp:TextBox ID="txtPrinterName" runat="server" Text='<%# Eval("PrinterName") %>'
                    CssClass="form-control form-control-sm" MaxLength="255" placeholder="Windows printer name" />
                </ItemTemplate>
              </asp:TemplateField>
              <asp:TemplateField HeaderText="Port" HeaderStyle-CssClass="fw-medium" ItemStyle-Width="110px">
                <ItemTemplate>
                  <asp:TextBox ID="txtPrinterPort" runat="server" Text='<%# Eval("PrinterPort") %>'
                    CssClass="form-control form-control-sm" TextMode="Number" min="1" max="65535" placeholder="Default 9100" />
                </ItemTemplate>
              </asp:TemplateField>
              <asp:TemplateField HeaderText="Enabled" HeaderStyle-CssClass="text-center fw-medium" ItemStyle-CssClass="text-center">
                <ItemTemplate>
                  <asp:CheckBox ID="chkPrinterEnabled" runat="server" Checked='<%# Convert.ToBoolean(Eval("PrinterEnabled")) %>' />
                </ItemTemplate>
              </asp:TemplateField>
              <asp:TemplateField HeaderText="Last service test" HeaderStyle-CssClass="fw-medium">
                <ItemTemplate>
                  <div class="fs--2">
                    <%# Eval("LastPrinterTestResult") == DBNull.Value ? "Not tested" : Server.HtmlEncode(Convert.ToString(Eval("LastPrinterTestResult"))) %>
                    <%# Eval("LastPrinterTestAt") == DBNull.Value ? "" : " - " + Convert.ToDateTime(Eval("LastPrinterTestAt")).ToLocalTime().ToString("g") %>
                  </div>
                </ItemTemplate>
              </asp:TemplateField>
              <asp:TemplateField HeaderText="Actions" HeaderStyle-CssClass="text-end fw-medium pe-3" ItemStyle-CssClass="text-end pe-3">
                <ItemTemplate>
                  <asp:LinkButton ID="btnSavePrinter" runat="server" CommandName="SavePrinter"
                    CommandArgument='<%# Eval("DepartmentID") %>' CausesValidation="false"
                    CssClass="btn btn-sm btn-primary px-2 py-0">Save</asp:LinkButton>
                </ItemTemplate>
              </asp:TemplateField>
            </Columns>
          </asp:GridView>
        </div>
      </div>
    </ContentTemplate>
  </asp:UpdatePanel>
</asp:Content>
