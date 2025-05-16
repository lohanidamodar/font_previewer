#include "resource_extractor.h"
#include <iostream>
#include <fstream>
#include <shlobj.h>
#include <shlwapi.h>
#include <vector>
#include <string>

#pragma comment(lib, "shlwapi.lib")

ResourceExtractor::ResourceExtractor() : moduleHandle(nullptr)
{
    moduleHandle = GetModuleHandle(NULL);

    // Define resources to extract
    // Main executable and DLLs
    resources.push_back({1, "font_previewer.exe", "font_previewer.exe"});
    resources.push_back({2, "flutter_windows.dll", "flutter_windows.dll"});
    resources.push_back({3, "url_launcher_windows_plugin.dll", "url_launcher_windows_plugin.dll"});

    // Data folder contents
    resources.push_back({4, "data/app.so", "data/app.so"});
    resources.push_back({5, "data/icudtl.dat", "data/icudtl.dat"});

    // Flutter assets
    resources.push_back({10, "data/flutter_assets/AssetManifest.bin", "data/flutter_assets/AssetManifest.bin"});
    resources.push_back({11, "data/flutter_assets/AssetManifest.json", "data/flutter_assets/AssetManifest.json"});
    resources.push_back({12, "data/flutter_assets/FontManifest.json", "data/flutter_assets/FontManifest.json"});
    resources.push_back({13, "data/flutter_assets/NativeAssetsManifest.json", "data/flutter_assets/NativeAssetsManifest.json"});
    resources.push_back({14, "data/flutter_assets/NOTICES.Z", "data/flutter_assets/NOTICES.Z"});

    // Add more resources as needed
}

ResourceExtractor::~ResourceExtractor()
{
    cleanup();
}

bool ResourceExtractor::initialize()
{
    // Get temporary directory path
    tempPath = getTempDirectoryPath();

    if (tempPath.empty())
    {
        std::cerr << "Failed to get temporary directory path." << std::endl;
        return false;
    }

    // Create the base directory
    if (!createDirectoryStructure(tempPath))
    {
        std::cerr << "Failed to create temporary directory structure." << std::endl;
        return false;
    }

    return true;
}

std::string ResourceExtractor::getTempDirectoryPath()
{
    char tempPathBuffer[MAX_PATH];
    DWORD result = GetTempPathA(MAX_PATH, tempPathBuffer);

    if (result == 0 || result > MAX_PATH)
    {
        return "";
    }

    // Create a unique subfolder for our application
    std::string basePath = std::string(tempPathBuffer) + "FontPreviewer_" + std::to_string(GetCurrentProcessId());
    return basePath;
}

bool ResourceExtractor::createDirectoryStructure(const std::string &path)
{
    try
    {
        fs::create_directories(path);
        return true;
    }
    catch (const std::exception &e)
    {
        std::cerr << "Error creating directory: " << e.what() << std::endl;
        return false;
    }
}

bool ResourceExtractor::extractResources()
{
    // Extract all resources
    for (const auto &resource : resources)
    {
        if (!extractResource(resource))
        {
            std::cerr << "Failed to extract resource: " << resource.relativePath << std::endl;
            return false;
        }
    }

    // Create directories for assets
    std::string fontsDestDir = tempPath + "\\data\\flutter_assets\\fonts";
    std::string shadersDestDir = tempPath + "\\data\\flutter_assets\\shaders";

    createDirectoryStructure(fontsDestDir);
    createDirectoryStructure(shadersDestDir);

    // Get path to the Flutter release directory
    char exePath[MAX_PATH];
    GetModuleFileNameA(NULL, exePath, MAX_PATH);
    std::string exePathStr = std::string(exePath);
    size_t lastSlash = exePathStr.find_last_of("\\/");
    std::string exeDir = exePathStr.substr(0, lastSlash);

    // Try to find the Flutter release directory
    std::string releasePath = "";

    // First check current directory
    if (fs::exists(exeDir + "\\..\\build\\windows\\x64\\runner\\Release"))
    {
        releasePath = exeDir + "\\..\\build\\windows\\x64\\runner\\Release";
    }
    // Check relative path
    else if (fs::exists("..\\..\\build\\windows\\x64\\runner\\Release"))
    {
        char currentDir[MAX_PATH];
        GetCurrentDirectoryA(MAX_PATH, currentDir);
        releasePath = std::string(currentDir) + "\\..\\..\\build\\windows\\x64\\runner\\Release";
    }
    // Try absolute path
    else if (fs::exists("G:\\dev\\projects\\font_previewer\\build\\windows\\x64\\runner\\Release"))
    {
        releasePath = "G:\\dev\\projects\\font_previewer\\build\\windows\\x64\\runner\\Release";
    }

    if (!releasePath.empty())
    {
        std::string fontsSrcDir = releasePath + "\\data\\flutter_assets\\fonts";
        std::string shadersSrcDir = releasePath + "\\data\\flutter_assets\\shaders";

        // Copy directories if they exist
        if (fs::exists(fontsSrcDir))
        {
            copyDirectory(fontsSrcDir, fontsDestDir);
        }

        if (fs::exists(shadersSrcDir))
        {
            copyDirectory(shadersSrcDir, shadersDestDir);
        }
    }
    else
    {
        std::cerr << "Warning: Could not find Flutter release directory to copy additional assets" << std::endl;
    }

    // Store the executable path
    executablePath = tempPath + "\\" + "font_previewer.exe";

    return true;
}

