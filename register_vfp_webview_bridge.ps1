param(
    [ValidateSet("Debug", "Release")]
    [string]$Configuration = "Debug",
    [switch]$Unregister
)

$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectPath = Join-Path $scriptDir "VfpWebViewBridge.csproj"

dotnet build $projectPath -c $Configuration

$outputDir = Join-Path $scriptDir ("bin\" + $Configuration + "\net8.0-windows")
$comHostPath = Join-Path $outputDir "VfpWebViewBridge.comhost.dll"
$regsvr32Path = Join-Path $env:WINDIR "SysWOW64\regsvr32.exe"

if (-not (Test-Path $comHostPath)) {
    throw "No se encontro el COM host esperado: $comHostPath"
}

$arguments = @("/s")
if ($Unregister) {
    $arguments += "/u"
}
$arguments += $comHostPath

Start-Process -FilePath $regsvr32Path -ArgumentList $arguments -Verb RunAs -Wait

if ($Unregister) {
    Write-Host "Bridge COM eliminado del registro:" $comHostPath
}
else {
    Write-Host "Bridge COM registrado:" $comHostPath
}
