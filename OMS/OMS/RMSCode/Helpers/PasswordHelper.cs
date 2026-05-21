using System;
using System.Security.Cryptography;
using System.Text;

namespace OMS.App_Code.Helpers
{
    public static class PasswordHelper
    {
        public static string HashPassword(string password)
        {
            if (password == null) throw new ArgumentNullException("password");

            using (var sha = SHA256.Create())
            {
                var bytes = sha.ComputeHash(Encoding.UTF8.GetBytes(password));
                return Convert.ToBase64String(bytes);
            }
        }

        public static bool VerifyPassword(string password, string storedHash)
        {
            if (string.IsNullOrEmpty(storedHash)) return false;
            return StringComparer.Ordinal.Equals(HashPassword(password), storedHash);
        }
    }
}
