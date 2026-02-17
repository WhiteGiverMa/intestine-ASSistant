@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

set BACKEND_PORT=8001
set FRONTEND_PORT=5174
set PYTHON_PATH=.venv\Scripts\python.exe
set BACKEND_DIR=backend
set FRONTEND_DIR=mobile_app

:menu
cls
echo ============================================================
echo            Intestine ASSistant - Service Manager
echo ============================================================
echo.

echo  [Backend Service] Port: %BACKEND_PORT%
set BACKEND_COUNT=0
set BACKEND_RUNNING=0
for /f "tokens=5" %%a in ('netstat -ano ^| findstr ":%BACKEND_PORT% " ^| findstr "LISTENING" 2^>nul') do (
    set /a BACKEND_COUNT+=1
    for /f "tokens=1" %%b in ('tasklist /FI "PID eq %%a" /NH 2^>nul ^| findstr /V "INFO:"') do (
        if not "%%b"=="" (
            echo    - PID: %%a (%%b)
            set /a BACKEND_RUNNING+=1
        )
    )
)
if %BACKEND_RUNNING% gtr 0 (
    echo    Status: [Running]
    echo    API Docs: http://localhost:%BACKEND_PORT%/docs
) else (
    curl -s -o nul -w "%%{http_code}" http://localhost:%BACKEND_PORT%/docs 2>nul | findstr "200" >nul
    if !errorlevel! equ 0 (
        echo    - PID: Unknown (parent exited^)
        echo    Status: [Running]
        echo    API Docs: http://localhost:%BACKEND_PORT%/docs
    ) else (
        echo    Status: [Stopped]
    )
)

echo.
echo  [Frontend Service] Port: %FRONTEND_PORT%
set FRONTEND_COUNT=0
set FRONTEND_RUNNING=0
for /f "tokens=5" %%a in ('netstat -ano ^| findstr ":%FRONTEND_PORT% " ^| findstr "LISTENING" 2^>nul') do (
    set /a FRONTEND_COUNT+=1
    for /f "tokens=1" %%b in ('tasklist /FI "PID eq %%a" /NH 2^>nul ^| findstr /V "INFO:"') do (
        if not "%%b"=="" (
            echo    - PID: %%a (%%b)
            set /a FRONTEND_RUNNING+=1
        )
    )
)
if %FRONTEND_RUNNING% gtr 0 (
    echo    Status: [Running]
    echo    URL: http://localhost:%FRONTEND_PORT%
) else (
    curl -s -o nul -w "%%{http_code}" http://localhost:%FRONTEND_PORT% 2>nul | findstr "200" >nul
    if !errorlevel! equ 0 (
        echo    - PID: Unknown (parent exited^)
        echo    Status: [Running]
        echo    URL: http://localhost:%FRONTEND_PORT%
    ) else (
        echo    Status: [Stopped]
    )
)

echo.
echo ============================================================
echo  Options:
<nul set /p="   1. "
<nul set /p="[92mStart[0m"
echo  all services (Backend + Frontend)
<nul set /p="   2. "
<nul set /p="[91mStop[0m"
echo  all services
<nul set /p="   3. "
<nul set /p="[92mStart[0m"
echo  backend only
<nul set /p="   4. "
<nul set /p="[91mStop[0m"
echo  backend only
<nul set /p="   5. "
<nul set /p="[92mStart[0m"
echo  frontend only
<nul set /p="   6. "
<nul set /p="[91mStop[0m"
echo  frontend only
echo    7. Test API connection
echo    8. Open app/docs in browser
echo    0. Exit
echo ============================================================
echo.

set /p choice="Select option (0-8): "

if "%choice%"=="1" goto start_all
if "%choice%"=="2" goto stop_all
if "%choice%"=="3" goto start_backend
if "%choice%"=="4" goto stop_backend
if "%choice%"=="5" goto start_frontend
if "%choice%"=="6" goto stop_frontend
if "%choice%"=="7" goto test
if "%choice%"=="8" goto open_app
if "%choice%"=="0" goto end
goto menu

:start_all
echo.
echo Starting all services...
call :start_backend_silent
call :start_frontend_silent
echo [Done] All service start commands executed
timeout /t 3 >nul
goto menu

