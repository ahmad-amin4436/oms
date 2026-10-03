using System;
using System.Globalization;
using OMS.Common.DAL;

namespace OMS.Common.Helpers
{
    /// <summary>Access to AppSettings and tax helpers shared by order entry and display.</summary>
    public static class SettingsHelper
    {
        private const string TaxKey = "TaxPercent";
        private const decimal DefaultTaxPercent = 16m;

        /// <summary>Currently configured tax rate in percent (e.g. 16 for 16%).</summary>
        public static decimal TaxPercent
        {
            get
            {
                var value = DBHelper.ExecuteScalar("sp_GetSetting", DBHelper.Parameter("@SettingKey", TaxKey));
                decimal pct;
                if (value != null && decimal.TryParse(Convert.ToString(value), NumberStyles.Number,
                        CultureInfo.InvariantCulture, out pct) && pct >= 0m && pct <= 100m)
                    return pct;
                return DefaultTaxPercent;
            }
        }

        public static void SetTaxPercent(decimal percent, int updatedBy)
        {
            DBHelper.ExecuteNonQuery("sp_SetSetting",
                DBHelper.Parameter("@SettingKey",   TaxKey),
                DBHelper.Parameter("@SettingValue", Math.Round(percent, 2).ToString(CultureInfo.InvariantCulture)),
                DBHelper.Parameter("@UpdatedBy",    updatedBy == 0 ? (object)DBNull.Value : updatedBy));
        }

        public static decimal CalcTax(decimal taxable, decimal percent)
        {
            return Math.Round(taxable * percent / 100m, 2);
        }

        /// <summary>"16%" style text for a finalized order: the snapshot rate when stored,
        /// otherwise derived from the stored amounts (legacy orders). Empty if not derivable.</summary>
        public static string TaxLabel(object storedPercent, decimal subtotal, decimal discount, decimal taxAmount)
        {
            decimal pct;
            if (storedPercent != null && storedPercent != DBNull.Value)
                pct = Convert.ToDecimal(storedPercent);
            else
            {
                decimal taxable = subtotal - discount;
                if (taxable <= 0m) return "";
                pct = Math.Round(taxAmount / taxable * 100m, 2);
            }
            return pct.ToString("0.##", CultureInfo.InvariantCulture) + "%";
        }
    }
}
