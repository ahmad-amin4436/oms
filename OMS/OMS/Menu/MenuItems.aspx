<%@ Page Title="Menu Items" Language="C#" MasterPageFile="~/Site.Master" AutoEventWireup="true"
   CodeBehind="MenuItems.aspx.cs" Inherits="OMS.Menu.MenuItems" %>

<asp:Content ID="Content1" ContentPlaceHolderID="MainContent" runat="server">

  <%-- ── Page header ── --%>
  <div class="d-flex align-items-center justify-content-between mb-3">
    <div>
      <h4 class="mb-0">Menu Items</h4>
      <p class="text-600 fs--1 mb-0">Add, edit, remove items and manage availability &amp; pricing.</p>
    </div>
  </div>

  <asp:UpdatePanel ID="updMenu" runat="server">
    <ContentTemplate>

      <%-- ── Feedback ── --%>
      <asp:Label ID="lblMsg" runat="server" Visible="false"
        CssClass="alert alert-success d-block mb-3 py-2 fs--1"
        EnableViewState="false" />
      <asp:Label ID="lblErr" runat="server" Visible="false"
        CssClass="alert alert-danger d-block mb-3 py-2 fs--1"
        EnableViewState="false" />

      <%-- ══════════════════════════════════════════════════════════════
           MANAGE CATEGORIES  (collapsible)
           ══════════════════════════════════════════════════════════════ --%>
      <div class="card mb-3">
        <div class="card-header py-2 d-flex align-items-center justify-content-between">
          <h5 class="mb-0 fs-0">
            <span class="fas fa-tags me-2 text-600"></span>Categories
          </h5>
          <asp:Button ID="btnToggleCats" runat="server" CssClass="btn btn-sm btn-falcon-default"
            CausesValidation="false" OnClick="btnToggleCats_Click" Text="Manage Categories" />
        </div>

        <asp:Panel ID="pnlCategories" runat="server" Visible="false" CssClass="card-body pt-2">

          <%-- Category add/edit editor --%>
          <asp:Panel ID="pnlCatEditor" runat="server" Visible="false" CssClass="border rounded p-3 mb-3 bg-light">
            <asp:HiddenField ID="hfCatID" runat="server" Value="0" />
            <div class="row g-2 align-items-end">
              <div class="col-md-5">
                <label class="form-label fs--1 mb-1">Category Name<span class="text-danger ms-1">*</span></label>
                <asp:TextBox ID="txtCatName" runat="server" CssClass="form-control form-control-sm" MaxLength="80" />
                <asp:RequiredFieldValidator runat="server" ControlToValidate="txtCatName"
                  ValidationGroup="CatEditor" Display="Dynamic"
                  CssClass="text-danger fs--2" Text="Name is required." />
              </div>
              <div class="col-md-3">
                <label class="form-label fs--1 mb-1">Display Order</label>
                <asp:TextBox ID="txtCatOrder" runat="server" CssClass="form-control form-control-sm"
                  TextMode="Number" Text="0" />
                <asp:RangeValidator runat="server" ControlToValidate="txtCatOrder"
                  ValidationGroup="CatEditor" Display="Dynamic" Type="Integer"
                  MinimumValue="0" MaximumValue="9999"
                  CssClass="text-danger fs--2" Text="0–9999." />
              </div>
              <div class="col-md-2">
                <div class="form-check mb-1">
                  <asp:CheckBox ID="chkCatActive" runat="server" CssClass="form-check-input" Checked="true" />
                  <label class="form-check-label fs--1">Active</label>
                </div>
              </div>
              <div class="col-md-2 d-flex gap-1">
                <asp:Button ID="btnSaveCat" runat="server" CssClass="btn btn-sm btn-primary"
                  Text="Save" ValidationGroup="CatEditor" OnClick="btnSaveCat_Click" />
                <asp:Button ID="btnCancelCat" runat="server" CssClass="btn btn-sm btn-falcon-default"
                  Text="Cancel" CausesValidation="false" OnClick="btnCancelCat_Click" />
              </div>
            </div>
          </asp:Panel>

          <div class="d-flex justify-content-end mb-2">
            <asp:Button ID="btnAddCat" runat="server" CssClass="btn btn-sm btn-primary"
              CausesValidation="false" OnClick="btnAddCat_Click" Text="+ Add Category" />
          </div>

          <div class="table-responsive">
            <asp:GridView ID="gvCategories" runat="server"
              CssClass="table table-sm table-hover align-middle mb-0"
              AutoGenerateColumns="False" GridLines="None"
              DataKeyNames="CategoryID"
              EmptyDataText="No categories yet."
              OnRowCommand="gvCategories_RowCommand">
              <EmptyDataRowStyle CssClass="text-center text-600 py-4 fs--1" />
              <HeaderStyle CssClass="bg-light border-bottom" />
              <Columns>
                <asp:BoundField DataField="CategoryName" HeaderText="Category"
                  HeaderStyle-CssClass="ps-3 fw-medium" ItemStyle-CssClass="ps-3 fw-semibold" />
                <asp:BoundField DataField="DisplayOrder" HeaderText="Order"
                  HeaderStyle-CssClass="text-center fw-medium" ItemStyle-CssClass="text-center text-600" />
                <asp:BoundField DataField="ItemCount" HeaderText="Items"
                  HeaderStyle-CssClass="text-center fw-medium" ItemStyle-CssClass="text-center text-600" />
                <asp:TemplateField HeaderText="Status"
                  HeaderStyle-CssClass="text-center fw-medium" ItemStyle-CssClass="text-center">
                  <ItemTemplate>
                    <span class='badge <%# (bool)Eval("IsActive") ? "badge-subtle-success" : "badge-subtle-secondary" %>'>
                      <%# (bool)Eval("IsActive") ? "Active" : "Inactive" %>
                    </span>
                  </ItemTemplate>
                </asp:TemplateField>
                <asp:TemplateField HeaderText="Actions"
                  HeaderStyle-CssClass="text-end fw-medium pe-3" ItemStyle-CssClass="text-end pe-3">
                  <ItemTemplate>
                    <div class="d-inline-flex gap-1">
                      <asp:LinkButton runat="server" CommandName="EditCat"
                        CommandArgument='<%# Eval("CategoryID") %>' CausesValidation="false"
                        CssClass="btn btn-sm btn-falcon-default px-2 py-0 fs--2" ToolTip="Edit">
                        <span class="fas fa-edit"></span>
                      </asp:LinkButton>
                      <asp:LinkButton runat="server" CommandName="DeleteCat"
                        CommandArgument='<%# Eval("CategoryID") %>' CausesValidation="false"
                        CssClass="btn btn-sm btn-falcon-danger px-2 py-0 fs--2" ToolTip="Deactivate"
                        Visible='<%# (bool)Eval("IsActive") %>'
                        OnClientClick="return confirm('Deactivate this category? It will be hidden from filters and the item form.');">
                        <span class="fas fa-trash-alt"></span>
                      </asp:LinkButton>
                    </div>
                  </ItemTemplate>
                </asp:TemplateField>
              </Columns>
            </asp:GridView>
          </div>
        </asp:Panel>
      </div>

      <%-- ══════════════════════════════════════════════════════════════
           ADD / EDIT EDITOR  (hidden until Add New / Edit is clicked)
           ══════════════════════════════════════════════════════════════ --%>
      <asp:Panel ID="pnlEditor" runat="server" Visible="false" CssClass="card mb-3 border-primary">
        <div class="card-header py-2 bg-light d-flex align-items-center justify-content-between">
          <h5 class="mb-0 fs-0"><asp:Literal ID="litEditorTitle" runat="server" Text="Add New Item" /></h5>
          <asp:LinkButton ID="lbCloseEditor" runat="server" CssClass="btn btn-sm btn-falcon-default p-1 lh-1"
            CausesValidation="false" OnClick="lbCancel_Click" ToolTip="Close">&times;</asp:LinkButton>
        </div>
        <div class="card-body">
          <asp:HiddenField ID="hfItemID" runat="server" Value="0" />
          <div class="row g-3">

            <div class="col-md-6">
              <label class="form-label fs--1 mb-1">Item Name<span class="text-danger ms-1">*</span></label>
              <asp:TextBox ID="txtName" runat="server" CssClass="form-control form-control-sm" MaxLength="120" />
              <asp:RequiredFieldValidator runat="server" ControlToValidate="txtName"
                ValidationGroup="Editor" Display="Dynamic"
                CssClass="text-danger fs--2" Text="Name is required." />
            </div>

            <div class="col-md-6">
              <label class="form-label fs--1 mb-1">Category<span class="text-danger ms-1">*</span></label>
              <asp:DropDownList ID="ddlCategory" runat="server" CssClass="form-select form-select-sm" />
              <asp:RequiredFieldValidator runat="server" ControlToValidate="ddlCategory"
                ValidationGroup="Editor" Display="Dynamic" InitialValue=""
                CssClass="text-danger fs--2" Text="Select a category." />
            </div>

            <div class="col-md-4">
              <label class="form-label fs--1 mb-1">Base Price (Rs.)<span class="text-danger ms-1">*</span></label>
              <asp:TextBox ID="txtPrice" runat="server" CssClass="form-control form-control-sm"
                TextMode="Number" />
              <asp:RequiredFieldValidator runat="server" ControlToValidate="txtPrice"
                ValidationGroup="Editor" Display="Dynamic"
                CssClass="text-danger fs--2" Text="Price is required." />
              <asp:RangeValidator runat="server" ControlToValidate="txtPrice"
                ValidationGroup="Editor" Display="Dynamic" Type="Double"
                MinimumValue="0" MaximumValue="1000000"
                CssClass="text-danger fs--2" Text="Enter a price between 0 and 1,000,000." />
            </div>

            <div class="col-md-8">
              <label class="form-label fs--1 mb-1">Description</label>
              <asp:TextBox ID="txtDescription" runat="server" CssClass="form-control form-control-sm"
                TextMode="MultiLine" Rows="2" MaxLength="500" placeholder="Optional" />
            </div>

            <div class="col-md-6 d-flex align-items-center gap-4 pt-1">
              <div class="form-check mb-0">
                <asp:CheckBox ID="chkAvailable" runat="server" CssClass="form-check-input" Checked="true" />
                <label class="form-check-label fs--1">Available</label>
              </div>
              <div class="form-check mb-0">
                <asp:CheckBox ID="chkFeatured" runat="server" CssClass="form-check-input" />
                <label class="form-check-label fs--1">Featured</label>
              </div>
            </div>

            <div class="col-12 d-flex gap-2 border-top pt-3">
              <asp:Button ID="btnSave" runat="server" CssClass="btn btn-sm btn-primary"
                Text="Save Item" ValidationGroup="Editor" OnClick="btnSave_Click" />
              <asp:Button ID="btnCancel" runat="server" CssClass="btn btn-sm btn-falcon-default"
                Text="Cancel" CausesValidation="false" OnClick="lbCancel_Click" />
            </div>

          </div>
        </div>
      </asp:Panel>

      <%-- ── Toolbar: category filter tabs + Add button ── --%>
      <div class="card mb-3">
        <div class="card-body py-2 d-flex flex-wrap gap-2 align-items-center">
          <asp:LinkButton ID="lbAllCat" runat="server" CssClass="btn btn-sm btn-falcon-default"
            CausesValidation="false" OnClick="lbAllCat_Click">All Categories</asp:LinkButton>
          <asp:Repeater ID="rptCatTabs" runat="server" OnItemCommand="rptCatTabs_ItemCommand">
            <ItemTemplate>
              <asp:LinkButton runat="server" CssClass='<%# GetCatBtnCss((int)Eval("CategoryID")) %>'
                CommandName="Filter" CommandArgument='<%# Eval("CategoryID") %>' CausesValidation="false">
                <%# Eval("CategoryName") %>
              </asp:LinkButton>
            </ItemTemplate>
          </asp:Repeater>
          <asp:Button ID="btnAddNew" runat="server" CssClass="btn btn-sm btn-primary ms-auto"
            Text="+ Add New Item" CausesValidation="false" OnClick="btnAddNew_Click" />
        </div>
      </div>

      <%-- ── Items table ── --%>
      <div class="card">
        <div class="table-responsive">
          <asp:GridView ID="gvMenuItems" runat="server"
            CssClass="table table-sm table-hover align-middle mb-0"
            AutoGenerateColumns="False" GridLines="None"
            DataKeyNames="ItemID"
            EmptyDataText="No items found."
            OnRowCommand="gvMenuItems_RowCommand">
            <EmptyDataRowStyle CssClass="text-center text-600 py-4 fs--1" />
            <HeaderStyle CssClass="bg-light border-bottom" />
            <Columns>
              <asp:BoundField DataField="Name" HeaderText="Item"
                HeaderStyle-CssClass="ps-3 fw-medium"
                ItemStyle-CssClass="ps-3 fw-semibold" />
              <asp:BoundField DataField="CategoryName" HeaderText="Category"
                HeaderStyle-CssClass="fw-medium"
                ItemStyle-CssClass="text-600" />
              <asp:BoundField DataField="BasePrice" HeaderText="Base Price"
                DataFormatString="Rs.&#160;{0:N0}"
                HeaderStyle-CssClass="text-end fw-medium"
                ItemStyle-CssClass="text-end" />
              <asp:TemplateField HeaderText="Available"
                HeaderStyle-CssClass="text-center fw-medium"
                ItemStyle-CssClass="text-center">
                <ItemTemplate>
                  <span class='badge <%# (bool)Eval("IsAvailable") ? "badge-subtle-success" : "badge-subtle-danger" %>'>
                    <%# (bool)Eval("IsAvailable") ? "Yes" : "No" %>
                  </span>
                </ItemTemplate>
              </asp:TemplateField>
              <asp:TemplateField HeaderText="Featured"
                HeaderStyle-CssClass="text-center fw-medium"
                ItemStyle-CssClass="text-center">
                <ItemTemplate>
                  <span class='badge <%# (bool)Eval("IsFeatured") ? "badge-subtle-primary" : "badge-subtle-secondary" %>'>
                    <%# (bool)Eval("IsFeatured") ? "Yes" : "No" %>
                  </span>
                </ItemTemplate>
              </asp:TemplateField>
              <asp:TemplateField HeaderText="Actions"
                HeaderStyle-CssClass="text-end fw-medium pe-3"
                ItemStyle-CssClass="text-end pe-3">
                <ItemTemplate>
                  <div class="d-inline-flex gap-1">
                    <asp:LinkButton runat="server"
                      CommandName="EditItem"
                      CommandArgument='<%# Eval("ItemID") %>'
                      CausesValidation="false"
                      CssClass="btn btn-sm btn-falcon-default px-2 py-0 fs--2"
                      ToolTip="Edit">
                      <span class="fas fa-edit"></span>
                    </asp:LinkButton>
                    <asp:LinkButton runat="server"
                      CommandName="Toggle"
                      CommandArgument='<%# Eval("ItemID") %>'
                      CausesValidation="false"
                      CssClass='<%# "btn btn-sm px-2 py-0 fs--2 " + ((bool)Eval("IsAvailable") ? "btn-falcon-warning" : "btn-falcon-success") %>'>
                      <%# (bool)Eval("IsAvailable") ? "Hide" : "Show" %>
                    </asp:LinkButton>
                    <asp:LinkButton runat="server"
                      CommandName="DeleteItem"
                      CommandArgument='<%# Eval("ItemID") %>'
                      CausesValidation="false"
                      CssClass="btn btn-sm btn-falcon-danger px-2 py-0 fs--2"
                      ToolTip="Delete"
                      OnClientClick="return confirm('Remove this item from the menu? It will be hidden from customers.');">
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
