<#
.SYNOPSIS
    Intestine ASSistant - Service Manager
.DESCRIPTION
    Manage backend and frontend services
#>

$BackendPort = 8001
$FrontendPort = 5174
$PythonPath = ".venv\Scripts\python.exe"
$BackendDir = "backend"
$FrontendDir = "mobile_app"

function Get-BackendStatus {
    $connections = Get-NetTCPConnection -LocalPort $BackendPort -State Listen -ErrorAction SilentlyContinue
    $results = @()
    
    if ($connections) {
        foreach ($conn in $connections) {
            $process = Get-Process -Id $conn.OwningProcess -ErrorAction SilentlyContinue
            if ($process) {
                $results += @{
                    PID = $conn.OwningProcess
                    ProcessName = $process.ProcessName
                    StartTime = if ($process.StartTime) { $process.StartTime } else { "Unknown" }
                }
            }
        }
    }
    
    if ($results.Count -gt 0) {
        return @{ Running = $true; Processes = $results }
    }
    
    try {
        $null = Invoke-WebRequest -Uri "http://localhost:$BackendPort/docs" -Method Get -TimeoutSec 3 -UseBasicParsing
        $results += @{
            PID = "Unknown"
            ProcessName = "Unknown (parent exited)"
            StartTime = "Unknown"
        }
        return @{ Running = $true; Processes = $results }
    } catch { }
    
    return @{ Running = $false; Processes = @() }
}

function Get-FrontendStatus {
    $connections = Get-NetTCPConnection -LocalPort $FrontendPort -State Listen -ErrorAction SilentlyContinue
    $results = @()
    
    if ($connections) {
        foreach ($conn in $connections) {
            $process = Get-Process -Id $conn.OwningProcess -ErrorAction SilentlyContinue
            if ($process) {
                $results += @{
                    PID = $conn.OwningProcess
                    ProcessName = $process.ProcessName
                }
            }
        }
    }
    
    if ($results.Count -gt 0) {
        return @{ Running = $true; Processes = $results }
    }
    
    try {
        $null = Invoke-WebRequest -Uri "http://localhost:$FrontendPort" -Method Get -TimeoutSec 3 -UseBasicParsing
        $results += @{
            PID = "Unknown"
            ProcessName = "Unknown (parent exited)"
        }
        return @{ Running = $true; Processes = $results }
    } catch { }
    
    return @{ Running = $false; Processes = @() }
}

function Show-Status {
    Clear-Host
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host "           Intestine ASSistant - Service Manager" -ForegroundColor Cyan
    Write-Host "============================================================" -ForegroundColor Cyan
    
    Write-Host ""
    Write-Host " [Backend Service] Port: $BackendPort" -ForegroundColor Yellow
    $backendStatus = Get-BackendStatus
    if ($backendStatus.Running) {
        Write-Host "   Status: " -NoNewline
        Write-Host "[Running]" -ForegroundColor Green
        foreach ($proc in $backendStatus.Processes) {
            Write-Host "   - PID: $($proc.PID) ($($proc.ProcessName))"
        }
        Write-Host "   API Docs: " -NoNewline
        Write-Host "http://localhost:$BackendPort/docs" -ForegroundColor Blue
    } else {
        Write-Host "   Status: " -NoNewline
        Write-Host "[Stopped]" -ForegroundColor Red
    }
    
    Write-Host ""
    Write-Host " [Frontend Service] Port: $FrontendPort" -ForegroundColor Yellow
    $frontendStatus = Get-FrontendStatus
    if ($frontendStatus.Running) {
        Write-Host "   Status: " -NoNewline
        Write-Host "[Running]" -ForegroundColor Green
        foreach ($proc in $frontendStatus.Processes) {
            Write-Host "   - PID: $($proc.PID) ($($proc.ProcessName))"
        }
        Write-Host "   URL: " -NoNewline
        Write-Host "http://localhost:$FrontendPort" -ForegroundColor Blue
    } else {
        Write-Host "   Status: " -NoNewline
        Write-Host "[Stopped]" -ForegroundColor Red
    }
    
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
}

