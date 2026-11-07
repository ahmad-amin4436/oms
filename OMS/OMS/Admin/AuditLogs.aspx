<%@ Page Title="Audit Logs" Language="C#" MasterPageFile="~/Site.Master" AutoEventWireup="true"
    CodeBehind="AuditLogs.aspx.cs" Inherits="OMS.Admin.AuditLogs" %>

<asp:Content ID="Content1" ContentPlaceHolderID="MainContent" runat="server">
  <div class="d-flex flex-wrap align-items-center justify-content-between gap-2 mb-3">
    <div>
      <h4 class="mb-0">Audit Logs</h4>
      <p class="text-600 fs--1 mb-0">Review important OMS activities recorded by the server.</p>
    </div>
  </div>

  <asp:UpdatePanel ID="updAudit" runat="server">
    <ContentTemplate>
      <asp:Label ID="lblErr" runat="server" Visible="false" CssClass="alert alert-danger d-block mb-3 py-2 fs--1" />
      <div class="card mb-3">
        <div class="card-body">
          <div class="row g-2 align-items-end">
            <div class="col-md-2"><label class="form-label fs--1">User</label><asp:DropDownList ID="ddlUser" runat="server" CssClass="form-select form-select-sm" /></div>
            <div class="col-md-2"><label class="form-label fs--1">Role</label><asp:DropDownList ID="ddlRole" runat="server" CssClass="form-select form-select-sm" /></div>
            <div class="col-md-2"><label class="form-label fs--1">Module</label><asp:DropDownList ID="ddlModule" runat="server" CssClass="form-select form-select-sm" /></div>
            <div class="col-md-2"><label class="form-label fs--1">Action</label><asp:DropDownList ID="ddlAction" runat="server" CssClass="form-select form-select-sm" /></div>
            <div class="col-md-1"><label class="form-label fs--1">From</label><asp:TextBox ID="txtStartDate" runat="server" TextMode="Date" CssClass="form-control form-control-sm" /></div>
            <div class="col-md-1"><label class="form-label fs--1">To</label><asp:TextBox ID="txtEndDate" runat="server" TextMode="Date" CssClass="form-control form-control-sm" /></div>
            <div class="col-md-1"><label class="form-label fs--1">Order ID</label><asp:TextBox ID="txtOrderID" runat="server" CssClass="form-control form-control-sm" /></div>
            <div class="col-md-1"><asp:Button ID="btnApply" runat="server" Text="Apply" CssClass="btn btn-primary btn-sm w-100" OnClick="btnApply_Click" /></div>
          </div>
          <div class="mt-2 d-flex flex-wrap gap-2">
            <asp:LinkButton ID="lbItemAdded" runat="server" Text="Item Added" CssClass="btn btn-sm btn-falcon-default" CommandArgument="AddOrderItem" OnClick="ActivityFilter_Click" />
            <asp:LinkButton ID="lbItemRemoved" runat="server" Text="Item Removed" CssClass="btn btn-sm btn-falcon-default" CommandArgument="DeleteOrderItem" OnClick="ActivityFilter_Click" />
            <asp:LinkButton ID="lbOrderEdited" runat="server" Text="Order Edited" CssClass="btn btn-sm btn-falcon-default" CommandArgument="EditOrder" OnClick="ActivityFilter_Click" />
            <asp:LinkButton ID="lbOrderCancelled" runat="server" Text="Order Cancelled" CssClass="btn btn-sm btn-falcon-default" CommandArgument="CancelOrder" OnClick="ActivityFilter_Click" />
            <asp:LinkButton ID="lbClear" runat="server" Text="Clear" CssClass="btn btn-sm btn-falcon-default" OnClick="Clear_Click" />
          </div>
        </div>
      </div>

      <div class="card">
        <div class="table-responsive">
          <asp:GridView ID="gvAudit" runat="server" AutoGenerateColumns="False" GridLines="None" CssClass="table table-sm table-hover align-middle mb-0" EmptyDataText="No audit records found.">
            <Columns>
              <asp:BoundField DataField="CreatedAt" HeaderText="Date/time" DataFormatString="{0:dd MMM yyyy, hh:mm tt}" />
              <asp:BoundField DataField="FullName" HeaderText="User" />
              <asp:BoundField DataField="RoleName" HeaderText="Role" />
              <asp:BoundField DataField="Module" HeaderText="Module" />
              <asp:BoundField DataField="Action" HeaderText="Action" />
              <asp:BoundField DataField="OrderID" HeaderText="Order ID" />
              <asp:BoundField DataField="Description" HeaderText="Description" />
              <asp:BoundField DataField="PreviousValue" HeaderText="Previous" />
              <asp:BoundField DataField="NewValue" HeaderText="New" />
              <asp:BoundField DataField="IPAddress" HeaderText="IP address" />
            </Columns>
          </asp:GridView>
        </div>
      </div>
    </ContentTemplate>
  </asp:UpdatePanel>
</asp:Content>
