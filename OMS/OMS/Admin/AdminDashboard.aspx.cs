using System;
using System.Data;
using OMS.Common.DAL;
using OMS.Common.Helpers;

namespace OMS.Admin
{
    public partial class AdminDashboard : System.Web.UI.Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {
            SecurityHelper.RequireRoles("Admin", "Manager");
            if (!IsPostBack)
                BindStats();
        }

        private void BindStats()
        {
            var dt = DBHelper.ExecuteDataTable("sp_GetAdminStats");
            if (dt.Rows.Count == 0) return;

            DataRow row = dt.Rows[0];
            lblUserCount.Text  = Convert.ToInt32(row["UserCount"]).ToString("N0");
            lblMenuCount.Text  = Convert.ToInt32(row["MenuCount"]).ToString("N0");
            lblMsgCount.Text   = Convert.ToInt32(row["UnreadMessages"]).ToString("N0");
            lblOfferCount.Text = Convert.ToInt32(row["ActiveOffers"]).ToString("N0");
        }
    }
}
