<%@ Page Title="Admin Dashboard" Language="C#" MasterPageFile="~/Site.Master" AutoEventWireup="true"
   CodeBehind="AdminDashboard.aspx.cs" Inherits="OMS.Admin.AdminDashboard" %>

<asp:Content ID="Content1" ContentPlaceHolderID="MainContent" runat="server">

  <%-- ── Page header ── --%>
  <div class="d-flex align-items-center justify-content-between mb-3">
    <div>
      <h4 class="mb-0">Admin Dashboard</h4>
      <p class="text-600 fs--1 mb-0">System overview: users, menu, and messages.</p>
    </div>
  </div>

  <%-- ── Quick stats ── --%>
  <div class="row g-3 mb-3">
    <div class="col-sm-6 col-xl-3">
      <div class="card h-100">
        <div class="card-body">
          <h6 class="text-600 fs--1 mb-2">Total Users</h6>
          <h3 class="mb-0">
            <asp:Label ID="lblUserCount" runat="server" Text="0" />
          </h3>
        </div>
      </div>
    </div>
    <div class="col-sm-6 col-xl-3">
      <div class="card h-100">
        <div class="card-body">
          <h6 class="text-600 fs--1 mb-2">Menu Items</h6>
          <h3 class="mb-0">
            <asp:Label ID="lblMenuCount" runat="server" Text="0" />
          </h3>
        </div>
      </div>
    </div>
    <div class="col-sm-6 col-xl-3">
      <div class="card h-100">
        <div class="card-body">
          <h6 class="text-600 fs--1 mb-2">Unread Messages</h6>
          <h3 class="mb-0">
            <asp:Label ID="lblMsgCount" runat="server" Text="0" CssClass="text-warning" />
          </h3>
        </div>
      </div>
    </div>
    <div class="col-sm-6 col-xl-3">
      <div class="card h-100">
        <div class="card-body">
          <h6 class="text-600 fs--1 mb-2">Active Offers</h6>
          <h3 class="mb-0">
            <asp:Label ID="lblOfferCount" runat="server" Text="0" CssClass="text-success" />
          </h3>
        </div>
      </div>
    </div>
  </div>

  <%-- ── Quick links ── --%>
  <div class="row g-3">
    <div class="col-md-4">
      <div class="card h-100">
        <div class="card-header py-2">
          <h5 class="mb-0 fs-0">User Management</h5>
        </div>
        <div class="card-body py-3 fs--1">
          <p class="text-600">View, activate, or deactivate staff accounts.</p>
          <a runat="server" href="~/Admin/Users.aspx" class="btn btn-sm btn-primary">
            Manage Users
          </a>
        </div>
      </div>
    </div>
    <div class="col-md-4">
      <div class="card h-100">
        <div class="card-header py-2">
          <h5 class="mb-0 fs-0">Menu Management</h5>
        </div>
        <div class="card-body py-3 fs--1">
          <p class="text-600">Update item availability, pricing, and details.</p>
          <a runat="server" href="~/Menu/MenuItems.aspx" class="btn btn-sm btn-primary">
            Manage Menu
          </a>
        </div>
      </div>
    </div>
    <div class="col-md-4">
      <div class="card h-100">
        <div class="card-header py-2">
          <h5 class="mb-0 fs-0">Customer Messages</h5>
        </div>
        <div class="card-body py-3 fs--1">
          <p class="text-600">Read and reply to customer feedback.</p>
          <a runat="server" href="~/Admin/Messages.aspx" class="btn btn-sm btn-primary">
            View Messages
          </a>
        </div>
      </div>
    </div>
  </div>

</asp:Content>
