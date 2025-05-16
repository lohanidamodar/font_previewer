@echo off
echo Building Font Previewer Bundler...
setlocal enabledelayedexpansion

:: Flutter build instructions
echo Step 1: Make sure you've built the Flutter app in release mode using:
echo   flutter build windows --release

:: Visual Studio detection
echo Step 2: Detecting Visual Studio installation...

:: Set default paths to check for different VS versions
set "VS2022PATH=C:\Program Files\Microsoft Visual Studio\2022\Community"
set "VS2019PATH=C:\Program Files (x86)\Microsoft Visual Studio\2019\Community"

:: Check for VS Professional/Enterprise editions if Community not found
if not exist "!VS2022PATH!" set "VS2022PATH=C:\Program Files\Microsoft Visual Studio\2022\Professional"
if not exist "!VS2022PATH!" set "VS2022PATH=C:\Program Files\Microsoft Visual Studio\2022\Enterprise"
if not exist "!VS2019PATH!" set "VS2019PATH=C:\Program Files (x86)\Microsoft Visual Studio\2019\Professional"
if not exist "!VS2019PATH!" set "VS2019PATH=C:\Program Files (x86)\Microsoft Visual Studio\2019\Enterprise"

:: Check for vswhere tool to find VS installation
for %%i in (vswhere.exe) do set "VSWHERE=%%~$PATH:i"
if defined VSWHERE (
    for /f "usebackq tokens=*" %%i in (`vswhere -latest -products * -requires Microsoft.Component.MSBuild -property installationPath`) do (
        set "VSINSTALLPATH=%%i"
        echo Found Visual Studio at: !VSINSTALLPATH!
    )
)

:: Try MSBuild directly if it's in PATH
where /q msbuild
if %ERRORLEVEL% equ 0 (
    echo MSBuild found in PATH, attempting to build...
    msbuild FlutterBundler.sln /p:Configuration=Release /p:Platform=x64
    if !ERRORLEVEL! neq 0 goto :BUILD_FAILED
    goto :BUILD_SUCCESS
)

:: Try using VS2022 path
if exist "!VS2022PATH!" (
    echo Found Visual Studio 2022 at: !VS2022PATH!
    if exist "!VS2022PATH!\MSBuild\Current\Bin\MSBuild.exe" (
        echo Using MSBuild from VS2022...
        "!VS2022PATH!\MSBuild\Current\Bin\MSBuild.exe" FlutterBundler.sln /p:Configuration=Release /p:Platform=x64
        if !ERRORLEVEL! neq 0 goto :BUILD_FAILED
        goto :BUILD_SUCCESS
    )
)

:: Try using VS2019 path
if exist "!VS2019PATH!" (
    echo Found Visual Studio 2019 at: !VS2019PATH!
    if exist "!VS2019PATH!\MSBuild\Current\Bin\MSBuild.exe" (
        echo Using MSBuild from VS2019...
        "!VS2019PATH!\MSBuild\Current\Bin\MSBuild.exe" FlutterBundler.sln /p:Configuration=Release /p:Platform=x64
        if !ERRORLEVEL! neq 0 goto :BUILD_FAILED
        goto :BUILD_SUCCESS
    )
)

:: Try using VS installation path found by vswhere
if defined VSINSTALLPATH (
    if exist "!VSINSTALLPATH!\MSBuild\Current\Bin\MSBuild.exe" (
        echo Using MSBuild from detected Visual Studio...
        "!VSINSTALLPATH!\MSBuild\Current\Bin\MSBuild.exe" FlutterBundler.sln /p:Configuration=Release /p:Platform=x64
        if !ERRORLEVEL! neq 0 goto :BUILD_FAILED
        goto :BUILD_SUCCESS
    )
)

:: If we get here, no valid Visual Studio installation was found
echo No Visual Studio installation with MSBuild was found.
echo Please install Visual Studio with C++ desktop development workload
echo or open FlutterBundler.sln in Visual Studio and build manually.
goto :END

:BUILD_FAILED
echo Build failed. Please check the error messages above.
goto :END

:BUILD_SUCCESS
echo Build completed successfully!
echo The bundled app is available at: bin\x64\Release\FontPreviewer.exe

pause

:END
echo.
echo Press any key to exit...
pause >nul
exit /b
