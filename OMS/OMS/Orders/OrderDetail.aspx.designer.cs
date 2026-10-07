namespace OMS.Orders
{
    public partial class OrderDetail
    {
        // Header
        protected global::System.Web.UI.WebControls.Label          lblOrderNumber;
        protected global::System.Web.UI.HtmlControls.HtmlAnchor    lnkPrint;
        protected global::System.Web.UI.WebControls.Label          lblError;
        protected global::System.Web.UI.WebControls.Panel          pnlNotFound;
        protected global::System.Web.UI.WebControls.Panel          pnlContent;

        // Add dish
        protected global::System.Web.UI.WebControls.Panel          pnlAddDish;
        protected global::System.Web.UI.WebControls.Label          lblAddMsg;
        protected global::System.Web.UI.WebControls.DropDownList   ddlAddItem;
        protected global::System.Web.UI.WebControls.RequiredFieldValidator rfvAddItem;
        protected global::System.Web.UI.WebControls.TextBox        txtAddQty;
        protected global::System.Web.UI.WebControls.RangeValidator rngAddQty;
        protected global::System.Web.UI.WebControls.Button         btnAddDish;

        // Summary header card
        protected global::System.Web.UI.WebControls.Label          lblOrderNumberCard;
        protected global::System.Web.UI.WebControls.Label          lblCreatedAtCard;
        protected global::System.Web.UI.WebControls.Label          lblStatusBadge;

        // Items + totals
        protected global::System.Web.UI.WebControls.GridView       gvItems;
        protected global::System.Web.UI.WebControls.Label          lblSubtotal;
        protected global::System.Web.UI.WebControls.Label          lblDiscount;
        protected global::System.Web.UI.WebControls.Label          lblTax;
        protected global::System.Web.UI.WebControls.Label          lblTaxLabel;
        protected global::System.Web.UI.WebControls.Panel          pnlCancelInfo;
        protected global::System.Web.UI.WebControls.Label          lblCancelledAt;
        protected global::System.Web.UI.WebControls.Label          lblCancelledBy;
        protected global::System.Web.UI.WebControls.Label          lblCancelReason;
        protected global::System.Web.UI.WebControls.Panel          pnlUpdateStatus;
        protected global::System.Web.UI.WebControls.Panel          pnlCancel;
        protected global::System.Web.UI.WebControls.TextBox        txtCancelReason;
        protected global::System.Web.UI.WebControls.RequiredFieldValidator rfvCancelReason;
        protected global::System.Web.UI.WebControls.Button         btnCancelOrder;
        protected global::System.Web.UI.WebControls.Label          lblTotal;

        // Order info
        protected global::System.Web.UI.WebControls.Label          lblCustomer;
        protected global::System.Web.UI.WebControls.Label          lblPhone;
        protected global::System.Web.UI.WebControls.Label          lblOrderType;
        protected global::System.Web.UI.WebControls.Panel          pnlTableRow;
        protected global::System.Web.UI.WebControls.Label          lblTableNo;
        protected global::System.Web.UI.WebControls.Panel          pnlAddressRow;
        protected global::System.Web.UI.WebControls.Label          lblAddress;
        protected global::System.Web.UI.WebControls.Label          lblPaymentMethod;
        protected global::System.Web.UI.WebControls.Label          lblPaymentStatus;
        protected global::System.Web.UI.WebControls.Panel          pnlNotes;
        protected global::System.Web.UI.WebControls.Label          lblNotes;
        protected global::System.Web.UI.WebControls.Label          lblCreatedAt;

        // Status update
        protected global::System.Web.UI.WebControls.Label          lblStatusMsg;
        protected global::System.Web.UI.WebControls.DropDownList   ddlStatus;
        protected global::System.Web.UI.WebControls.Button         btnUpdateStatus;
    
        protected global::System.Web.UI.HtmlControls.HtmlAnchor lnkAllOrders;
    }
}
