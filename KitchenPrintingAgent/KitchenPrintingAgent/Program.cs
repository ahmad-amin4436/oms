using System;
using System.Collections;
using System.Collections.Generic;
using System.Configuration;
using System.IO;
using System.Net.Http;
using System.Net.Sockets;
using System.ServiceProcess;
using System.Text;
using System.Threading;
using System.Web.Script.Serialization;

namespace KitchenPrintingService
{
    internal static class Program
    {
        private static void Main(string[] args)
        {
            KitchenPrintingWindowsService service = new KitchenPrintingWindowsService();

            if (args != null && Array.Exists(args, delegate (string arg)
            {
                return string.Equals(arg, "--console", StringComparison.OrdinalIgnoreCase);
            }))
            {
                service.RunConsole();
                return;
            }

            ServiceBase.Run(service);
        }
    }

    internal sealed class KitchenPrintingWindowsService : ServiceBase
    {
        private readonly ManualResetEvent stopEvent = new ManualResetEvent(false);
        private readonly object workerLock = new object();
        private Thread workerThread;
        private bool stopping;

        public KitchenPrintingWindowsService()
        {
            ServiceName = ServiceSettings.ServiceName;
            CanStop = true;
            CanPauseAndContinue = false;
            AutoLog = false;
        }

        protected override void OnStart(string[] args)
        {
            lock (workerLock)
            {
                if (workerThread != null)
                    return;

                stopping = false;
                stopEvent.Reset();
                Logger.Info("Service starting. OMS endpoint: " + ServiceSettings.ApiUrl);
                workerThread = new Thread(WorkerLoop)
                {
                    IsBackground = true,
                    Name = "KitchenPrintingWorker"
                };
                workerThread.Start();
            }
        }

        protected override void OnStop()
        {
            Thread threadToJoin;

            lock (workerLock)
            {
                if (stopping)
                    return;

                stopping = true;
                threadToJoin = workerThread;
                Logger.Info("Service stop requested.");
                stopEvent.Set();
            }

            if (threadToJoin != null && threadToJoin != Thread.CurrentThread)
                threadToJoin.Join(TimeSpan.FromSeconds(30));

            lock (workerLock)
            {
                workerThread = null;
            }

            Logger.Info("Service stopped.");
        }

        public void RunConsole()
        {
            Console.CancelKeyPress += OnConsoleCancelKeyPress;
            OnStart(null);
            Logger.Info("Console mode started. Press Ctrl+C to stop.");

            stopEvent.WaitOne();
            OnStop();
        }

        private void OnConsoleCancelKeyPress(object sender, ConsoleCancelEventArgs e)
        {
            e.Cancel = true;
            stopEvent.Set();
        }

        private void WorkerLoop()
        {
            try
            {
                while (!stopEvent.WaitOne(0))
                {
                    try
                    {
                        ProcessPrintJobs();
                    }
                    catch (Exception ex)
                    {
                        Logger.Error("Polling cycle failed; the service will continue.", ex);
                    }

                    if (stopEvent.WaitOne(ServiceSettings.PollIntervalMilliseconds))
                        break;
                }
            }
            catch (Exception ex)
            {
                Logger.Error("Unexpected worker exception; the service worker is stopping.", ex);
            }
            finally
            {
                Logger.Info("Worker stopped.");
            }
        }

        private void ProcessPrintJobs()
        {
            using (HttpResponseMessage response = HttpClientProvider.Client.GetAsync(ServiceSettings.ApiUrl).Result)
            {
                response.EnsureSuccessStatusCode();

                string json = response.Content.ReadAsStringAsync().Result;
                JavaScriptSerializer serializer = new JavaScriptSerializer();
                Dictionary<string, object> result = serializer.Deserialize<Dictionary<string, object>>(json);

                if (result == null || !result.ContainsKey("jobs") || result["jobs"] == null)
                    return;

                ArrayList jobs = result["jobs"] as ArrayList;
                if (jobs == null || jobs.Count == 0)
                    return;

                Logger.Info("Received " + jobs.Count + " print job(s) from OMS.");

                foreach (object jobObject in jobs)
                {
                    if (stopEvent.WaitOne(0))
                        break;

                    Dictionary<string, object> job = jobObject as Dictionary<string, object>;
                    if (job == null)
                    {
                        Logger.Error("OMS returned a print job with an invalid format.", null);
                        continue;
                    }

                    ProcessJob(job);
                }
            }
        }