:stop_all
echo.
echo Stopping all services...
call :stop_backend_silent
call :stop_frontend_silent
echo [Done] All services stopped
timeout /t 2 >nul
goto menu

:start_backend
echo.
echo Starting backend service...
call :check_backend_running
if !BACKEND_IS_RUNNING! equ 1 (
    echo [Warning] Backend service is already running
    pause
    goto menu
)
start "Intestine ASSistant Backend" cmd /c "cd %BACKEND_DIR% & ..\%PYTHON_PATH% -m uvicorn app.main:app --reload --host 0.0.0.0 --port %BACKEND_PORT%"
echo [Success] Backend service started
timeout /t 3 >nul
goto menu

:start_backend_silent
call :check_backend_running
if !BACKEND_IS_RUNNING! equ 1 goto :eof
start "Intestine ASSistant Backend" cmd /c "cd %BACKEND_DIR% & ..\%PYTHON_PATH% -m uvicorn app.main:app --reload --host 0.0.0.0 --port %BACKEND_PORT%"
echo [Success] Backend service started
timeout /t 2 >nul
goto :eof

:check_backend_running
set BACKEND_IS_RUNNING=0
for /f "tokens=5" %%a in ('netstat -ano ^| findstr ":%BACKEND_PORT% " ^| findstr "LISTENING" 2^>nul') do (
    for /f "tokens=1" %%b in ('tasklist /FI "PID eq %%a" /NH 2^>nul ^| findstr /V "INFO:"') do (
        if not "%%b"=="" set BACKEND_IS_RUNNING=1
    )
)
if !BACKEND_IS_RUNNING! equ 0 (
    curl -s -o nul -w "%%{http_code}" http://localhost:%BACKEND_PORT%/docs 2>nul | findstr "200" >nul
    if !errorlevel! equ 0 set BACKEND_IS_RUNNING=1
)
goto :eof

:stop_backend
echo.
echo Stopping backend service...
call :stop_backend_silent
echo [Done] Backend service stopped
timeout /t 2 >nul
goto menu

:stop_backend_silent
set KILL_COUNT=0
for /f "tokens=5" %%a in ('netstat -ano ^| findstr ":%BACKEND_PORT% " ^| findstr "LISTENING" 2^>nul') do (
    taskkill /F /T /PID %%a >nul 2>&1
    echo [Success] Terminated process tree: %%a
    set /a KILL_COUNT+=1
)
timeout /t 2 >nul 2>&1
for /f "tokens=5" %%a in ('netstat -ano ^| findstr ":%BACKEND_PORT% " ^| findstr "LISTENING" 2^>nul') do (
    taskkill /F /PID %%a >nul 2>&1
    echo [Cleanup] Force terminated remaining process: %%a
    set /a KILL_COUNT+=1
)
for /f "tokens=2" %%a in ('tasklist /FI "IMAGENAME eq python.exe" /NH 2^>nul ^| findstr "python.exe"') do (
    for /f "tokens=*" %%c in ('wmic process where "ProcessId=%%a" get CommandLine 2^>nul ^| findstr /I "uvicorn"') do (
        taskkill /F /PID %%a >nul 2>&1
        echo [Cleanup] Terminated uvicorn python process: %%a
        set /a KILL_COUNT+=1
    )
)
if %KILL_COUNT% equ 0 (
    echo [Info] Backend service is not running
)
goto :eof

:start_frontend
echo.
echo Starting frontend service...
call :check_frontend_running
if !FRONTEND_IS_RUNNING! equ 1 (
    echo [Warning] Frontend service is already running
    pause
    goto menu
)
start "Intestine ASSistant Frontend" cmd /c "cd %FRONTEND_DIR% & flutter run -d chrome --web-port=%FRONTEND_PORT%"
echo [Success] Frontend service start command executed
echo [Info] Flutter Web takes time to start, please wait...
timeout /t 5 >nul
goto menu

