using Oracle.ManagedDataAccess.Client;

namespace WindowsFormsApp.Data
{
    public static class DbConnectionHelper
    {
        public static OracleConnection GetConnection(string username, string password)
        {
            string connStr = $"DATA SOURCE=localhost:1521/xe;USER ID={username};PASSWORD={password};";
            return new OracleConnection(connStr);
        }
    }
}