function Start-Backend {
    $status = Get-BackendStatus
    if ($status.Running) {
        Write-Host "[Warning] Backend service is already running" -ForegroundColor Yellow
        return $false
    }
    
    Write-Host "`nStarting backend service..." -ForegroundColor Cyan
    
    $cmdArgs = "/c cd $BackendDir & ..\$PythonPath -m uvicorn app.main:app --reload --host 0.0.0.0 --port $BackendPort"
    Start-Process -FilePath "cmd.exe" -ArgumentList $cmdArgs -WindowStyle Normal
    
    Start-Sleep -Seconds 3
    
    $newStatus = Get-BackendStatus
    if ($newStatus.Running) {
        Write-Host "[Success] Backend service started" -ForegroundColor Green
        return $true
    } else {
        Write-Host "[Failed] Backend service failed to start, please check logs" -ForegroundColor Red
        return $false
    }
}

function Stop-Backend {
    Write-Host "`nStopping backend service..." -ForegroundColor Cyan
    
    $status = Get-BackendStatus
    if (-not $status.Running) {
        Write-Host "[Info] Backend service is not running" -ForegroundColor Yellow
        return
    }
    
    $killedCount = 0
    $hasUnknownPid = $false
    
    foreach ($proc in $status.Processes) {
        if ($proc.PID -eq "Unknown") {
            $hasUnknownPid = $true
            Write-Host "[Info] Detected orphaned process (parent exited), will use port-based cleanup" -ForegroundColor Yellow
            continue
        }
        try {
            $result = taskkill /F /T /PID $proc.PID 2>&1
            if ($LASTEXITCODE -eq 0) {
                Write-Host "[Success] Terminated process tree: $($proc.PID)" -ForegroundColor Green
                $killedCount++
            } else {
                Write-Host "[Warning] taskkill exit code: $LASTEXITCODE for PID $($proc.PID)" -ForegroundColor Yellow
            }
        } catch {
            Write-Host "[Error] Cannot terminate process $($proc.PID): $_" -ForegroundColor Red
        }
    }
    
    Start-Sleep -Seconds 1
    
    $remaining = Get-BackendStatus
    if ($remaining.Running) {
        Write-Host "[Warning] Some processes still running, force cleaning..." -ForegroundColor Yellow
        
        $connections = Get-NetTCPConnection -LocalPort $BackendPort -ErrorAction SilentlyContinue
        foreach ($conn in $connections) {
            try {
                $proc = Get-Process -Id $conn.OwningProcess -ErrorAction SilentlyContinue
                if ($proc) {
                    Stop-Process -Id $conn.OwningProcess -Force -ErrorAction SilentlyContinue
                    Write-Host "[Cleanup] Force terminated process: $($conn.OwningProcess) ($($proc.ProcessName))" -ForegroundColor Yellow
                    $killedCount++
                }
            } catch { }
        }
        
        $pythonProcs = Get-Process -Name python -ErrorAction SilentlyContinue
        foreach ($py in $pythonProcs) {
            try {
                $cmd = (Get-CimInstance Win32_Process -Filter "ProcessId=$($py.Id)" -ErrorAction SilentlyContinue).CommandLine
                if ($cmd -match "uvicorn|backend|multiprocessing.*spawn.*parent_pid") {
                    Stop-Process -Id $py.Id -Force -ErrorAction SilentlyContinue
                    Write-Host "[Cleanup] Terminated python process: $($py.Id)" -ForegroundColor Yellow
                    $killedCount++
                }
            } catch { }
        }
    }
    
    Start-Sleep -Seconds 2
    
    $finalCheck = Get-BackendStatus
    if ($finalCheck.Running) {
        Write-Host "[Error] Failed to stop backend service completely" -ForegroundColor Red
    } else {
        Write-Host "[Done] Stopped $killedCount backend process(es)" -ForegroundColor Green
    }
}

