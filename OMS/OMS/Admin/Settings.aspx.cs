using System;
using System.Globalization;
using System.Web.UI.WebControls;
using OMS.Common.Helpers;

namespace OMS.Admin
{
    public partial class Settings : System.Web.UI.Page
    {
        // payment method value -> its text box (values match SettingsHelper.TaxPaymentMethods)
        private TextBox BoxFor(string method)
        {
            switch (method)
            {
                case "Card":         return txtTaxCard;
                case "Wallet":       return txtTaxWallet;
                case "BankTransfer": return txtTaxBank;
                default:             return txtTaxCash;
            }
        }

        protected void Page_Load(object sender, EventArgs e)
        {
            SecurityHelper.RequireRoles("Admin");
            if (!IsPostBack)
                foreach (var m in SettingsHelper.TaxPaymentMethods)
                    BoxFor(m[0]).Text = SettingsHelper.TaxPercentFor(m[0]).ToString("0.##", CultureInfo.InvariantCulture);
        }

        protected void btnSave_Click(object sender, EventArgs e)
        {
            SecurityHelper.RequireRoles("Admin");
            Page.Validate("Settings");
            if (!Page.IsValid) return;

            // Validate everything before saving anything, so a typo cannot half-save.
            var rates = new decimal[SettingsHelper.TaxPaymentMethods.Length];
            for (int i = 0; i < rates.Length; i++)
            {
                var m = SettingsHelper.TaxPaymentMethods[i];
                decimal pct;
                if (!decimal.TryParse(BoxFor(m[0]).Text.Trim(), NumberStyles.Number, CultureInfo.InvariantCulture, out pct)
                    || pct < 0m || pct > 100m)
                {
                    lblMsg.CssClass = "alert alert-danger d-block mb-3 py-2 fs--1";
                    lblMsg.Text     = m[1] + ": enter a number between 0 and 100.";
                    lblMsg.Visible  = true;
                    return;
                }
                rates[i] = pct;
            }

            for (int i = 0; i < rates.Length; i++)
                SettingsHelper.SetTaxPercentFor(SettingsHelper.TaxPaymentMethods[i][0], rates[i], SecurityHelper.UserID);

            lblMsg.CssClass = "alert alert-success d-block mb-3 py-2 fs--1";
            lblMsg.Text     = "Tax rates saved.";
            lblMsg.Visible  = true;
        }
    }
}
