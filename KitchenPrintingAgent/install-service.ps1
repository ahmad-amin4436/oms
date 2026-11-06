[CmdletBinding()]
param(
	[string]$ServiceName = 'KitchenPrintingAgent',
	[string]$DisplayName = 'Kitchen Printing Agent',
	[string]$ServiceExecutable = (Join-Path $PSScriptRoot 'KitchenPrintingAgent\bin\Release\KitchenPrintingAgent.exe'),
	[string]$ServiceAccount = 'LocalSystem',
	[System.Security.SecureString]$ServicePassword
)

$ErrorActionPreference = 'Stop'

if (-not (Test-Path -LiteralPath $ServiceExecutable -PathType Leaf)) {
	throw "Service executable was not found: $ServiceExecutable. Build the Release configuration first or pass -ServiceExecutable."
}

$binPath = '"' + (Resolve-Path -LiteralPath $ServiceExecutable).Path + '"'
$existing = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
if ($null -ne $existing) {
	throw "A service named '$ServiceName' already exists. Uninstall it first or choose another name."
}

& sc.exe create $ServiceName "binPath=$binPath" "start=auto" "DisplayName=$DisplayName" "obj=$ServiceAccount"
if ($LASTEXITCODE -ne 0) {
	throw "sc.exe create failed with exit code $LASTEXITCODE."
}

if ($ServiceAccount -ne 'LocalSystem' -and $null -ne $ServicePassword) {
	$password = [Runtime.InteropServices.Marshal]::PtrToStringBSTR([Runtime.InteropServices.Marshal]::SecureStringToBSTR($ServicePassword))
	try {
		& sc.exe config $ServiceName "obj=$ServiceAccount" "password=$password"
		if ($LASTEXITCODE -ne 0) {
			throw "sc.exe config failed with exit code $LASTEXITCODE."
		}
	}
	finally {
		$password = $null
	}
}

& sc.exe description $ServiceName 'Polls OMS for kitchen print jobs and sends receipts to configured department thermal printers.'
& sc.exe failure $ServiceName reset=86400 actions=restart/60000/restart/60000/restart/60000
& sc.exe failureflag $ServiceName 1

if ($LASTEXITCODE -ne 0) {
	throw "sc.exe recovery configuration failed with exit code $LASTEXITCODE."
}

& sc.exe start $ServiceName
if ($LASTEXITCODE -ne 0) {
	throw "Service was created but could not be started. Check the Windows Event Log and the agent log."
}

Write-Host "Installed and started $DisplayName ($ServiceName)."