function Start-Frontend {
    $status = Get-FrontendStatus
    if ($status.Running) {
        Write-Host "[Warning] Frontend service is already running" -ForegroundColor Yellow
        return $false
    }
    
    Write-Host "`nStarting frontend service..." -ForegroundColor Cyan
    
    $cmdArgs = "/c cd $FrontendDir & flutter run -d chrome --web-port=$FrontendPort"
    Start-Process -FilePath "cmd.exe" -ArgumentList $cmdArgs -WindowStyle Normal
    
    Write-Host "[Info] Flutter Web takes time to start, please wait..." -ForegroundColor Yellow
    Start-Sleep -Seconds 5
    
    $newStatus = Get-FrontendStatus
    if ($newStatus.Running) {
        Write-Host "[Success] Frontend service started" -ForegroundColor Green
        return $true
    } else {
        Write-Host "[Info] Frontend service is starting, please refresh page later..." -ForegroundColor Yellow
        return $true
    }
}

function Stop-Frontend {
    Write-Host "`nStopping frontend service..." -ForegroundColor Cyan
    
    $status = Get-FrontendStatus
    if (-not $status.Running) {
        Write-Host "[Info] Frontend service is not running" -ForegroundColor Yellow
        return
    }
    
    $killedCount = 0
    
    foreach ($proc in $status.Processes) {
        if ($proc.PID -eq "Unknown") {
            Write-Host "[Info] Detected orphaned process (parent exited), will use port-based cleanup" -ForegroundColor Yellow
            continue
        }
        try {
            Stop-Process -Id $proc.PID -Force -ErrorAction SilentlyContinue
            Write-Host "[Success] Terminated process: $($proc.PID) ($($proc.ProcessName))" -ForegroundColor Green
            $killedCount++
        } catch {
            Write-Host "[Error] Cannot terminate process $($proc.PID): $_" -ForegroundColor Red
        }
    }
    
    Start-Sleep -Seconds 2
    
    $remaining = Get-FrontendStatus
    if ($remaining.Running) {
        Write-Host "[Warning] Some processes still running, force cleaning..." -ForegroundColor Yellow
        
        $connections = Get-NetTCPConnection -LocalPort $FrontendPort -ErrorAction SilentlyContinue
        foreach ($conn in $connections) {
            try {
                $proc = Get-Process -Id $conn.OwningProcess -ErrorAction SilentlyContinue
                if ($proc) {
                    Stop-Process -Id $conn.OwningProcess -Force -ErrorAction SilentlyContinue
                    Write-Host "[Cleanup] Force terminated process: $($conn.OwningProcess) ($($proc.ProcessName))" -ForegroundColor Yellow
                    $killedCount++
                }
            } catch { }
        }
        
        $flutterProcs = Get-Process -Name flutter, dart -ErrorAction SilentlyContinue
        foreach ($f in $flutterProcs) {
            try {
                Stop-Process -Id $f.Id -Force -ErrorAction SilentlyContinue
                Write-Host "[Cleanup] Terminated flutter/dart process: $($f.Id)" -ForegroundColor Yellow
                $killedCount++
            } catch { }
        }
    }
    
    Start-Sleep -Seconds 1
    
    $finalCheck = Get-FrontendStatus
    if ($finalCheck.Running) {
        Write-Host "[Error] Failed to stop frontend service completely" -ForegroundColor Red
    } else {
        Write-Host "[Done] Stopped $killedCount frontend process(es)" -ForegroundColor Green
    }
}

function Start-All {
    Write-Host "`nStarting all services..." -ForegroundColor Cyan
    Start-Backend
    Start-Frontend
    Write-Host "`n[Done] All service start commands executed" -ForegroundColor Green
}

function Stop-All {
    Write-Host "`nStopping all services..." -ForegroundColor Cyan
    Stop-Backend
    Stop-Frontend
    Write-Host "[Done] All services stopped" -ForegroundColor Green
}

