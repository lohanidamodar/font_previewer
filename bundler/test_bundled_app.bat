@echo off
echo Testing the bundled application...

:: Check if the bundled exe exists in either possible location
if exist "bin\x64\Release\FontPreviewer.exe" (
    set BUNDLED_EXE=bin\x64\Release\FontPreviewer.exe
) else if exist "bin\Release\FontPreviewer.exe" (
    set BUNDLED_EXE=bin\Release\FontPreviewer.exe
) else if exist "build\bin\Release\FontPreviewer.exe" (
    set BUNDLED_EXE=build\bin\Release\FontPreviewer.exe
) else (
    echo ERROR: Bundled executable not found.
    echo Please build the project first using Visual Studio or CMake.
    echo.
    echo Make sure you've built the Flutter app with:
    echo   flutter build windows --release
    echo.
    echo Then build the bundler with:
    echo   build_manual.bat
    pause
    exit /b 1
)

echo Found bundled application: %BUNDLED_EXE%
echo.
echo Starting the bundled application...
echo (If successful, the Flutter application should launch)
echo.
echo Press any key to run the application...
pause >nul

echo.
echo Running bundled app: %BUNDLED_EXE%
start "" "%BUNDLED_EXE%"

echo.
echo The application has been launched.
echo If you don't see the app window, check the task manager
echo to see if the process is running.
echo.
echo If there are issues:
echo 1. Make sure you've built the Flutter app in release mode
echo 2. Check the paths in resources.rc match your project structure
echo 3. Try rebuilding with Visual Studio directly
echo.
echo Press any key to exit...
pause >nul
