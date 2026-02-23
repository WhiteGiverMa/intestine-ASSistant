<#
.SYNOPSIS
    Intestine ASSistant Service Manager
.DESCRIPTION
    Manage local Flutter Web service - status check, start and stop
.EXAMPLE
    .\manage_service.ps1          # Show status and interactive menu
    .\manage_service.ps1 start    # Start service
    .\manage_service.ps1 stop     # Stop service
    .\manage_service.ps1 status   # Show status only
#>

param(
    [Parameter(Position=0)]
    [ValidateSet("start", "stop", "status", "toggle")]
    [string]$Action
)

$ErrorActionPreference = "Stop"
try { $Host.UI.RawUI.WindowTitle = "Intestine ASSistant - Service Manager" } catch {}

$FLUTTER_PORT = 5174
$PROJECT_DIR = $PSScriptRoot
$FRONTEND_DIR = Join-Path $PROJECT_DIR "frontend_Flutter"

function Write-Header {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "   Intestine ASSistant - Service Manager" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
}

function Get-FlutterProcess {
    $flutterProcesses = @()

    $dartProcesses = Get-Process -Name "dart" -ErrorAction SilentlyContinue
    foreach ($proc in $dartProcesses) {
        try {
            $connections = Get-NetTCPConnection -OwningProcess $proc.Id -ErrorAction SilentlyContinue
            $portConn = $connections | Where-Object { $_.LocalPort -eq $FLUTTER_PORT -and $_.State -eq "Listen" }
            if ($portConn) {
                $flutterProcesses += [PSCustomObject]@{
                    Id = $proc.Id
                    Port = $FLUTTER_PORT
                    StartTime = $proc.StartTime
                    Name = $proc.ProcessName
                }
            }
        } catch {}
    }

    if ($flutterProcesses.Count -eq 0) {
        $flutterProcesses = Get-Process -Name "flutter" -ErrorAction SilentlyContinue
        $result = @()
        foreach ($proc in $flutterProcesses) {
            try {
                $connections = Get-NetTCPConnection -OwningProcess $proc.Id -ErrorAction SilentlyContinue
                $portConn = $connections | Where-Object { $_.LocalPort -eq $FLUTTER_PORT }
                if ($portConn) {
                    $result += [PSCustomObject]@{
                        Id = $proc.Id
                        Port = $FLUTTER_PORT
                        StartTime = $proc.StartTime
                        Name = $proc.ProcessName
                    }
                }
            } catch {}
        }
        $flutterProcesses = $result
    }

    return $flutterProcesses
}

function Test-ServiceRunning {
    $processes = Get-FlutterProcess
    return $processes.Count -gt 0
}

function Show-Status {
    Write-Header

    $isRunning = Test-ServiceRunning

    if ($isRunning) {
        $processes = Get-FlutterProcess
        Write-Host "Flutter Web Status: " -NoNewline
        Write-Host "RUNNING" -ForegroundColor Green
        Write-Host ""
        Write-Host "Service Info:" -ForegroundColor Yellow
        foreach ($proc in $processes) {
            Write-Host "  PID: $($proc.Id)"
            Write-Host "  Name: $($proc.Name)"
            Write-Host "  Port: $($proc.Port)"
            Write-Host "  Started: $($proc.StartTime)"
        }
        Write-Host ""
        Write-Host "URL: " -NoNewline
        Write-Host "http://localhost:$FLUTTER_PORT" -ForegroundColor Cyan
    } else {
        Write-Host "Flutter Web Status: " -NoNewline
        Write-Host "NOT RUNNING" -ForegroundColor Red
        Write-Host ""
        Write-Host "Tip: Use 'start' or press 'S' to start service" -ForegroundColor Gray
    }

    Write-Host ""
    return $isRunning
}

