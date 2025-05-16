@echo off
echo Building and bundling Font Previewer...

:: Step 1: Build Flutter app in release mode
echo Building Flutter app in release mode...
cd ..\..
flutter build windows --release
if %ERRORLEVEL% neq 0 (
    echo Failed to build Flutter app in release mode.
    pause
    exit /b %ERRORLEVEL%
)
echo Flutter app built successfully.

:: Step 2: Build the bundler with Visual Studio
echo Building bundler...
cd src\bundler

:: Check if Visual Studio is installed and in PATH
where /q devenv
if %ERRORLEVEL% neq 0 (
    echo Visual Studio not found in PATH.
    echo Please build the bundler manually by opening FlutterBundler.sln in Visual Studio.
    pause
    exit /b 1
)

:: Build with Visual Studio
devenv FlutterBundler.sln /Build "Release|x64"
if %ERRORLEVEL% neq 0 (
    echo Failed to build bundler.
    echo Please build the bundler manually by opening FlutterBundler.sln in Visual Studio.
    pause
    exit /b %ERRORLEVEL%
)

:: Check if the build was successful
if exist "bin\x64\Release\FontPreviewer.exe" (
    echo Bundler built successfully.
    echo The bundled app is available at: bin\x64\Release\FontPreviewer.exe
) else (
    echo The bundler build completed but the output executable was not found.
    echo Please check the build logs for errors.
)

pause
