#include <iostream>
#include <windows.h>
#include <shlobj.h>
#include "resource_extractor.h"

// Forward declaration for console attachment in debug mode
void AttachConsole();

int WINAPI WinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance, LPSTR lpCmdLine, int nCmdShow)
{
#ifdef _DEBUG
    AttachConsole();
#endif

    try
    {
        // Create the resource extractor
        ResourceExtractor extractor;

        // Initialize the extractor
        if (!extractor.initialize())
        {
            MessageBoxA(NULL, "Failed to initialize resource extractor.", "Font Previewer", MB_ICONERROR);
            return 1;
        }

        // Extract resources
        if (!extractor.extractResources())
        {
            MessageBoxA(NULL, "Failed to extract resources.", "Font Previewer", MB_ICONERROR);
            return 1;
        }

        // Run the extracted application
        if (!extractor.runApplication())
        {
            MessageBoxA(NULL, "Failed to run application.", "Font Previewer", MB_ICONERROR);
            return 1;
        }

        // Cleanup is handled in the destructor
        return 0;
    }
    catch (const std::exception &e)
    {
        std::string errorMsg = "An unexpected error occurred: ";
        errorMsg += e.what();
        MessageBoxA(NULL, errorMsg.c_str(), "Font Previewer", MB_ICONERROR);
        return 1;
    }
    catch (...)
    {
        MessageBoxA(NULL, "An unknown error occurred.", "Font Previewer", MB_ICONERROR);
        return 1;
    }
}

// Attach to console for debugging purposes
void AttachConsole()
{
    // Allocate a console for this app
    AllocConsole();
    // Redirect stdout to the console
    FILE *pConsole;
    freopen_s(&pConsole, "CONOUT$", "w", stdout);
    // Redirect stderr to the console
    freopen_s(&pConsole, "CONOUT$", "w", stderr);
}

// Alternative entry point for console debugging if needed
/*
int main(int argc, char* argv[]) {
    return WinMain(GetModuleHandle(NULL), NULL, GetCommandLineA(), SW_SHOWDEFAULT);
}
*/
