// Generated header for resource extraction
#ifndef FLUTTER_BUNDLED_H
#define FLUTTER_BUNDLED_H

#include "resource.h"

// Resource extraction mapping
struct ResourceMapping {
    int resourceId;
    const wchar_t* targetPath;
    bool isDll;
};

// Create an array of resources to extract
static const ResourceMapping BUNDLED_RESOURCES[] = {
    // DLLs
    {IDR_DLL_FLUTTER_WINDOWS, L"flutter_windows.dll", true},
    {IDR_DLL_URL_LAUNCHER, L"url_launcher_windows_plugin.dll", true},

    // Data files
    {IDR_DATA_APP_SO, L"data\\app.so", false},
    {IDR_DATA_ICUDTL, L"data\\icudtl.dat", false},

    // Flutter assets
    {IDR_ASSET_MANIFEST_BIN, L"data\\flutter_assets\\AssetManifest.bin", false},
    {IDR_ASSET_MANIFEST_JSON, L"data\\flutter_assets\\AssetManifest.json", false},
    {IDR_FONT_MANIFEST_JSON, L"data\\flutter_assets\\FontManifest.json", false},
    {IDR_NATIVE_ASSETS_MANIFEST_JSON, L"data\\flutter_assets\\NativeAssetsManifest.json", false},
    {IDR_NOTICES_Z, L"data\\flutter_assets\\NOTICES.Z", false},
    {IDR_MATERIAL_ICONS_FONT, L"data\\flutter_assets\\fonts\\MaterialIcons-Regular.otf", false},
    {IDR_INK_SPARKLE_SHADER, L"data\\flutter_assets\\shaders\\ink_sparkle.frag", false},
};

#endif // FLUTTER_BUNDLED_H
