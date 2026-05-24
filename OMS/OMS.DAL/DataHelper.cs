using System;
using System.Configuration;
using System.Data;
using System.Data.Common;
using Microsoft.Practices.EnterpriseLibrary.Data;
using Microsoft.Practices.EnterpriseLibrary.Data.Sql;

namespace OMS.DAL
{
    /// <summary>
    /// Central data-access helper built on the Microsoft Enterprise Library
    /// Data Access Application Block (DAAB).
    /// All database calls in OMS.DAL go through this class.
    /// </summary>
    public static class DataHelper
    {
        private const string ConnectionName = "RMSConnection";

        // Creates a SqlDatabase using the named connection string from Web/App.config.
        // Using direct instantiation avoids requiring the <dataConfiguration> config section.
        private static Database CreateDatabase()
        {
            var cs = ConfigurationManager.ConnectionStrings[ConnectionName]?.ConnectionString;
            if (string.IsNullOrWhiteSpace(cs))
                throw new InvalidOperationException(
                    $"Connection string '{ConnectionName}' is not defined in configuration.");

            return new SqlDatabase(cs);
        }

        // ----------------------------------------------------------------
        // Public execution methods
        // ----------------------------------------------------------------

        public static DataSet ExecuteDataSet(string storedProcedure, params IDbDataParameter[] parameters)
        {
            var db = CreateDatabase();
            using (var cmd = db.GetStoredProcCommand(storedProcedure))
            {
                AddParameters(cmd, parameters);
                return db.ExecuteDataSet(cmd);
            }
        }

        public static DataTable ExecuteDataTable(string storedProcedure, params IDbDataParameter[] parameters)
        {
            var ds = ExecuteDataSet(storedProcedure, parameters);
            return ds.Tables.Count > 0 ? ds.Tables[0] : new DataTable();
        }

        public static int ExecuteNonQuery(string storedProcedure, params IDbDataParameter[] parameters)
        {
            var db = CreateDatabase();
            using (var cmd = db.GetStoredProcCommand(storedProcedure))
            {
                AddParameters(cmd, parameters);
                return db.ExecuteNonQuery(cmd);
            }
        }

        public static object ExecuteScalar(string storedProcedure, params IDbDataParameter[] parameters)
        {
            var db = CreateDatabase();
            using (var cmd = db.GetStoredProcCommand(storedProcedure))
            {
                AddParameters(cmd, parameters);
                return db.ExecuteScalar(cmd);
            }
        }

        public static IDataReader ExecuteReader(string storedProcedure, params IDbDataParameter[] parameters)
        {
            var db = CreateDatabase();
            var cmd = db.GetStoredProcCommand(storedProcedure);
            AddParameters(cmd, parameters);
            // Caller is responsible for disposing the reader (and its underlying connection).
            return db.ExecuteReader(cmd);
        }

        // ----------------------------------------------------------------
        // Parameter factory helpers
        // ----------------------------------------------------------------

        public static IDbDataParameter Param(string name, DbType dbType, object value)
        {
            var db = CreateDatabase();
            var p = db.DbProviderFactory.CreateParameter();
            p.ParameterName = name;
            p.DbType        = dbType;
            p.Value         = value ?? DBNull.Value;
            return p;
        }

        public static IDbDataParameter ParamString(string name, object value, int size = 500)
        {
            var db = CreateDatabase();
            var p  = db.DbProviderFactory.CreateParameter();
            p.ParameterName = name;
            p.DbType        = DbType.String;
            p.Size          = size;
            p.Value         = value ?? DBNull.Value;
            return p;
        }

        public static IDbDataParameter ParamInt(string name, object value)
            => Param(name, DbType.Int32, value);

        public static IDbDataParameter ParamBool(string name, object value)
            => Param(name, DbType.Boolean, value);

        public static IDbDataParameter ParamDecimal(string name, object value)
            => Param(name, DbType.Decimal, value);

        public static IDbDataParameter ParamDateTime(string name, object value)
            => Param(name, DbType.DateTime2, value);

        // ----------------------------------------------------------------
        // Private helpers
        // ----------------------------------------------------------------

        private static void AddParameters(DbCommand cmd, IDbDataParameter[] parameters)
        {
            if (parameters == null) return;
            foreach (var p in parameters)
                cmd.Parameters.Add(p);
        }
    }
}
