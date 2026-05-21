using System;
using System.Data;
using System.Data.SqlClient;
using System.Web;
using System.Web.Security;
using OMS.App_Code.DAL;
using OMS.App_Code.Helpers;

namespace OMS.App_Code.BLL
{
    public static class AuthService
    {
        public static bool TryLogin(string email, string password, bool rememberMe, out string errorMessage)
        {
            errorMessage = null;
            var table = DBHelper.ExecuteDataTable("sp_GetUserByEmail", DBHelper.Parameter("@Email", email));
            if (table.Rows.Count == 0)
            {
                errorMessage = "Invalid email or password.";
                return false;
            }

            var row = table.Rows[0];
            var userId = Convert.ToInt32(row["UserID"]);
            var isActive = Convert.ToBoolean(row["IsActive"]);
            var lockoutUntil = row["LockoutUntil"] == DBNull.Value ? (DateTime?)null : Convert.ToDateTime(row["LockoutUntil"]);

            if (!isActive)
            {
                errorMessage = "This user account is inactive.";
                return false;
            }

            if (lockoutUntil.HasValue && lockoutUntil.Value > DateTime.UtcNow)
            {
                errorMessage = "Too many failed attempts. Try again after a few minutes.";
                return false;
            }

            var passwordOk = PasswordHelper.VerifyPassword(password, Convert.ToString(row["PasswordHash"]));
            DBHelper.ExecuteNonQuery("sp_RecordLoginResult",
                DBHelper.Parameter("@UserID", userId),
                DBHelper.Parameter("@Succeeded", passwordOk));

            if (!passwordOk)
            {
                errorMessage = "Invalid email or password.";
                return false;
            }

            var roleName = Convert.ToString(row["RoleName"]);
            var fullName = Convert.ToString(row["FullName"]);
            var ticket = new FormsAuthenticationTicket(1, email, DateTime.Now, DateTime.Now.AddHours(rememberMe ? 24 * 14 : 8), rememberMe, userId + "|" + roleName, FormsAuthentication.FormsCookiePath);
            var cookie = new HttpCookie(FormsAuthentication.FormsCookieName, FormsAuthentication.Encrypt(ticket))
            {
                HttpOnly = true,
                Secure = HttpContext.Current.Request.IsSecureConnection
            };

            if (rememberMe) cookie.Expires = ticket.Expiration;
            HttpContext.Current.Response.Cookies.Add(cookie);

            HttpContext.Current.Session["UserID"] = userId;
            HttpContext.Current.Session["UserName"] = fullName;
            HttpContext.Current.Session["UserRole"] = roleName;

            DBHelper.ExecuteNonQuery("sp_LogActivity",
                DBHelper.Parameter("@UserID", userId),
                DBHelper.Parameter("@Action", "Login"),
                DBHelper.Parameter("@Description", "User logged in"),
                DBHelper.Parameter("@IPAddress", HttpContext.Current.Request.UserHostAddress));

            return true;
        }

        public static void Logout()
        {
            FormsAuthentication.SignOut();
            HttpContext.Current.Session.Clear();
            HttpContext.Current.Response.Redirect("~/Login.aspx", false);
            HttpContext.Current.ApplicationInstance.CompleteRequest();
        }
    }
}
