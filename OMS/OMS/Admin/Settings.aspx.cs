using System;
using System.Globalization;
using OMS.Common.Helpers;

namespace OMS.Admin
{
    public partial class Settings : System.Web.UI.Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {
            SecurityHelper.RequireRoles("Admin");
            if (!IsPostBack)
                txtTaxPercent.Text = SettingsHelper.TaxPercent.ToString("0.##", CultureInfo.InvariantCulture);
        }

        protected void btnSave_Click(object sender, EventArgs e)
        {
            SecurityHelper.RequireRoles("Admin");
            Page.Validate("Settings");
            if (!Page.IsValid) return;

            decimal pct;
            if (!decimal.TryParse(txtTaxPercent.Text.Trim(), NumberStyles.Number, CultureInfo.InvariantCulture, out pct)
                || pct < 0m || pct > 100m)
            {
                lblMsg.CssClass = "alert alert-danger d-block mb-3 py-2 fs--1";
                lblMsg.Text     = "Enter a number between 0 and 100.";
                lblMsg.Visible  = true;
                return;
            }

            SettingsHelper.SetTaxPercent(pct, SecurityHelper.UserID);
            lblMsg.CssClass = "alert alert-success d-block mb-3 py-2 fs--1";
            lblMsg.Text     = "Tax percentage saved.";
            lblMsg.Visible  = true;
        }
    }
}
