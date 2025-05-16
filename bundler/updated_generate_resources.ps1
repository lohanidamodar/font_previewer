# Script to auto-generate resources.rc file for Flutter bundler
# Usage: .\generate_resources.ps1 -ReleasePath "path\to\flutter\release\folder"

param (
    [Parameter(Mandatory=$true)]
    [string]$ReleasePath,
    
    [Parameter(Mandatory=$false)]
    [string]$FlutterProjectPath = ""
)

# Convert to absolute path if relative
if (-not [System.IO.Path]::IsPathRooted($ReleasePath)) {
    $ReleasePath = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($PWD, $ReleasePath))
}

# Ensure the release path exists
if (-not (Test-Path $ReleasePath)) {
    Write-Error "The specified release path does not exist: $ReleasePath"
    exit 1
}

Write-Host "Release Path: $ReleasePath"

# If Flutter project path not provided, try to determine it
if ([string]::IsNullOrEmpty($FlutterProjectPath)) {
    # Try to find the Flutter project root (assume standard directory structure)
    $FlutterProjectPath = (Get-Item $ReleasePath).Directory.Parent.Parent.FullName
    Write-Host "Auto-detected Flutter Project Path: $FlutterProjectPath"
}

# Create resources directory if it doesn't exist
$resourcesDir = Join-Path $PSScriptRoot "resources"
if (-not (Test-Path $resourcesDir)) {
    Write-Host "Creating resources directory..."
    New-Item -ItemType Directory -Path $resourcesDir -Force | Out-Null
}

# Possible locations for the Flutter app icon
$iconLocations = @(
    # Standard location in Flutter Windows project
    (Join-Path $FlutterProjectPath "windows\runner\resources\app_icon.ico"),
    # Direct location in project root (for testing)
    (Join-Path $FlutterProjectPath "app_icon.ico"),
    # Try to find icon anywhere in the project
    (Get-ChildItem -Path $FlutterProjectPath -Recurse -Filter "app_icon.ico" -ErrorAction SilentlyContinue | Select-Object -First 1 -ExpandProperty FullName)
)

# Destination for the app icon
$destinationIconPath = Join-Path $resourcesDir "app_icon.ico"
$iconFound = $false

# Try each location until we find one
foreach ($iconPath in $iconLocations) {
    if ($iconPath -and (Test-Path $iconPath)) {
        Write-Host "Found Flutter app icon at: $iconPath"
        Write-Host "Copying icon to: $destinationIconPath"
        Copy-Item -Path $iconPath -Destination $destinationIconPath -Force
        $iconFound = $true
        break
    }
}

# If we didn't find an icon, copy the default one if it exists
if (-not $iconFound) {
    $defaultIconPath = Join-Path $PSScriptRoot "default_icon.ico"
    if (Test-Path $defaultIconPath) {
        Write-Host "Using default icon: $defaultIconPath"
        Copy-Item -Path $defaultIconPath -Destination $destinationIconPath -Force
        $iconFound = $true
    } else {
        Write-Host "Warning: No app icon found. The bundler will use the default Windows application icon."
    }
}

# Create resource.h file
$resourceHeader = @"
//{{NO_DEPENDENCIES}}
// Microsoft Visual C++ generated include file.
// Used by resources.rc

#define IDI_APP_ICON                    101

// Resource IDs for embedded files
#define IDR_EXE_FLUTTER_APP             1
#define IDR_DLL_FLUTTER_WINDOWS         2
#define IDR_DLL_URL_LAUNCHER            3
#define IDR_DATA_APP_SO                 4
#define IDR_DATA_ICUDTL                 5
#define IDR_ASSET_MANIFEST_BIN          10
#define IDR_ASSET_MANIFEST_JSON         11
#define IDR_FONT_MANIFEST_JSON          12
#define IDR_NATIVE_ASSETS_MANIFEST_JSON 13
#define IDR_NOTICES_Z                   14
#define IDR_MATERIAL_ICONS_FONT         15
#define IDR_INK_SPARKLE_SHADER          16

