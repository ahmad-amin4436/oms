using System;
using System.Configuration;
using System.Data;
using System.Data.SqlClient;

namespace OMS.App_Code.DAL
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
                adapter.Fill(table);
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
                adapter.Fill(dataSet);
                return dataSet;
            }
        }

        public static int ExecuteNonQuery(string storedProcedure, params SqlParameter[] parameters)
        {
            using (var connection = new SqlConnection(ConnectionString))
            using (var command = CreateCommand(connection, storedProcedure, parameters))
            {
                connection.Open();
                return command.ExecuteNonQuery();
            }
        }

        public static object ExecuteScalar(string storedProcedure, params SqlParameter[] parameters)
        {
            using (var connection = new SqlConnection(ConnectionString))
            using (var command = CreateCommand(connection, storedProcedure, parameters))
            {
                connection.Open();
                return command.ExecuteScalar();
            }
        }

        public static SqlParameter Parameter(string name, object value)
        {
            return new SqlParameter(name, value ?? DBNull.Value);
        }

        public static SqlParameter OutputParameter(string name, SqlDbType type)
        {
            return new SqlParameter(name, type) { Direction = ParameterDirection.Output };
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
