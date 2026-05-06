: << 'END_OF_BATCH'
@echo off
setlocal enabledelayedexpansion

:: ==============================================================================
:: WINDOWS BATCH SCRIPT
:: ==============================================================================

:: Setup ANSI Colors
for /F "tokens=1,2 delims=#" %%a in ('"prompt #$H#$E# & echo on & for %%b in (1) do rem"') do set "ESC=%%b"
set "c_cyan=%ESC%[36m" & set "c_yellow=%ESC%[33m" & set "c_green=%ESC%[32m"
set "c_red=%ESC%[31m" & set "c_dim=%ESC%[90m" & set "c_reset=%ESC%[0m"

cls
echo %c_cyan%=======================================================%c_reset%
echo %c_cyan%            Florence (Windows Environment)          %c_reset%
echo %c_cyan%=======================================================%c_reset%
echo.

:: Resolve ADB Path
set "ADB_EXE=%LOCALAPPDATA%\Android\Sdk\platform-tools\adb.exe"
if not exist "!ADB_EXE!" for /f "delims=" %%i in ('where adb 2^>nul') do set "ADB_EXE=%%i"

if not exist "!ADB_EXE!" (
    echo %c_red%  [X] ERROR: adb.exe not found! Please install Android SDK.%c_reset%
    pause & exit /b 1
)

:WIN_CHECK_CONNECTION
set "WIRELESS_IP=" & set "USB_FOUND=0"

:: [FIXED]: Switched to backticks and usebackq to avoid quote-stripping parser crashes
for /f "usebackq tokens=1" %%i in (`"!ADB_EXE!" devices 2^>nul ^| findstr /r /c:"^[0-9].*:5555.*device"`) do set "WIRELESS_IP=%%i"
for /f "usebackq tokens=1" %%i in (`"!ADB_EXE!" devices 2^>nul ^| findstr /v "List" ^| findstr "device" ^| findstr /v ":5555"`) do set "USB_FOUND=1"

if defined WIRELESS_IP (
    echo %c_green%  [^v] Connected wirelessly to !WIRELESS_IP!%c_reset%
    goto WIN_LAUNCH
)

:: [FIXED]: Escaped parentheses with ^ to prevent early block closure
if "!USB_FOUND!"=="1" ( echo %c_yellow%  [!] USB device detected, but wireless is NOT active.%c_reset%
) else ( echo %c_red%  [!] No devices detected ^(USB or wireless^).%c_reset% )

echo.
echo   [1] %c_green%Quick reconnect%c_reset% (Connect via IP - no USB needed)
echo   [2] %c_yellow%Setup TCP mode%c_reset%  (Requires USB, needed after phone restart)
echo   [3] %c_dim%Skip%c_reset%            (Launch Flutter anyway)
echo.
set /p mode=" > Select option (1-3): "

if "!mode!"=="1" (
    set /p ip=" > Enter phone IP address: "
    "!ADB_EXE!" connect !ip!:5555 & timeout /t 2 >nul & goto WIN_CHECK_CONNECTION
)
if "!mode!"=="2" (
    "!ADB_EXE!" tcpip 5555
    echo %c_dim%  [*] TCP mode enabled. You may disconnect USB.%c_reset%
    set /p ip=" > Enter phone IP address: "
    "!ADB_EXE!" connect !ip!:5555 & timeout /t 2 >nul & goto WIN_CHECK_CONNECTION
)

:WIN_LAUNCH
echo.
echo %c_cyan%-------------------------------------------------------%c_reset%
echo.
cd /d "%~dp0"
if exist "florence\platform_service" ( cd "florence\platform_service"
) else ( echo %c_red%  [X] Error: platform_service folder not found.%c_reset% & pause & exit /b 1 )

echo %c_dim%  [*] Resolving Flutter dependencies...%c_reset%
echo.
call flutter pub get

echo.
echo %c_green%  [*] Launching Florence...%c_reset%
echo.
if defined WIRELESS_IP ( call flutter run -d !WIRELESS_IP! ) else ( call flutter run )
pause
exit /b
END_OF_BATCH



