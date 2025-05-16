# Script to auto-generate resources.rc file for Flutter bundler
# Usage: .\generate_resources.ps1 -ReleasePath "path\to\flutter\release\folder"

param (
    [Parameter(Mandatory=$true)]
    [string]$ReleasePath
)

# Ensure the release path exists
if (-not (Test-Path $ReleasePath)) {
    Write-Error "The specified release path does not exist: $ReleasePath"
    exit 1
}

# Initialize resource content
$resourceContent = @"
#include <windows.h>

// Executable and Manifest
CREATEPROCESS_MANIFEST_RESOURCE_ID RT_MANIFEST "app.manifest"

// Main Files
"@

# Start resource ID counter
$resourceId = 1

# Function to add a file to the resources
function Add-Resource {
    param (
        [string]$FilePath,
        [string]$Type = "RCDATA",
        [int]$Id = $script:resourceId
    )
    
    # Only add files, not directories
    if (-not (Test-Path $FilePath -PathType Leaf)) {
        return
    }
    
    # Get the relative path from release folder
    $relativePath = $FilePath.Substring($ReleasePath.Length + 1).Replace('\', '/')
    
    # Create the resource entry
    $resourceEntry = "$Id $Type `"$relativePath`"`n"
    $script:resourceContent += $resourceEntry
    
    # Increment the resource ID
    $script:resourceId++
}

# Get all the main files in the release folder (non-recursive)
Write-Host "Scanning root folder for executable and DLLs..."
Get-ChildItem -Path $ReleasePath -File | ForEach-Object {
    Add-Resource -FilePath $_.FullName
}

# Add data folder files
$resourceContent += "`n// Data Folder Files`n"
if (Test-Path "$ReleasePath\data") {
    Write-Host "Scanning data folder for key files..."
    Get-ChildItem -Path "$ReleasePath\data" -File | ForEach-Object {
        Add-Resource -FilePath $_.FullName
    }
    
    # Add flutter_assets files
    $resourceContent += "`n// Flutter Assets`n"
    if (Test-Path "$ReleasePath\data\flutter_assets") {
        Write-Host "Scanning flutter_assets folder..."
        Get-ChildItem -Path "$ReleasePath\data\flutter_assets" -File | ForEach-Object {
            Add-Resource -FilePath $_.FullName
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
Write-Host "Total resources added: $($resourceId - 1)"
Write-Host ""
Write-Host "IMPORTANT: You need to update the resource_extractor.cpp file to load these resources."
Write-Host "Resource IDs start at 1 and go up to $($resourceId - 1)."
