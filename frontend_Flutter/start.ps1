param(
    [int]$StartPort = 5174,
    [int]$MaxAttempts = 100
)

function Test-PortAvailable {
    param([int]$Port)

    $connections = netstat -ano | Select-String ":$Port\s" | Select-String "LISTENING"
    return $null -eq $connections
}

function Find-AvailablePort {
    param([int]$StartPort, [int]$MaxAttempts)

    for ($port = $StartPort; $port -lt ($StartPort + $MaxAttempts); $port++) {
        if (Test-PortAvailable -Port $port) {
            return $port
        }
        Write-Host "Port $port is in use, trying next..." -ForegroundColor Yellow
    }
    return $null
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Intestine ASSistant - Flutter Web" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$port = Find-AvailablePort -StartPort $StartPort -MaxAttempts $MaxAttempts

if ($null -eq $port) {
    Write-Host "Error: No available port found in range $StartPort to $($StartPort + $MaxAttempts - 1)" -ForegroundColor Red
    exit 1
}

Write-Host "Found available port: $port" -ForegroundColor Green
Write-Host "Starting Flutter Web..." -ForegroundColor Green
Write-Host ""

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $scriptDir

flutter run -d chrome --web-port=$port