bool ResourceExtractor::extractResource(const ResourceInfo &info)
{
    // Full path to extract the resource
    std::string fullPath = tempPath + "\\" + info.destinationPath;

    // Create directory structure if needed
    std::string directoryPath = fullPath.substr(0, fullPath.find_last_of("\\/"));
    if (!createDirectoryStructure(directoryPath))
    {
        return false;
    }

    // Find and load the resource
    HRSRC resourceHandle = FindResource(moduleHandle, MAKEINTRESOURCE(info.id), RT_RCDATA);
    if (!resourceHandle)
    {
        std::cerr << "Resource not found: " << info.id << std::endl;
        return false;
    }

    HGLOBAL resourceData = LoadResource(moduleHandle, resourceHandle);
    if (!resourceData)
    {
        std::cerr << "Failed to load resource: " << info.id << std::endl;
        return false;
    }

    DWORD resourceSize = SizeofResource(moduleHandle, resourceHandle);
    void *resourcePtr = LockResource(resourceData);

    if (!resourcePtr)
    {
        std::cerr << "Failed to lock resource: " << info.id << std::endl;
        return false;
    }

    // Write the resource to file
    std::ofstream outFile(fullPath, std::ios::binary);
    if (!outFile)
    {
        std::cerr << "Failed to create file: " << fullPath << std::endl;
        return false;
    }

    outFile.write(static_cast<const char *>(resourcePtr), resourceSize);
    outFile.close();

    return true;
}

bool ResourceExtractor::runApplication()
{
    if (executablePath.empty())
    {
        std::cerr << "Executable path not set. Did you extract resources?" << std::endl;
        return false;
    }

    // Start the extracted application
    STARTUPINFOA si;
    PROCESS_INFORMATION pi;

    ZeroMemory(&si, sizeof(si));
    si.cb = sizeof(si);
    ZeroMemory(&pi, sizeof(pi));

    // Set the working directory to where we extracted the files
    if (!CreateProcessA(
            executablePath.c_str(), // Application path
            NULL,                   // Command line arguments
            NULL,                   // Process security attributes
            NULL,                   // Thread security attributes
            FALSE,                  // Inherit handles
            0,                      // Creation flags
            NULL,                   // Environment
            tempPath.c_str(),       // Working directory
            &si,                    // Startup info
            &pi                     // Process information
            ))
    {
        std::cerr << "Failed to start application. Error code: " << GetLastError() << std::endl;
        return false;
    }

    // Wait for the process to exit
    WaitForSingleObject(pi.hProcess, INFINITE);

    // Close process and thread handles
    CloseHandle(pi.hProcess);
    CloseHandle(pi.hThread);

    return true;
}

void ResourceExtractor::cleanup()
{
    // Clean up the extracted files
    try
    {
        if (!tempPath.empty() && fs::exists(tempPath))
        {
            // Try to remove all files first to reduce chances of access issues
            for (const auto &entry : fs::recursive_directory_iterator(tempPath))
            {
                try
                {
                    if (!fs::is_directory(entry))
                    {
                        fs::remove(entry);
                    }
                }
                catch (...)
                {
                    // Continue trying to clean up other files
                }
            }

            // Now try to remove the entire directory
            try
            {
                fs::remove_all(tempPath);
            }
            catch (...)
            {
                // If removing all at once fails, try a second approach
                for (auto it = fs::directory_iterator(tempPath); it != fs::directory_iterator(); ++it)
                {
                    try
                    {
                        fs::remove_all(it->path());
                    }
                    catch (...)
                    {
                        // At this point we've done our best
                    }
                }
            }
        }
    }
    catch (const std::exception &e)
    {
        std::cerr << "Error during cleanup: " << e.what() << std::endl;
    }
    catch (...)
    {
        std::cerr << "Unknown error during cleanup" << std::endl;
    }
}

void ResourceExtractor::copyDirectory(const std::string &sourcePath, const std::string &destPath)
{
    try
    {
        if (!fs::exists(sourcePath))
        {
            std::cerr << "Source path does not exist: " << sourcePath << std::endl;
            return;
        }

        // Create the destination directory if it doesn't exist
        if (!fs::exists(destPath))
        {
            fs::create_directories(destPath);
        }

        // Copy all items in the directory
        for (const auto &entry : fs::directory_iterator(sourcePath))
        {
            const auto &path = entry.path();
            std::string filename = path.filename().string();
            std::string destFilePath = destPath + "\\" + filename;

            if (fs::is_directory(path))
            {
                // Recursively copy subdirectories
                copyDirectory(path.string(), destFilePath);
            }
            else
            {
                // Copy file
                fs::copy_file(path, destFilePath, fs::copy_options::overwrite_existing);
            }
        }
    }
    catch (const std::exception &e)
    {
        std::cerr << "Error copying directory: " << e.what() << std::endl;
    }
}
