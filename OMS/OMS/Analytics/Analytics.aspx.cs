using System;
using OMS.App_Code.DAL;
using OMS.App_Code.Helpers;

namespace OMS.Analytics
{
    public partial class Analytics : System.Web.UI.Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {
            SecurityHelper.RequireRoles("Admin", "Manager");
            if (!IsPostBack)
            {
                var end = DateTime.UtcNow.Date;
                gvAnalytics.DataSource = DBHelper.ExecuteDataTable("sp_GetSalesAnalytics", DBHelper.Parameter("@StartDate", end.AddDays(-7)), DBHelper.Parameter("@EndDate", end), DBHelper.Parameter("@GroupBy", "Day"));
                gvAnalytics.DataBind();
            }
        }
    }
}