function Start-FlutterService {
    if (Test-ServiceRunning) {
        Write-Host "Service is already running!" -ForegroundColor Yellow
        return
    }

    $portInUse = Get-NetTCPConnection -LocalPort $FLUTTER_PORT -ErrorAction SilentlyContinue
    if ($portInUse) {
        Write-Host "Warning: Port $FLUTTER_PORT is already in use by another process!" -ForegroundColor Yellow
        Write-Host "The service may fail to start. Stop the conflicting process first." -ForegroundColor Yellow
        Write-Host ""
    }

    Write-Host "Starting Flutter Web service..." -ForegroundColor Yellow

    if (-not (Test-Path $FRONTEND_DIR)) {
        Write-Host "Error: frontend_Flutter directory not found" -ForegroundColor Red
        return
    }

    Push-Location $FRONTEND_DIR

    try {
        $flutterCmd = Get-Command flutter -ErrorAction SilentlyContinue
        if (-not $flutterCmd) {
            Write-Host "Error: Flutter SDK not found. Please ensure Flutter is installed and in PATH" -ForegroundColor Red
            Pop-Location
            return
        }

        Write-Host "Running: flutter run -d chrome --web-port=$FLUTTER_PORT" -ForegroundColor Gray
        Write-Host ""

        Start-Process -FilePath "flutter" `
                      -ArgumentList "run", "-d", "chrome", "--web-port=$FLUTTER_PORT" `
                      -WorkingDirectory $FRONTEND_DIR

        Write-Host "Service start command executed, please wait for compilation..." -ForegroundColor Green
        Write-Host "URL: http://localhost:$FLUTTER_PORT" -ForegroundColor Cyan

        Start-Sleep -Seconds 3
        Show-Status
    }
    finally {
        Pop-Location
    }
}

function Stop-FlutterService {
    $processes = Get-FlutterProcess

    if ($processes.Count -eq 0) {
        Write-Host "Service is not running!" -ForegroundColor Yellow
        return
    }

    Write-Host "Stopping Flutter Web service..." -ForegroundColor Yellow

    foreach ($proc in $processes) {
        try {
            Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue
            Write-Host "Stopped process PID: $($proc.Id)" -ForegroundColor Green
        } catch {
            Write-Host "Failed to stop process PID: $($proc.Id) - $_" -ForegroundColor Red
        }
    }

    Start-Sleep -Seconds 1

    if (Test-ServiceRunning) {
        Write-Host "Warning: Service may not be fully stopped" -ForegroundColor Yellow
    } else {
        Write-Host "Service stopped" -ForegroundColor Green
    }
}

function Show-Menu {
    $isRunning = Show-Status

    Write-Host "Actions:" -ForegroundColor Yellow
    if ($isRunning) {
        Write-Host "  [S] Stop service"
        Write-Host "  [T] Restart service"
    } else {
        Write-Host "  [S] Start service"
    }
    Write-Host "  [R] Refresh status"
    Write-Host "  [Q] Quit"
    Write-Host ""
}

function Invoke-Interactive {
    while ($true) {
        Show-Menu
        try {
            $key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            $char = $key.Character.ToString().ToLower()
        } catch {
            Write-Host "Non-interactive mode detected. Use: .\manage_service.ps1 [start|stop|status|toggle]" -ForegroundColor Yellow
            return
        }

        switch ($char) {
            "s" {
                if (Test-ServiceRunning) {
                    Stop-FlutterService
                } else {
                    Start-FlutterService
                }
            }
            "t" {
                if (Test-ServiceRunning) {
                    Stop-FlutterService
                    Start-Sleep -Seconds 1
                    Start-FlutterService
                }
            }
            "r" {
                continue
            }
            "q" {
                Write-Host "Bye!" -ForegroundColor Green
                return
            }
            default {
                Write-Host "Invalid option: $char" -ForegroundColor Red
            }
        }

        Write-Host ""
        Write-Host "Press any key to continue..." -ForegroundColor Gray
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    }
}

# Main
switch ($Action) {
    "start" {
        Write-Header
        Start-FlutterService
    }
    "stop" {
        Write-Header
        Stop-FlutterService
    }
    "status" {
        Show-Status
    }
    "toggle" {
        Write-Header
        if (Test-ServiceRunning) {
            Stop-FlutterService
        } else {
            Start-FlutterService
        }
    }
    default {
        Invoke-Interactive
    }
}
