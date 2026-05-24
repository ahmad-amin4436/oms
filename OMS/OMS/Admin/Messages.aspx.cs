using System;
using System.Data;
using OMS.Common.DAL;
using OMS.Common.Helpers;

namespace OMS.Admin
{
    public partial class Messages : System.Web.UI.Page
    {
        private bool? FilterRead
        {
            get { return ViewState["FilterRead"] as bool?; }
            set { ViewState["FilterRead"] = value; }
        }

        protected void Page_Load(object sender, EventArgs e)
        {
            SecurityHelper.RequireRoles("Admin", "Manager");
            if (!IsPostBack)
                BindMessages();
        }

        private void BindMessages()
        {
            var param = FilterRead.HasValue
                ? DBHelper.Parameter("@IsRead", FilterRead.Value)
                : DBHelper.Parameter("@IsRead", DBNull.Value);

            gvMessages.DataSource = DBHelper.ExecuteDataTable("sp_GetMessages", param);
            gvMessages.DataBind();
        }

        protected void lbAll_Click(object sender, EventArgs e)
        {
            FilterRead = null;
            lbAll.CssClass    = "btn btn-sm btn-primary";
            lbUnread.CssClass = "btn btn-sm btn-falcon-default";
            lbRead.CssClass   = "btn btn-sm btn-falcon-default";
            BindMessages();
        }

        protected void lbUnread_Click(object sender, EventArgs e)
        {
            FilterRead = false;
            lbAll.CssClass    = "btn btn-sm btn-falcon-default";
            lbUnread.CssClass = "btn btn-sm btn-primary";
            lbRead.CssClass   = "btn btn-sm btn-falcon-default";
            BindMessages();
        }

        protected void lbRead_Click(object sender, EventArgs e)
        {
            FilterRead = true;
            lbAll.CssClass    = "btn btn-sm btn-falcon-default";
            lbUnread.CssClass = "btn btn-sm btn-falcon-default";
            lbRead.CssClass   = "btn btn-sm btn-primary";
            BindMessages();
        }

        protected void gvMessages_SelectedIndexChanged(object sender, EventArgs e)
        {
            int msgId = Convert.ToInt32(gvMessages.SelectedDataKey?.Value ?? 0);
            if (msgId == 0) return;

            // Re-fetch all messages and find selected row by ID
            var dt = DBHelper.ExecuteDataTable("sp_GetMessages",
                DBHelper.Parameter("@IsRead", DBNull.Value));

            DataRow[] rows = dt.Select("MessageID = " + msgId);
            if (rows.Length == 0) return;

            DataRow dr = rows[0];
            pnlDetail.Visible  = true;
            hdnMessageID.Value = msgId.ToString();
            lblSubject.Text    = Server.HtmlEncode(Convert.ToString(dr["Subject"]));
            lblFrom.Text       = Server.HtmlEncode(Convert.ToString(dr["CustomerName"]));
            lblPhone.Text      = Convert.ToString(dr["CustomerPhone"]) == ""
                                    ? "—" : Server.HtmlEncode(Convert.ToString(dr["CustomerPhone"]));
            lblEmail.Text      = Convert.ToString(dr["CustomerEmail"]) == ""
                                    ? "—" : Server.HtmlEncode(Convert.ToString(dr["CustomerEmail"]));
            lblBody.Text       = Server.HtmlEncode(Convert.ToString(dr["Body"]));

            string reply = Convert.ToString(dr["ReplyBody"]);
            pnlExistingReply.Visible = !string.IsNullOrEmpty(reply);
            lblExistingReply.Text    = Server.HtmlEncode(reply);
            txtReply.Text            = string.Empty;
        }

        protected void btnReply_Click(object sender, EventArgs e)
        {
            int msgId = Convert.ToInt32(hdnMessageID.Value);
            if (msgId == 0 || string.IsNullOrWhiteSpace(txtReply.Text)) return;

            DBHelper.ExecuteNonQuery("sp_ReplyMessage",
                DBHelper.Parameter("@MessageID", msgId),
                DBHelper.Parameter("@ReplyBody",  txtReply.Text.Trim()),
                DBHelper.Parameter("@RepliedBy",  SecurityHelper.UserID));

            lblMsg.Text    = "Reply recorded and message marked as read.";
            lblMsg.Visible = true;
            pnlDetail.Visible = false;
            BindMessages();
        }
    }
}