        private void ProcessJob(Dictionary<string, object> job)
        {
            int jobId;
            try
            {
                jobId = Convert.ToInt32(job["PrintJobID"]);
            }
            catch (Exception ex)
            {
                Logger.Error("OMS returned a print job without a valid PrintJobID.", ex);
                return;
            }

            try
            {
                string printerIP = Convert.ToString(job["PrinterIP"]);
                string printerName = Convert.ToString(job.ContainsKey("PrinterName") ? job["PrinterName"] : null);
                int printerPort = GetPrinterPort(job);
                byte[] receipt = CreateReceipt(job);

                if (!string.IsNullOrWhiteSpace(printerIP))
                {
                    Logger.Info("Starting LAN print job " + jobId + " for " + printerIP + ":" + printerPort + ".");
                    SendToPrinter(printerIP, printerPort, receipt);
                }
                else if (!string.IsNullOrWhiteSpace(printerName))
                {
                    Logger.Info("Starting USB/spooler print job " + jobId + " for '" + printerName + "'.");
                    SendToWindowsPrinter(printerName, receipt);
                }
                else
                {
                    throw new InvalidOperationException("The OMS job has neither a printer IP nor a Windows printer name.");
                }

                try
                {
                    UpdateJob(jobId, "complete", "");
                    Logger.Info("Print job " + jobId + " printed and completion reported to OMS.");
                }
                catch (Exception ex)
                {
                    Logger.Error("Print job " + jobId + " was sent to the printer, but completion could not be reported. A later SQL retry may duplicate the physical print.", ex);
                }
            }
            catch (Exception ex)
            {
                Logger.Error("Print job " + jobId + " failed. Reporting failure so the existing SQL retry schedule remains authoritative.", ex);

                try
                {
                    UpdateJob(jobId, "fail", ex.Message);
                    Logger.Info("Failure for print job " + jobId + " reported to OMS.");
                }
                catch (Exception reportException)
                {
                    Logger.Error("Could not report failure for print job " + jobId + ". OMS/SQL must make the job available again according to its existing retry schedule.", reportException);
                }
            }
        }

        private static int GetPrinterPort(Dictionary<string, object> job)
        {
            int port;
            return job.ContainsKey("PrinterPort") && int.TryParse(Convert.ToString(job["PrinterPort"]), out port) && port > 0
                ? port : 9100;
        }

        private static void SendToWindowsPrinter(string printerName, byte[] data)
        {
            IntPtr handle;
            if (!RawPrinterHelper.OpenPrinter(printerName, out handle, IntPtr.Zero))
                throw new InvalidOperationException("Could not open Windows printer '" + printerName + "'.");

            try
            {
                if (!RawPrinterHelper.StartDocPrinter(handle, 1, "OMS Kitchen Receipt") ||
                    !RawPrinterHelper.StartPagePrinter(handle) ||
                    !RawPrinterHelper.WritePrinter(handle, data, data.Length))
                    throw new InvalidOperationException("Windows printer did not accept the raw receipt payload.");
            }
            finally
            {
                RawPrinterHelper.EndPagePrinter(handle);
                RawPrinterHelper.EndDocPrinter(handle);
                RawPrinterHelper.ClosePrinter(handle);
            }
        }

        private static byte[] CreateReceipt(Dictionary<string, object> job)
        {
            StringBuilder receipt = new StringBuilder();
            receipt.AppendLine();
            receipt.AppendLine("       KITCHEN ORDER");
            receipt.AppendLine("--------------------------------");
            receipt.AppendLine("Order: " + GetValue(job, "OrderNumber"));
            receipt.AppendLine("Department: " + GetValue(job, "DepartmentName"));
            receipt.AppendLine("Table: " + GetValue(job, "TableNumber"));
            receipt.AppendLine("Type: " + GetValue(job, "OrderType"));
            receipt.AppendLine("--------------------------------");
            receipt.AppendLine("Item: " + GetValue(job, "ItemName"));
            receipt.AppendLine("Quantity: " + GetValue(job, "Quantity"));

            string size = GetValue(job, "SizeName");
            if (!string.IsNullOrWhiteSpace(size))
                receipt.AppendLine("Size: " + size);

            string note = GetValue(job, "SpecialInstructions");
            if (!string.IsNullOrWhiteSpace(note))
            {
                receipt.AppendLine("--------------------------------");
                receipt.AppendLine("Instructions:");
                receipt.AppendLine(note);
            }

            receipt.AppendLine("--------------------------------");
            receipt.AppendLine();
            receipt.AppendLine();
            receipt.AppendLine();

            byte[] text = Encoding.ASCII.GetBytes(receipt.ToString());
            byte[] initialize = { 0x1B, 0x40 };
            byte[] cut = { 0x1D, 0x56, 0x00 };
            byte[] output = new byte[initialize.Length + text.Length + cut.Length];

            Buffer.BlockCopy(initialize, 0, output, 0, initialize.Length);
            Buffer.BlockCopy(text, 0, output, initialize.Length, text.Length);
            Buffer.BlockCopy(cut, 0, output, initialize.Length + text.Length, cut.Length);
            return output;
        }

        private static string GetValue(Dictionary<string, object> job, string key)
        {
            if (!job.ContainsKey(key) || job[key] == null)
                return "";

            return Convert.ToString(job[key]);
        }

