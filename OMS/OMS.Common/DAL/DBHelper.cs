using System;
using System.Configuration;
using System.Data;
using System.Data.SqlClient;
using System.Diagnostics;
using System.Linq;
using OMS.Common.Helpers;

namespace OMS.Common.DAL
{
    public static class DBHelper
    {
        private static string ConnectionString
        {
            get { return ConfigurationManager.ConnectionStrings["RMSConnection"].ConnectionString; }
        }

        public static DataTable ExecuteDataTable(string storedProcedure, params SqlParameter[] parameters)
        {
            using (var connection = new SqlConnection(ConnectionString))
            using (var command = CreateCommand(connection, storedProcedure, parameters))
            using (var adapter = new SqlDataAdapter(command))
            {
                var table = new DataTable();
                var sw = Stopwatch.StartNew();
                adapter.Fill(table);
                DbStats.Record(storedProcedure, sw.ElapsedMilliseconds);
                AfterWrite(storedProcedure);
                return table;
            }
        }

        public static DataSet ExecuteDataSet(string storedProcedure, params SqlParameter[] parameters)
        {
            using (var connection = new SqlConnection(ConnectionString))
            using (var command = CreateCommand(connection, storedProcedure, parameters))
            using (var adapter = new SqlDataAdapter(command))
            {
                var dataSet = new DataSet();
                var sw = Stopwatch.StartNew();
                adapter.Fill(dataSet);
                DbStats.Record(storedProcedure, sw.ElapsedMilliseconds);
                AfterWrite(storedProcedure);
                return dataSet;
            }
        }

        public static int ExecuteNonQuery(string storedProcedure, params SqlParameter[] parameters)
        {
            using (var connection = new SqlConnection(ConnectionString))
            using (var command = CreateCommand(connection, storedProcedure, parameters))
            {
                var sw = Stopwatch.StartNew();
                connection.Open();
                var rows = command.ExecuteNonQuery();
                DbStats.Record(storedProcedure, sw.ElapsedMilliseconds);
                AfterWrite(storedProcedure);
                return rows;
            }
        }

        public static object ExecuteScalar(string storedProcedure, params SqlParameter[] parameters)
        {
            using (var connection = new SqlConnection(ConnectionString))
            using (var command = CreateCommand(connection, storedProcedure, parameters))
            {
                var sw = Stopwatch.StartNew();
                connection.Open();
                var value = command.ExecuteScalar();
                DbStats.Record(storedProcedure, sw.ElapsedMilliseconds);
                AfterWrite(storedProcedure);
                return value;
            }
        }

        // A write bumps its cache scope, so cached reads never outlive an edit.
        private static void AfterWrite(string storedProcedure)
        {
            string scope = AppCache.ScopeForWrite(storedProcedure);
            if (scope != null) AppCache.Clear(scope);
        }

        private static string CacheKey(string storedProcedure, SqlParameter[] parameters)
        {
            return storedProcedure + "(" + string.Join(",", (parameters ?? new SqlParameter[0])
                .Select(p => p.ParameterName + "=" + Convert.ToString(p.Value))) + ")";
        }

        /// <summary>Read-through cache for lookup data that changes rarely. Returns a private copy.</summary>
        public static DataTable CachedDataTable(string scope, int seconds, string storedProcedure, params SqlParameter[] parameters)
        {
            return AppCache.GetOrAdd<DataTable>(scope, CacheKey(storedProcedure, parameters), seconds,
                () => ExecuteDataTable(storedProcedure, parameters)).Copy();
        }

        public static DataSet CachedDataSet(string scope, int seconds, string storedProcedure, params SqlParameter[] parameters)
        {
            return AppCache.GetOrAdd<DataSet>(scope, CacheKey(storedProcedure, parameters), seconds,
                () => ExecuteDataSet(storedProcedure, parameters)).Copy();
        }
        public static SqlParameter Parameter(string name, object value)
        {
            return new SqlParameter(name, value ?? DBNull.Value);
        }

        public static SqlParameter OutputParameter(string name, SqlDbType type)
        {
            // InputOutput: the save procedures need the caller's current ID (0 = new) as well as returning the saved one.
            // A plain Output parameter is sent to the server as NULL, which made every "edit" look like an insert.
            return new SqlParameter(name, type) { Direction = ParameterDirection.InputOutput, Value = DBNull.Value };
        }

        private static SqlCommand CreateCommand(SqlConnection connection, string storedProcedure, SqlParameter[] parameters)
        {
            var command = new SqlCommand(storedProcedure, connection)
            {
                CommandType = CommandType.StoredProcedure,
                CommandTimeout = 60
            };

            if (parameters != null)
            {
                command.Parameters.AddRange(parameters);
            }

            return command;
        }
    }
}
