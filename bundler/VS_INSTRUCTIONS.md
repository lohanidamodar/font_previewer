# Visual Studio solution for Flutter Bundler
# This file can be opened directly in Visual Studio as a ready-to-use project

1. Open Visual Studio 2019 or newer
2. Create a new Windows Desktop Application C++ project named "FlutterBundler"
3. Replace the generated code with the files from this directory
4. Add the following files to your project:
   - main.cpp
   - resource_extractor.h
   - resource_extractor.cpp
   - app.manifest

5. Create a new Resource File (.rc) named "resources.rc" with the following content:

```
#include <windows.h>

// Executable
CREATEPROCESS_MANIFEST_RESOURCE_ID RT_MANIFEST "app.manifest"
1 RCDATA "../build/windows/x64/runner/Release/font_previewer.exe"
2 RCDATA "../build/windows/x64/runner/Release/flutter_windows.dll"
3 RCDATA "../build/windows/x64/runner/Release/url_launcher_windows_plugin.dll"
4 RCDATA "../build/windows/x64/runner/Release/data/app.so"
5 RCDATA "../build/windows/x64/runner/Release/data/icudtl.dat"

// Flutter Assets
10 RCDATA "../build/windows/x64/runner/Release/data/flutter_assets/AssetManifest.bin"
11 RCDATA "../build/windows/x64/runner/Release/data/flutter_assets/AssetManifest.json"
12 RCDATA "../build/windows/x64/runner/Release/data/flutter_assets/FontManifest.json"
13 RCDATA "../build/windows/x64/runner/Release/data/flutter_assets/NativeAssetsManifest.json"
14 RCDATA "../build/windows/x64/runner/Release/data/flutter_assets/NOTICES.Z"
```

6. Update project settings:
   - Set Subsystem to Windows (/SUBSYSTEM:WINDOWS)
   - Set Character Set to Multi-Byte
   - Add "shlwapi.lib" to Additional Dependencies

7. Build the solution in Release mode

The output executable will be a single file that contains all the Flutter app resources.
