param(
    [string]$Host = "127.0.0.1",
    [int]$Port = 8765
)

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$healthUrl = "http://$Host`:$Port/health"

function Test-Backend {
    param([string]$Url)

    try {
        $response = Invoke-WebRequest -UseBasicParsing -Uri $Url -TimeoutSec 2
        return $response.StatusCode -eq 200
    }
    catch {
        return $false
    }
}

Set-Location $scriptDir

if (-not (Test-Backend -Url $healthUrl)) {
    $pythonCommand = Get-Command python -ErrorAction Stop

    Start-Process `
        -FilePath $pythonCommand.Source `
        -ArgumentList @("-m", "uvicorn", "main:app", "--host", $Host, "--port", $Port.ToString()) `
        -WorkingDirectory $scriptDir

    $backendReady = $false
    for ($i = 0; $i -lt 12; $i++) {
        Start-Sleep -Seconds 1
        if (Test-Backend -Url $healthUrl) {
            $backendReady = $true
            break
        }
    }

    if (-not $backendReady) {
        throw "Backend no respondio en $healthUrl."
    }
}

dotnet run --project (Join-Path $scriptDir "VfpWebViewHost.csproj")
