#pragma once

#include <string>
#include <vector>
#include <map>
#include <windows.h>
#include <filesystem>

namespace fs = std::filesystem;

class ResourceExtractor
{
public:
    ResourceExtractor();
    ~ResourceExtractor();

    // Initialize the extractor, create temp directories if needed
    bool initialize();

    // Extract all resources and prepare for execution
    bool extractResources();

    // Run the extracted application
    bool runApplication();

    // Clean up extracted resources
    void cleanup();

private:
    // Resource ID to filename mapping
    struct ResourceInfo
    {
        int id;
        std::string relativePath;
        std::string destinationPath;
    };

    // Extract a single resource to the specified path
    bool extractResource(const ResourceInfo &info);

    // Create directory structure if it doesn't exist
    bool createDirectoryStructure(const std::string &path);

    // Get path to temporary directory for extraction
    std::string getTempDirectoryPath();

    // Copy directory to the destination path
    void copyDirectory(const std::string &sourcePath, const std::string &destPath);

    // Collection of resources to extract
    std::vector<ResourceInfo> resources;

    // Path where resources are extracted
    std::string tempPath;

    // Handle to current module
    HMODULE moduleHandle;

    // Path to the extracted executable
    std::string executablePath;
};