#!/bin/bash
# ==============================================================================
# LINUX BASH SCRIPT (With Git Bash Fallback)
# ==============================================================================

# Setup ANSI Colors
C_CYAN='\033[0;36m' ; C_YELLOW='\033[0;33m' ; C_GREEN='\033[0;32m'
C_RED='\033[0;31m' ; C_DIM='\033[0;90m' ; C_RESET='\033[0m'

clear
echo -e "${C_CYAN}=======================================================${C_RESET}"
echo -e "${C_CYAN}              Florence (Linux/Bash Environment)        ${C_RESET}"
echo -e "${C_CYAN}=======================================================${C_RESET}"
echo

# Resolve ADB Path
ADB_EXE=$(command -v adb)

if [ -z "$ADB_EXE" ]; then
    if [[ "$OSTYPE" == "msys"* || "$OSTYPE" == "cygwin"* ]]; then
        # Running inside Git Bash on Windows
        ADB_EXE="$LOCALAPPDATA/Android/Sdk/platform-tools/adb.exe"
    elif [ -f "$HOME/Android/Sdk/platform-tools/adb" ]; then
        # Standard Linux environment
        ADB_EXE="$HOME/Android/Sdk/platform-tools/adb"
    fi
fi

if [ -z "$ADB_EXE" ] || [ ! -f "$ADB_EXE" ]; then
    echo -e "${C_RED}  [X] ERROR: adb not found! Please install Android SDK.${C_RESET}"
    exit 1
fi

check_connection() {
    WIRELESS_IP=$("$ADB_EXE" devices | grep -E "^[0-9].*:5555" | awk '{print $1}' | head -n 1)
    USB_FOUND=0
    if "$ADB_EXE" devices | grep -v "List" | grep "device" | grep -v ":5555" > /dev/null; then USB_FOUND=1; fi

    if [ -n "$WIRELESS_IP" ]; then
        echo -e "${C_GREEN}  [^v] Connected wirelessly to $WIRELESS_IP${C_RESET}"
        launch_flutter
    fi

    if [ "$USB_FOUND" -eq 1 ]; then echo -e "${C_YELLOW}  [!] USB device detected, but wireless is NOT active.${C_RESET}"
    else echo -e "${C_RED}  [!] No devices detected (USB or wireless).${C_RESET}"; fi

    echo
    echo -e "  [1] ${C_GREEN}Quick reconnect${C_RESET} (Connect via IP - no USB needed)"
    echo -e "  [2] ${C_YELLOW}Setup TCP mode${C_RESET}  (Requires USB, needed after phone restart)"
    echo -e "  [3] ${C_DIM}Skip${C_RESET}            (Launch Flutter anyway)"
    echo
    read -p " > Select option (1-3): " mode

    case $mode in
        1)
            read -p " > Enter phone IP address: " ip
            "$ADB_EXE" connect "$ip:5555" ; sleep 2 ; check_connection ;;
        2)
            "$ADB_EXE" tcpip 5555
            echo -e "${C_DIM}  [*] TCP mode enabled. You may disconnect USB.${C_RESET}"
            read -p " > Enter phone IP address: " ip
            "$ADB_EXE" connect "$ip:5555" ; sleep 2 ; check_connection ;;
        *)
            launch_flutter ;;
    esac
}

launch_flutter() {
    echo
    echo -e "${C_CYAN}-------------------------------------------------------${C_RESET}"
    echo
    cd "$(dirname "${BASH_SOURCE[0]}")" || exit
    
    if [ -d "florence/platform_service" ]; then cd "florence/platform_service"
    else echo -e "${C_RED}  [X] Error: platform_service folder not found.${C_RESET}" ; exit 1 ; fi

    echo -e "${C_DIM}  [*] Resolving Flutter dependencies...${C_RESET}"
    echo
    flutter pub get

    echo
    echo -e "${C_GREEN}  [*] Launching Florence...${C_RESET}"
    echo
    if [ -n "$WIRELESS_IP" ]; then flutter run -d "$WIRELESS_IP"
    else flutter run ; fi
    exit 0
}

check_connection
