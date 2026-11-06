[CmdletBinding()]
param(
	[string]$ServiceName = 'KitchenPrintingAgent'
)

$ErrorActionPreference = 'Stop'
$service = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue

if ($null -eq $service) {
	Write-Host "Service '$ServiceName' is not installed."
	exit 0
}

if ($service.Status -ne 'Stopped') {
	Stop-Service -Name $ServiceName -Force -ErrorAction Stop
	$service.WaitForStatus([System.ServiceProcess.ServiceControllerStatus]::Stopped, (New-TimeSpan -Seconds 30))
}

& sc.exe delete $ServiceName
if ($LASTEXITCODE -ne 0) {
	throw "sc.exe delete failed with exit code $LASTEXITCODE."
}

Write-Host "Uninstalled $ServiceName."
