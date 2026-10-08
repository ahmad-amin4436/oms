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
                var value = Read(TaxKey);
                decimal pct;
                if (value != null && decimal.TryParse(Convert.ToString(value), NumberStyles.Number,
                        CultureInfo.InvariantCulture, out pct) && pct >= 0m && pct <= 100m)
                    return pct;
                return DefaultTaxPercent;
            }
        }

        /// <summary>Payment methods that can carry their own tax rate (value, display name).
        /// Cash uses the original "TaxPercent" setting, which is also the fallback for any method
        /// without a rate of its own.</summary>
        public static readonly string[][] TaxPaymentMethods =
        {
            new[] { "Cash",         "Cash" },
            new[] { "Card",         "Card" },
            new[] { "Wallet",       "Wallet" },
            new[] { "BankTransfer", "Bank Transfer" }
        };

        // Settings are read on every order screen; cache them (a save clears the cache at once, see AppCache).
        private static object Read(string key)
        {
            string v = AppCache.GetOrAdd<string>("settings", key, 60,
                () => Convert.ToString(DBHelper.ExecuteScalar("sp_GetSetting", DBHelper.Parameter("@SettingKey", key))) ?? "");
            return string.IsNullOrEmpty(v) ? null : v;
        }

        private static string KeyFor(string method)
        {
            return string.IsNullOrEmpty(method) || method == "Cash" ? TaxKey : TaxKey + "." + method;
        }

        /// <summary>Tax rate in percent for a payment method.</summary>
        public static decimal TaxPercentFor(string method)
        {
            var value = Read(KeyFor(method));
            decimal pct;
            if (value != null && decimal.TryParse(Convert.ToString(value), NumberStyles.Number,
                    CultureInfo.InvariantCulture, out pct) && pct >= 0m && pct <= 100m)
                return pct;
            return TaxPercent;   // no rate of its own: use the default (Cash) rate
        }

        public static void SetTaxPercentFor(string method, decimal percent, int updatedBy)
        {
            DBHelper.ExecuteNonQuery("sp_SetSetting",
                DBHelper.Parameter("@SettingKey",   KeyFor(method)),
                DBHelper.Parameter("@SettingValue", Math.Round(percent, 2).ToString(CultureInfo.InvariantCulture)),
                DBHelper.Parameter("@UpdatedBy",    updatedBy == 0 ? (object)DBNull.Value : updatedBy));
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
