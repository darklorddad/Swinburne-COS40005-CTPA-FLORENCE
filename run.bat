@echo off
setlocal enabledelayedexpansion

:: Define the ESC character to enable ANSI colors in the terminal
for /F %%a in ('echo prompt $E ^| cmd') do set "ESC=%%a"

:: Define Color Palette
set "c_cyan=%ESC%[36m"
set "c_yellow=%ESC%[33m"
set "c_green=%ESC%[32m"
set "c_dim=%ESC%[90m"
set "c_reset=%ESC%[0m"

cls
echo %c_cyan%=======================================================%c_reset%
echo %c_cyan%                      Florence                         %c_reset%
echo %c_cyan%=======================================================%c_reset%
echo.
echo %c_yellow%  [^^!] NOTE: If connecting wirelessly for the first time%c_reset%
echo %c_yellow%      or after a phone reboot, you MUST connect via USB%c_reset%
echo %c_yellow%      first to enable TCP mode.%c_reset%
echo.
echo %c_cyan%-------------------------------------------------------%c_reset%
echo.

set ADB_PATH=%LOCALAPPDATA%\Android\Sdk\platform-tools\adb.exe

:: Check for existing wireless connection
set "WIRELESS_CONNECTED=0"
set "DEVICE_IP="
for /f "tokens=1" %%i in ('"%ADB_PATH%" devices ^| findstr /r /c:"^[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*:5555.*device"') do (
    set "WIRELESS_CONNECTED=1"
    set "DEVICE_IP=%%i"
)

if "!WIRELESS_CONNECTED!"=="1" (
    echo %c_green%  [^v] Already connected wirelessly to !DEVICE_IP!%c_reset%
    echo.
    echo %c_cyan%-------------------------------------------------------%c_reset%
) else (
    set /p choice=" > Connect wirelessly? (y/n): "

    if /i "!choice!"=="y" (
        echo.
        echo %c_dim%  [-] Ensure phone and PC are on the same Wi-Fi network.%c_reset%
        set /p ip=" > Enter phone IP address: "
        
        echo.
        echo %c_dim%  [*] Restarting ADB in TCP mode ^(Port 5555^)...%c_reset%
        "%ADB_PATH%" tcpip 5555
        timeout /t 2 >nul
        
        echo.
        echo %c_dim%  [*] Connecting to !ip!...%c_reset%
        "%ADB_PATH%" connect !ip!:5555
        
        :: Buffer for ADB to register
        timeout /t 3 >nul 
        echo.
        echo %c_green%  [^v] Ready^^! You may now disconnect the USB cable.%c_reset%
        echo.
        echo %c_cyan%-------------------------------------------------------%c_reset%
        
        set "DEVICE_IP=!ip!:5555"
    )
)

:: Navigate to service directory safely
cd /d "%~dp0florence\platform_service"

echo.
echo %c_dim%  [*] Resolving Flutter dependencies...%c_reset%
call flutter pub get

echo.
echo %c_green%  [*] Launching Florence...%c_reset%
if defined DEVICE_IP (
    call flutter run -d !DEVICE_IP!
) else (
    call flutter run
)

pause
