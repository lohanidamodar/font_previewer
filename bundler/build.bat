@echo off
echo Building Flutter Bundler...

:: Create build directory
if not exist "build" mkdir build
cd build

:: Configure CMake
cmake .. -G "Visual Studio 17 2022" -A x64
if %ERRORLEVEL% neq 0 (
    echo CMake configuration failed.
    exit /b %ERRORLEVEL%
)

:: Build the project
cmake --build . --config Release
if %ERRORLEVEL% neq 0 (
    echo Build failed.
    exit /b %ERRORLEVEL%
)

echo Build completed successfully.
echo The bundled executable is located at: %CD%\bin\Release\FontPreviewer.exe

cd ..
