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

        // Summary header card
        protected global::System.Web.UI.WebControls.Label          lblOrderNumberCard;
        protected global::System.Web.UI.WebControls.Label          lblCreatedAtCard;
        protected global::System.Web.UI.WebControls.Label          lblStatusBadge;

        // Items + totals
        protected global::System.Web.UI.WebControls.GridView       gvItems;
        protected global::System.Web.UI.WebControls.Label          lblSubtotal;
        protected global::System.Web.UI.WebControls.Label          lblDiscount;
        protected global::System.Web.UI.WebControls.Label          lblTax;
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
    }
}
