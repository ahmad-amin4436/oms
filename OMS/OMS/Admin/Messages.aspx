<%@ Page Title="Messages" Language="C#" MasterPageFile="~/Site.Master" AutoEventWireup="true"
   CodeBehind="Messages.aspx.cs" Inherits="OMS.Admin.Messages" %>

<asp:Content ID="Content1" ContentPlaceHolderID="MainContent" runat="server">

  <%-- ── Page header ── --%>
  <div class="d-flex align-items-center justify-content-between mb-3">
    <div>
      <h4 class="mb-0">Messages</h4>
      <p class="text-600 fs--1 mb-0">Customer feedback and enquiries.</p>
    </div>
  </div>

  <asp:UpdatePanel ID="updMessages" runat="server">
    <ContentTemplate>

      <%-- Filter tabs --%>
      <div class="card mb-3">
        <div class="card-body py-2 d-flex gap-2">
          <asp:LinkButton ID="lbAll" runat="server" CssClass="btn btn-sm btn-primary"
            OnClick="lbAll_Click">All</asp:LinkButton>
          <asp:LinkButton ID="lbUnread" runat="server" CssClass="btn btn-sm btn-falcon-default"
            OnClick="lbUnread_Click">Unread</asp:LinkButton>
          <asp:LinkButton ID="lbRead" runat="server" CssClass="btn btn-sm btn-falcon-default"
            OnClick="lbRead_Click">Read</asp:LinkButton>
        </div>
      </div>

      <%-- Reply success / error --%>
      <asp:Label ID="lblMsg" runat="server" Visible="false"
        CssClass="alert alert-success d-block mb-3 py-2 fs--1"
        EnableViewState="false" />

      <%-- Messages table --%>
      <div class="card mb-3">
        <div class="table-responsive">
          <asp:GridView ID="gvMessages" runat="server"
            CssClass="table table-sm table-hover align-middle mb-0"
            AutoGenerateColumns="False" GridLines="None"
            EmptyDataText="No messages."
            DataKeyNames="MessageID"
            OnSelectedIndexChanged="gvMessages_SelectedIndexChanged"
            SelectedRowStyle-CssClass="table-active">
            <EmptyDataRowStyle CssClass="text-center text-600 py-4 fs--1" />
            <HeaderStyle CssClass="bg-light border-bottom" />
            <Columns>
              <asp:TemplateField HeaderText="Status"
                HeaderStyle-CssClass="ps-3 fw-medium"
                ItemStyle-CssClass="ps-3">
                <ItemTemplate>
                  <span class='badge <%# (bool)Eval("IsRead") ? "badge-subtle-secondary" : "badge-subtle-warning" %>'>
                    <%# (bool)Eval("IsRead") ? "Read" : "New" %>
                  </span>
                </ItemTemplate>
              </asp:TemplateField>
              <asp:BoundField DataField="CustomerName" HeaderText="From"
                HeaderStyle-CssClass="fw-medium"
                ItemStyle-CssClass="fw-semibold" />
              <asp:BoundField DataField="Subject" HeaderText="Subject"
                HeaderStyle-CssClass="fw-medium" />
              <asp:BoundField DataField="CreatedAt" HeaderText="Received"
                DataFormatString="{0:dd MMM yyyy, hh:mm tt}"
                HeaderStyle-CssClass="fw-medium"
                ItemStyle-CssClass="text-600 fs--1" />
              <asp:CommandField SelectText="View" ShowSelectButton="true"
                HeaderStyle-CssClass="text-center fw-medium"
                ItemStyle-CssClass="text-center pe-3"
                ButtonType="Link"
                ControlStyle-CssClass="btn btn-sm btn-falcon-default px-2 py-0 fs--2" />
            </Columns>
          </asp:GridView>
        </div>
      </div>

      <%-- Message detail + reply panel --%>
      <asp:Panel ID="pnlDetail" runat="server" Visible="false">
        <div class="card">
          <div class="card-header py-2">
            <h5 class="mb-0 fs-0">
              <asp:Label ID="lblSubject" runat="server" />
            </h5>
            <div class="text-600 fs--1">
              From: <asp:Label ID="lblFrom" runat="server" />
              &nbsp;|&nbsp;
              <asp:Label ID="lblPhone" runat="server" />
              &nbsp;|&nbsp;
              <asp:Label ID="lblEmail" runat="server" />
            </div>
          </div>
          <div class="card-body py-3">
            <p class="text-700"><asp:Label ID="lblBody" runat="server" /></p>

            <asp:Panel ID="pnlExistingReply" runat="server" Visible="false"
              CssClass="alert alert-info py-2 fs--1 mb-3">
              <strong>Previous reply:</strong>
              <asp:Label ID="lblExistingReply" runat="server" />
            </asp:Panel>

            <div class="mb-2">
              <label class="form-label fs--1 fw-medium">Reply</label>
              <asp:TextBox ID="txtReply" runat="server"
                CssClass="form-control form-control-sm" TextMode="MultiLine" Rows="3" />
            </div>
            <asp:Button ID="btnReply" runat="server" CssClass="btn btn-primary btn-sm"
              Text="Send Reply" OnClick="btnReply_Click" />
            <asp:HiddenField ID="hdnMessageID" runat="server" />
          </div>
        </div>
      </asp:Panel>

    </ContentTemplate>
  </asp:UpdatePanel>

</asp:Content>