function Test-BackendAPI {
    Write-Host "`nTesting API connection..." -ForegroundColor Cyan
    Write-Host "============================================================"
    
    $status = Get-BackendStatus
    if (-not $status.Running) {
        Write-Host "[Error] Backend service is not running" -ForegroundColor Red
        return
    }
    
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:$BackendPort/docs" -Method Get -TimeoutSec 5 -UseBasicParsing
        Write-Host "[Success] API connection OK (Status: $($response.StatusCode))" -ForegroundColor Green
        Write-Host "`nAvailable endpoints:"
        Write-Host "  - API Docs: " -NoNewline
        Write-Host "http://localhost:$BackendPort/docs" -ForegroundColor Blue
        Write-Host "  - Register: POST " -NoNewline
        Write-Host "http://localhost:$BackendPort/api/v1/auth/register" -ForegroundColor Blue
        Write-Host "  - Login: POST " -NoNewline
        Write-Host "http://localhost:$BackendPort/api/v1/auth/login" -ForegroundColor Blue
        Write-Host "  - AI Analysis: POST " -NoNewline
        Write-Host "http://localhost:$BackendPort/api/v1/ai/analyze" -ForegroundColor Blue
    } catch {
        Write-Host "[Failed] API connection error: $_" -ForegroundColor Red
    }
}

function Open-App {
    $frontendStatus = Get-FrontendStatus
    $backendStatus = Get-BackendStatus
    
    if (-not $frontendStatus.Running -and -not $backendStatus.Running) {
        Write-Host "[Error] Both frontend and backend services are not running" -ForegroundColor Red
        Write-Host "[Info] Please start services first (Option 1 or 3/5)" -ForegroundColor Yellow
        return
    }
    
    if ($frontendStatus.Running) {
        Start-Process "http://localhost:$FrontendPort"
        Write-Host "[Success] Frontend app opened in browser" -ForegroundColor Green
    } elseif ($backendStatus.Running) {
        Start-Process "http://localhost:$BackendPort/docs"
        Write-Host "[Success] API docs opened in browser" -ForegroundColor Green
    }
}

while ($true) {
    Show-Status
    
    Write-Host " Options:" -ForegroundColor White
    Write-Host "   1. " -NoNewline; Write-Host "Start" -ForegroundColor Green -NoNewline; Write-Host " all services (Backend + Frontend)"
    Write-Host "   2. " -NoNewline; Write-Host "Stop" -ForegroundColor Red -NoNewline; Write-Host " all services"
    Write-Host "   3. " -NoNewline; Write-Host "Start" -ForegroundColor Green -NoNewline; Write-Host " backend only"
    Write-Host "   4. " -NoNewline; Write-Host "Stop" -ForegroundColor Red -NoNewline; Write-Host " backend only"
    Write-Host "   5. " -NoNewline; Write-Host "Start" -ForegroundColor Green -NoNewline; Write-Host " frontend only"
    Write-Host "   6. " -NoNewline; Write-Host "Stop" -ForegroundColor Red -NoNewline; Write-Host " frontend only"
    Write-Host "   7. Test API connection"
    Write-Host "   8. Open app/docs in browser"
    Write-Host "   0. Exit"
    Write-Host "============================================================" -ForegroundColor Cyan
    
    $choice = Read-Host "`nSelect option (0-8)"
    
    switch ($choice) {
        "1" { Start-All }
        "2" { Stop-All }
        "3" { Start-Backend }
        "4" { Stop-Backend }
        "5" { Start-Frontend }
        "6" { Stop-Frontend }
        "7" { Test-BackendAPI }
        "8" { Open-App }
        "0" { 
            Write-Host "`nGoodbye!" -ForegroundColor Green
            Start-Sleep -Seconds 1
            exit 0 
        }
        default { 
            Write-Host "[Error] Invalid option, please try again" -ForegroundColor Red
            Start-Sleep -Seconds 1
        }
    }
    
    Write-Host "`nPress any key to continue..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}
