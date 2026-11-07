# KitchenPrintingAgent Windows Service

`KitchenPrintingAgent` targets .NET Framework 4.7.2 and runs as the `KitchenPrintingAgent` Windows Service. It polls the existing OMS `KitchenPrintFeed.ashx` endpoint, processes the returned jobs sequentially, sends the existing ESC/POS receipt payload to the OMS-configured department printer, and reports `complete` or `fail` using the existing API contract.

OMS, SQL stored procedures, and PrinterSimulator are separate components. PrinterSimulator is for local testing only and is not included in the restaurant service deployment.

## Build

1. Open `KitchenPrintingAgent.sln` in Visual Studio.
2. Select `Release` and `Any CPU`.
3. Build the solution.
4. Confirm that `KitchenPrintingAgent\bin\Release\KitchenPrintingAgent.exe` and its `.config` file exist.

The service host requires the .NET Framework 4.7.2 runtime on the restaurant computer.

## Configure

Before installation, edit the deployed `KitchenPrintingAgent.exe.config` (copied from `App.config`):

- Set `OmsPrintFeedUrl` to the reachable OMS `KitchenPrintFeed.ashx` endpoint.
- Keep `PollIntervalSeconds` at `5` unless OMS operations explicitly require another value.
- Keep the printer timeout values reasonable for the restaurant network.
- Leave `LogPath` blank to log to `%ProgramData%\KitchenPrintingAgent\KitchenPrintingAgent.log`, or set an explicit path.

Printer IP addresses and ports must come from the OMS job data. Do not put restaurant printer addresses in this application configuration. Configure TCP port `9100` in the OMS database where that is the printer's configured port.

## Install

Run PowerShell as Administrator from the repository root after building Release:

```powershell
Set-ExecutionPolicy -Scope Process Bypass
.\install-service.ps1
```

The script creates an automatic-start service, configures Windows Service Recovery to restart it after failures, and starts it. To use a dedicated account instead of LocalSystem, provide `-ServiceAccount` and a `SecureString` password, or configure the account and password through the Services management console after installation.

Example with a different executable location:

```powershell
.\install-service.ps1 -ServiceExecutable 'C:\KitchenPrintingAgent\KitchenPrintingAgent.exe'
```

The service can also be started, stopped, and inspected through `services.msc` or with `Start-Service`, `Stop-Service`, and `Get-Service`.

## Uninstall

Run PowerShell as Administrator:

```powershell
Set-ExecutionPolicy -Scope Process Bypass
.\uninstall-service.ps1
```

Stop the service before replacing the executable or configuration during an upgrade.

## Service account and network access

The selected service account must have:

- Read and execute permission for the installation directory and `KitchenPrintingAgent.exe.config`.
- Write/create permission for the log directory, normally `%ProgramData%\KitchenPrintingAgent`.
- Outbound HTTP/HTTPS access to the OMS endpoint.
- Outbound TCP access to every department printer IP and configured port, normally TCP 9100.
- Permission to run as a Windows service (`Log on as a service`) when using a dedicated account.

Allow the required outbound traffic through local and restaurant firewalls. No inbound listener is required by the agent.

## Runtime behavior and recovery

- The worker polls immediately on startup and then waits five seconds between completed polling cycles.
- Only one polling cycle and one job are processed at a time; cycles cannot overlap.
- API, database/OMS reporting, printer connection, write, and unexpected errors are logged and do not terminate the worker.
- A stop request signals the worker and waits for the current bounded operation to finish.
- Failure reporting uses the existing `fail` action. The agent does not create a second retry counter or retry scheduler; SQL remains responsible for the retry schedule and its maximum of five total attempts.
- A job is reported `complete` only after the printer write succeeds and the existing completion request succeeds.
- Exactly-once physical printing is not guaranteed. If the printer accepts a receipt but the completion request fails, OMS/SQL may make the job available again and the next attempt can duplicate the physical receipt.

Logs include startup/shutdown, polling errors, printer connection errors, successful prints, failure reporting, retry-related failure messages, and unexpected exceptions. Review the log at the configured path and the Windows Service Control Manager/Event Viewer when diagnosing startup or recovery problems.

## Test checklist

1. Use `KitchenPrintingAgent.exe --console` with a local OMS endpoint for development; stop it with Ctrl+C.
2. Confirm a normal job is received, printed to the OMS-configured printer, and completed in OMS.
3. Disconnect the printer and confirm the connection failure is logged and the job is reported as `fail`.
4. Make OMS temporarily unreachable and confirm the service continues polling after the outage.
5. Restore the printer/OMS and confirm later SQL-scheduled attempts are processed.
6. Stop and start the Windows service through `services.msc` and confirm startup/shutdown entries and safe recovery.
7. Verify `PrinterSimulator` is not present in the release deployment directory.
