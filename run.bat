@echo off
setlocal enabledelayedexpansion

:: Define the ESC character for ANSI colors
for /F "tokens=1,2 delims=#" %%a in ('"prompt #$H#$E# & echo on & for %%b in (1) do rem"') do set "ESC=%%b"

:: Color palette
set "c_cyan=%ESC%[36m"
set "c_yellow=%ESC%[33m"
set "c_green=%ESC%[32m"
set "c_red=%ESC%[31m"
set "c_dim=%ESC%[90m"
set "c_reset=%ESC%[0m"

cls
echo %c_cyan%=======================================================%c_reset%
echo %c_cyan%                     Florence                        %c_reset%
echo %c_cyan%=======================================================%c_reset%
echo.

:: --- UNIVERSAL ADB PATH RESOLUTION ---

:: Check the standard Android Studio location using %LOCALAPPDATA%
set "ADB_EXE=%LOCALAPPDATA%\Android\Sdk\platform-tools\adb.exe"

:: If not found, check if it's already in the system PATH
if not exist "!ADB_EXE!" (
    for /f "delims=" %%i in ('where adb 2^>nul') do set "ADB_EXE=%%i"
)

:: If STILL not found, check common "Program Files" locations
if not exist "!ADB_EXE!" (
    if exist "C:\Program Files (x86)\Android\android-sdk\platform-tools\adb.exe" (
        set "ADB_EXE=C:\Program Files (x86)\Android\android-sdk\platform-tools\adb.exe"
    )
)

:: Final error check
if not exist "!ADB_EXE!" (
    echo %c_red%  [X] ERROR: adb.exe not found on this system!%c_reset%
    echo      Please install Android SDK or add platform-tools to your PATH.
    pause
    exit /b
)

:CHECK_CONNECTION
set "WIRELESS_IP="
set "USB_FOUND=0"

:: Check for wireless (IP: 5555)
for /f "tokens=1" %%i in ('""!ADB_EXE!" devices 2^>nul ^| findstr /r /c:"^[0-9].*:5555.*device""') do (
    set "WIRELESS_IP=%%i"
)

:: Check for USB (any device that isn't an IP and isn't the header)
for /f "tokens=1" %%i in ('""!ADB_EXE!" devices 2^>nul ^| findstr /v "List" ^| findstr "device" ^| findstr /v ":5555""') do (
    set "USB_FOUND=1"
)

:: --- SCENARIO HANDLING ---

if defined WIRELESS_IP (
    echo %c_green%  [^v] Status: Connected wirelessly to !WIRELESS_IP!%c_reset%
    goto LAUNCH_FLUTTER
)

if "!USB_FOUND!"=="1" (
    echo %c_yellow%  [!] Status: USB device detected, but wireless is NOT active.%c_reset%
) else (
    echo %c_red%  [!] Status: No devices detected (USB or wireless).%c_reset%
)

echo.
echo   [1] %c_green%Quick reconnect%c_reset% (Connect via IP - no USB needed)
echo   [2] %c_yellow%Setup%c_reset%     (Enable TCP mode - requires USB, required after phone restart)
echo   [3] %c_dim%Skip%c_reset%            (Launch Flutter anyway)
echo.
set /p mode=" > Select option (1-3): "

if "!mode!"=="1" (
    echo.
    set /p ip=" > Enter phone IP address: "
    echo %c_dim%  [*] Attempting wireless handshake...%c_reset%
    "!ADB_EXE!" connect !ip!:5555
    timeout /t 2 >nul
    goto CHECK_CONNECTION
)

if "!mode!"=="2" (
    echo.
    echo %c_dim%  [*] Restarting ADB daemon in TCP mode...%c_reset%
    "!ADB_EXE!" tcpip 5555
    echo %c_dim%  [*] Setup command sent. You may now disconnect USB.%c_reset%
    set /p ip=" > Enter phone IP address: "
    "!ADB_EXE!" connect !ip!:5555
    timeout /t 2 >nul
    goto CHECK_CONNECTION
)

:LAUNCH_FLUTTER
echo.
echo %c_cyan%-------------------------------------------------------%c_reset%

:: Move to the service directory
cd /d "%~dp0"
if exist "florence\platform_service" (
    cd "florence\platform_service"
) else (
    echo %c_red%  [X] Error: Could not find florence\platform_service folder.%c_reset%
    pause
    exit /b
)

echo.
echo %c_dim%  [*] Resolving Flutter dependencies...%c_reset%
call flutter pub get

echo.
echo %c_green%  [*] Launching Florence...%c_reset%
if defined WIRELESS_IP (
    echo %c_dim%  [*] Targeting wireless device: !WIRELESS_IP!%c_reset%
    call flutter run -d !WIRELESS_IP!
) else (
    call flutter run
)

pause