:start_frontend_silent
call :check_frontend_running
if !FRONTEND_IS_RUNNING! equ 1 goto :eof
start "Intestine ASSistant Frontend" cmd /c "cd %FRONTEND_DIR% & flutter run -d chrome --web-port=%FRONTEND_PORT%"
echo [Success] Frontend service start command executed
timeout /t 2 >nul
goto :eof

:check_frontend_running
set FRONTEND_IS_RUNNING=0
for /f "tokens=5" %%a in ('netstat -ano ^| findstr ":%FRONTEND_PORT% " ^| findstr "LISTENING" 2^>nul') do (
    for /f "tokens=1" %%b in ('tasklist /FI "PID eq %%a" /NH 2^>nul ^| findstr /V "INFO:"') do (
        if not "%%b"=="" set FRONTEND_IS_RUNNING=1
    )
)
if !FRONTEND_IS_RUNNING! equ 0 (
    curl -s -o nul -w "%%{http_code}" http://localhost:%FRONTEND_PORT% 2>nul | findstr "200" >nul
    if !errorlevel! equ 0 set FRONTEND_IS_RUNNING=1
)
goto :eof

:stop_frontend
echo.
echo Stopping frontend service...
call :stop_frontend_silent
echo [Done] Frontend service stopped
timeout /t 2 >nul
goto menu

:stop_frontend_silent
set KILL_COUNT=0
for /f "tokens=5" %%a in ('netstat -ano ^| findstr ":%FRONTEND_PORT% " ^| findstr "LISTENING" 2^>nul') do (
    taskkill /F /PID %%a >nul 2>&1
    echo [Success] Terminated process: %%a
    set /a KILL_COUNT+=1
)
timeout /t 2 >nul 2>&1
for /f "tokens=5" %%a in ('netstat -ano ^| findstr ":%FRONTEND_PORT% " ^| findstr "LISTENING" 2^>nul') do (
    taskkill /F /PID %%a >nul 2>&1
    echo [Cleanup] Force terminated remaining process: %%a
    set /a KILL_COUNT+=1
)
for /f "tokens=2" %%a in ('tasklist /FI "IMAGENAME eq flutter.bat" /NH 2^>nul ^| findstr "flutter"') do (
    taskkill /F /PID %%a >nul 2>&1
    echo [Cleanup] Terminated flutter process: %%a
    set /a KILL_COUNT+=1
)
for /f "tokens=2" %%a in ('tasklist /FI "IMAGENAME eq dart.exe" /NH 2^>nul ^| findstr "dart"') do (
    taskkill /F /PID %%a >nul 2>&1
    echo [Cleanup] Terminated dart process: %%a
    set /a KILL_COUNT+=1
)
if %KILL_COUNT% equ 0 (
    echo [Info] Frontend service is not running
)
goto :eof

:test
echo.
echo Testing API connection...
echo ============================================================
call :check_backend_running
if !BACKEND_IS_RUNNING! equ 0 (
    echo [Error] Backend service is not running
    pause
    goto menu
)

echo Testing health endpoint...
curl -s -o nul -w "HTTP Status: %%{http_code}\n" http://localhost:%BACKEND_PORT%/docs 2>nul
if %errorlevel% equ 0 (
    echo [Success] API connection OK
    echo.
    echo Available endpoints:
    echo   - API Docs: http://localhost:%BACKEND_PORT%/docs
    echo   - Register: POST http://localhost:%BACKEND_PORT%/api/v1/auth/register
    echo   - Login: POST http://localhost:%BACKEND_PORT%/api/v1/auth/login
) else (
    echo [Failed] API connection error
)
pause
goto menu

:open_app
echo.
call :check_frontend_running
if !FRONTEND_IS_RUNNING! equ 1 (
    start http://localhost:%FRONTEND_PORT%
    echo [Success] Frontend app opened in browser
    pause
    goto menu
)
call :check_backend_running
if !BACKEND_IS_RUNNING! equ 1 (
    start http://localhost:%BACKEND_PORT%/docs
    echo [Success] API docs opened in browser
    pause
    goto menu
)
echo [Error] Both frontend and backend services are not running
echo [Info] Please start services first (Option 1 or 3/5)
pause
goto menu

:end
echo.
echo Goodbye!
timeout /t 1 >nul
exit /b 0