        private static void SendToPrinter(string printerIP, int printerPort, byte[] data)
        {
            if (string.IsNullOrWhiteSpace(printerIP))
                throw new InvalidOperationException("The OMS printer IP is empty.");

            using (TcpClient printer = new TcpClient())
            {
                IAsyncResult connect = printer.BeginConnect(printerIP, printerPort, null, null);
                if (!connect.AsyncWaitHandle.WaitOne(ServiceSettings.PrinterConnectionTimeoutMilliseconds))
                {
                    printer.Close();
                    throw new System.TimeoutException("Timed out connecting to printer " + printerIP + ":" + printerPort + ".");
                }

                printer.EndConnect(connect);
                using (NetworkStream stream = printer.GetStream())
                {
                    stream.WriteTimeout = ServiceSettings.PrinterWriteTimeoutMilliseconds;
                    stream.Write(data, 0, data.Length);
                    stream.Flush();
                }
            }
        }

        private static class RawPrinterHelper
        {
            [System.Runtime.InteropServices.DllImport("winspool.drv", SetLastError = true, CharSet = System.Runtime.InteropServices.CharSet.Unicode)]
            internal static extern bool OpenPrinter(string name, out IntPtr handle, IntPtr defaults);
            [System.Runtime.InteropServices.DllImport("winspool.drv", SetLastError = true)]
            internal static extern bool ClosePrinter(IntPtr handle);
            [System.Runtime.InteropServices.DllImport("winspool.drv", SetLastError = true, CharSet = System.Runtime.InteropServices.CharSet.Unicode)]
            internal static extern bool StartDocPrinter(IntPtr handle, int level, string document);
            [System.Runtime.InteropServices.DllImport("winspool.drv", SetLastError = true)]
            internal static extern bool EndDocPrinter(IntPtr handle);
            [System.Runtime.InteropServices.DllImport("winspool.drv", SetLastError = true)]
            internal static extern bool StartPagePrinter(IntPtr handle);
            [System.Runtime.InteropServices.DllImport("winspool.drv", SetLastError = true)]
            internal static extern bool EndPagePrinter(IntPtr handle);
            [System.Runtime.InteropServices.DllImport("winspool.drv", SetLastError = true)]
            internal static extern bool WritePrinter(IntPtr handle, byte[] data, int length);
        }

        private static void UpdateJob(int jobId, string action, string error)
        {
            Dictionary<string, string> values = new Dictionary<string, string>
            {
                { "jobId", jobId.ToString() },
                { "action", action },
                { "error", error ?? "" }
            };

            using (FormUrlEncodedContent content = new FormUrlEncodedContent(values))
            using (HttpResponseMessage response = HttpClientProvider.Client.PostAsync(ServiceSettings.ApiUrl, content).Result)
            {
                response.EnsureSuccessStatusCode();
            }
        }
    }

    internal static class ServiceSettings
    {
        public static readonly string ServiceName = GetString("ServiceName", "KitchenPrintingAgent");
        public static readonly string ApiUrl = GetRequiredString("OmsPrintFeedUrl");
        public static readonly int PollIntervalMilliseconds = GetPositiveInt("PollIntervalSeconds", 5) * 1000;
        public static readonly int PrinterConnectionTimeoutMilliseconds = GetPositiveInt("PrinterConnectionTimeoutSeconds", 10) * 1000;
        public static readonly int PrinterWriteTimeoutMilliseconds = GetPositiveInt("PrinterWriteTimeoutSeconds", 10) * 1000;
        public static readonly string LogPath = GetString("LogPath", Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.CommonApplicationData), "KitchenPrintingAgent", "KitchenPrintingAgent.log"));

        private static string GetRequiredString(string key)
        {
            string value = ConfigurationManager.AppSettings[key];
            if (string.IsNullOrWhiteSpace(value))
                throw new ConfigurationErrorsException("Missing required appSetting: " + key);

            return value;
        }

        private static string GetString(string key, string defaultValue)
        {
            string value = ConfigurationManager.AppSettings[key];
            return string.IsNullOrWhiteSpace(value) ? defaultValue : value;
        }

        private static int GetPositiveInt(string key, int defaultValue)
        {
            int value;
            return int.TryParse(ConfigurationManager.AppSettings[key], out value) && value > 0 ? value : defaultValue;
        }
    }

    internal static class HttpClientProvider
    {
        public static readonly HttpClient Client = CreateClient();

        private static HttpClient CreateClient()
        {
            HttpClient client = new HttpClient
            {
                Timeout = TimeSpan.FromSeconds(30)
            };
            return client;
        }
    }

    internal static class Logger
    {
        private static readonly object SyncRoot = new object();

        public static void Info(string message)
        {
            Write("INFO", message, null);
        }

        public static void Error(string message, Exception exception)
        {
            Write("ERROR", message, exception);
        }

        private static void Write(string level, string message, Exception exception)
        {
            string line = DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss.fff") + " [" + level + "] " + message;
            if (exception != null)
                line += Environment.NewLine + exception;

            try
            {
                lock (SyncRoot)
                {
                    string directory = Path.GetDirectoryName(ServiceSettings.LogPath);
                    if (!string.IsNullOrWhiteSpace(directory))
                        Directory.CreateDirectory(directory);
                    File.AppendAllText(ServiceSettings.LogPath, line + Environment.NewLine);
                }
            }
            catch
            {
                if (Environment.UserInteractive)
                    Console.Error.WriteLine(line);
            }

            if (Environment.UserInteractive)
                Console.WriteLine(line);
        }
    }
}