// Next default values for new objects
//
#ifdef APSTUDIO_INVOKED
#ifndef APSTUDIO_READONLY_SYMBOLS
#define _APS_NEXT_RESOURCE_VALUE        102
#define _APS_NEXT_COMMAND_VALUE         40001
#define _APS_NEXT_CONTROL_VALUE         1001
#define _APS_NEXT_SYMED_VALUE           101
#endif
#endif
"@
$resourceHeader | Out-File -FilePath "resource.h" -Encoding ASCII -Force

# Initialize resource content
$resourceContent = @"
#include <windows.h>
#include "resource.h"

"@

# Add app icon resource if it exists
if ($iconFound -or (Test-Path $destinationIconPath)) {
    $resourceContent += @"
// Application Icon
IDI_APP_ICON            ICON                    "resources\\app_icon.ico"

"@
}

$resourceContent += @"
// Executable
// Note: Manifest is handled by the project file, so we don't include it here

// Main Files
"@

# Start resource ID counter for any additional resources
$resourceId = 1000  # Start from 1000 for any additional resources beyond those defined in resource.h

# Function to add a file to the resources
function Add-Resource {
    param (
        [string]$FilePath,
        [string]$Type = "RCDATA",
        [string]$ResourceName = "",
        [int]$Id = $script:resourceId
    )
    
    # Only add files, not directories
    if (-not (Test-Path $FilePath -PathType Leaf)) {
        return
    }
    
    # Get the relative path from release folder
    $relativePath = $FilePath.Substring($ReleasePath.Length + 1).Replace('\', '/')
    
    # Create the resource entry
    if ($ResourceName -ne "") {
        $resourceEntry = "$ResourceName $Type `"$relativePath`"`n"
    } else {
        $resourceEntry = "$Id $Type `"$relativePath`"`n"
        # Increment the resource ID if using numeric ID
        $script:resourceId++
    }
    
    $script:resourceContent += $resourceEntry
}

# Function to scan a directory recursively for files
function Scan-Directory-Recursively {
    param (
        [string]$Directory,
        [string]$SectionHeader = ""
    )
    
    if (-not (Test-Path $Directory -PathType Container)) {
        return
    }
    
    if ($SectionHeader -ne "") {
        $script:resourceContent += "`n// $SectionHeader`n"
    }
    
    # Get all files in the directory and its subdirectories
    Get-ChildItem -Path $Directory -File -Recurse | ForEach-Object {
        # Check for special files
        $fileName = $_.Name.ToLower()
        $relativePath = $_.FullName.Substring($ReleasePath.Length + 1).ToLower()
        
        # Handle specific files with symbolic names
        if ($relativePath -eq "data\flutter_assets\fonts\materialicons-regular.otf") {
            Add-Resource -FilePath $_.FullName -ResourceName "IDR_MATERIAL_ICONS_FONT"
        }
        elseif ($relativePath -eq "data\flutter_assets\shaders\ink_sparkle.frag") {
            Add-Resource -FilePath $_.FullName -ResourceName "IDR_INK_SPARKLE_SHADER"
        }
        else {
            # Add other files with numeric IDs
            Add-Resource -FilePath $_.FullName
        }
    }
}

# Get all the main files in the release folder (non-recursive)
Write-Host "Scanning root folder for executable and DLLs..."
$exeFound = $false
$flutterDllFound = $false
$urlLauncherFound = $false

Get-ChildItem -Path $ReleasePath -File | ForEach-Object {
    $fileName = $_.Name.ToLower()
    if ($fileName -eq "font_previewer.exe") {
        Add-Resource -FilePath $_.FullName -ResourceName "IDR_EXE_FLUTTER_APP"
        $exeFound = $true
    }
    elseif ($fileName -eq "flutter_windows.dll") {
        Add-Resource -FilePath $_.FullName -ResourceName "IDR_DLL_FLUTTER_WINDOWS"
        $flutterDllFound = $true
    }
    elseif ($fileName -eq "url_launcher_windows_plugin.dll") {
        Add-Resource -FilePath $_.FullName -ResourceName "IDR_DLL_URL_LAUNCHER"
        $urlLauncherFound = $true
    }
    else {
        Add-Resource -FilePath $_.FullName
    }
}

# Add data folder files
$resourceContent += "`n// Data Folder Files`n"
if (Test-Path "$ReleasePath\data") {
    Write-Host "Scanning data folder for key files..."
    $appSoFound = $false
    $icudtlFound = $false

    Get-ChildItem -Path "$ReleasePath\data" -File | ForEach-Object {
        $fileName = $_.Name.ToLower()
        if ($fileName -eq "app.so") {
            Add-Resource -FilePath $_.FullName -ResourceName "IDR_DATA_APP_SO"
            $appSoFound = $true
        }
        elseif ($fileName -eq "icudtl.dat") {
            Add-Resource -FilePath $_.FullName -ResourceName "IDR_DATA_ICUDTL"
            $icudtlFound = $true
        }
        else {
            Add-Resource -FilePath $_.FullName
        }
    }

    # Add flutter_assets files
    if (Test-Path "$ReleasePath\data\flutter_assets") {
        Write-Host "Scanning flutter_assets folder..."
        $resourceContent += "`n// Flutter Assets`n"
        $assetManifestBinFound = $false
        $assetManifestJsonFound = $false
        $fontManifestJsonFound = $false
        $nativeAssetsManifestJsonFound = $false
        $noticesZFound = $false

        Get-ChildItem -Path "$ReleasePath\data\flutter_assets" -File | ForEach-Object {
            $fileName = $_.Name.ToLower()
            if ($fileName -eq "assetmanifest.bin") {
                Add-Resource -FilePath $_.FullName -ResourceName "IDR_ASSET_MANIFEST_BIN"
                $assetManifestBinFound = $true
            }
            elseif ($fileName -eq "assetmanifest.json") {
                Add-Resource -FilePath $_.FullName -ResourceName "IDR_ASSET_MANIFEST_JSON"
                $assetManifestJsonFound = $true
            }
            elseif ($fileName -eq "fontmanifest.json") {
                Add-Resource -FilePath $_.FullName -ResourceName "IDR_FONT_MANIFEST_JSON"
                $fontManifestJsonFound = $true
            }
            elseif ($fileName -eq "nativeassetsmanifest.json") {
                Add-Resource -FilePath $_.FullName -ResourceName "IDR_NATIVE_ASSETS_MANIFEST_JSON"
                $nativeAssetsManifestJsonFound = $true
            }
            elseif ($fileName -eq "notices.z") {
                Add-Resource -FilePath $_.FullName -ResourceName "IDR_NOTICES_Z"
                $noticesZFound = $true
            }
            else {
                Add-Resource -FilePath $_.FullName
            }
        }
        
        # Scan fonts folder recursively
        if (Test-Path "$ReleasePath\data\flutter_assets\fonts") {
            Scan-Directory-Recursively -Directory "$ReleasePath\data\flutter_assets\fonts" -SectionHeader "Font Files"
        }
        
        # Scan shaders folder recursively
        if (Test-Path "$ReleasePath\data\flutter_assets\shaders") {
            Scan-Directory-Recursively -Directory "$ReleasePath\data\flutter_assets\shaders" -SectionHeader "Shader Files"
        }
        
        # Scan any other assets folders recursively
        if (Test-Path "$ReleasePath\data\flutter_assets\assets") {
            Scan-Directory-Recursively -Directory "$ReleasePath\data\flutter_assets\assets" -SectionHeader "Asset Files"
        }
    }
}

# Add note about additional resources that should be handled by the code
$resourceContent += @"

// Note: 
// Folders like fonts and shaders are handled by the code directly
// by copying the entire directory structure at runtime.
// If your app has additional critical files that need to be embedded,
// add them here with sequential resource IDs.
"@

# Write the resource file
$outputFile = "resources.rc"
$resourceContent | Out-File -FilePath $outputFile -Encoding ASCII

Write-Host "Resource file generated: $outputFile"
Write-Host "App icon copied: $(Test-Path $destinationIconPath)"
Write-Host ""
Write-Host "IMPORTANT: Make sure your resource_extractor.cpp uses the correct resource IDs from resource.h."
Write-Host "You should now be able to successfully build the bundler with your Flutter app icon."
Write-Host "Run build.bat or build_manual.bat to build the bundler."
