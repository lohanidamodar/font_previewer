@echo off
REM Quick build script for Flutter Bundler that handles both resource generation and building

echo ===== Flutter Bundler Build Script =====

REM Default values
set FLUTTER_RELEASE_PATH=..\build\windows\x64\runner\Release
set FLUTTER_PROJECT_PATH=..

REM Check arguments
if not "%~1"=="" set FLUTTER_RELEASE_PATH=%~1
if not "%~2"=="" set FLUTTER_PROJECT_PATH=%~2

REM Step 1: Generate resources
echo.
echo === Generating Resources ===
echo.
powershell -ExecutionPolicy Bypass -File generate_resources.ps1 -ReleasePath "%FLUTTER_RELEASE_PATH%" -FlutterProjectPath "%FLUTTER_PROJECT_PATH%"
if %ERRORLEVEL% neq 0 (
    echo Error: Failed to generate resources.
    exit /b 1
)

REM Step 2: Build the bundler
echo.
echo === Building Bundler ===
echo.
call build.bat
if %ERRORLEVEL% neq 0 (
    echo Error: Build failed.
    exit /b 1
)

echo.
echo Build completed successfully!
echo The bundled executable is at: build\bin\Release\FontPreviewer.exe
echo.
echo To test the bundled application, run: test_bundled_app.bat

exit /b 0
