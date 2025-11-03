@echo off
echo ========================================
echo BioTective Digital Health Platform
echo Component Runner Script
echo ========================================
echo.

:menu
echo Select component to run:
echo 1. AI Integration Backend (Simple Server)
echo 2. AI Integration Backend (Full Backend)
echo 3. Test AI Backend
echo 4. Biotective Flutter App (Basic)
echo 5. Biotective Health App (Advanced)
echo 6. Exit
echo.
set /p choice="Enter your choice (1-6): "

if "%choice%"=="1" goto ai_simple
if "%choice%"=="2" goto ai_full
if "%choice%"=="3" goto test_ai
if "%choice%"=="4" goto flutter_basic
if "%choice%"=="5" goto flutter_health
if "%choice%"=="6" goto exit
goto menu

:ai_simple
echo.
echo Starting AI Integration Backend (Simple Server)...
cd ai_integration
python simple_server.py
goto menu

:ai_full
echo.
echo Starting AI Integration Backend (Full Backend)...
cd ai_integration
python ai_backend/main.py
goto menu

:test_ai
echo.
echo Testing AI Backend...
cd ai_integration
python test_simple.py
pause
goto menu

:flutter_basic
echo.
echo Starting Biotective Flutter App (Basic)...
cd biotective
flutter pub get
flutter run
goto menu

:flutter_health
echo.
echo Starting Biotective Health App (Advanced)...
cd biotective_health_app
flutter pub get
flutter packages pub run build_runner build
flutter run
goto menu

:exit
echo.
echo Goodbye!
pause
exit
