
using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data;
using System.Web;
using System.Web.Script.Serialization;
using OMS.Common.DAL;

namespace OMS.Kitchen
{
    public class KitchenPrintFeed : IHttpHandler
    {
        public bool IsReusable { get { return false; } }

        public void ProcessRequest(HttpContext context)
        {
            context.Response.SuppressFormsAuthenticationRedirect = true;
            context.Response.Cache.SetCacheability(HttpCacheability.NoCache);
            context.Response.ContentType = "application/json";

            try
            {
                if (context.Request.HttpMethod == "GET")
                {
                    GetPendingJobs(context);
                    return;
                }

                if (context.Request.HttpMethod == "POST")
                {
                    UpdateJob(context);
                    return;
                }

                Fail(context, 405, "Method not allowed.");
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine(
                    "Kitchen print feed error: " + ex.Message);

                Fail(context, 500, "Printing service error.");
            }
        }

        private static void GetPendingJobs(HttpContext context)
        {
            DataTable dt = DBHelper.ExecuteDataTable(
                "sp_GetPendingKitchenPrintJobs",
                DBHelper.Parameter("@BatchSize", 10)
            );

            var jobs = new List<Dictionary<string, object>>();

            foreach (DataRow r in dt.Rows)
            {
                var job = new Dictionary<string, object>();

                foreach (DataColumn col in dt.Columns)
                {
                    job[col.ColumnName] =
                        r[col] == DBNull.Value ? null : r[col];
                }

                jobs.Add(job);
            }

            context.Response.Write(
                new JavaScriptSerializer().Serialize(
                    new Dictionary<string, object>
                    {
                        { "ok", true },
                        { "jobs", jobs }
                    }
                )
            );
        }

        private static void UpdateJob(HttpContext context)
        {
            string action = context.Request.Form["action"];

            int jobId;

            if (!int.TryParse(context.Request.Form["jobId"], out jobId)
                || jobId <= 0)
            {
                Fail(context, 400, "Invalid print job ID.");
                return;
            }

            if (action == "complete")
            {
                DBHelper.ExecuteNonQuery(
                    "sp_CompleteKitchenPrintJob",
                    DBHelper.Parameter("@PrintJobID", jobId)
                );
            }
            else if (action == "fail")
            {
                string error = context.Request.Form["error"];

                if (string.IsNullOrWhiteSpace(error))
                    error = "Printing failed.";

                if (error.Length > 1000)
                    error = error.Substring(0, 1000);

                DBHelper.ExecuteNonQuery(
                    "sp_FailKitchenPrintJob",
                    DBHelper.Parameter("@PrintJobID", jobId),
                    DBHelper.Parameter("@ErrorMessage", error)
                );
            }
            else
            {
                Fail(context, 400, "Invalid action.");
                return;
            }

            context.Response.Write("{\"ok\":true}");
        }

        private static void Fail(
            HttpContext context, int statusCode, string message)
        {
            context.Response.StatusCode = statusCode;

            context.Response.Write(
                new JavaScriptSerializer().Serialize(
                    new Dictionary<string, object>
                    {
                        { "ok", false },
                        { "error", message }
                    }
                )
            );
        }
    }
}
