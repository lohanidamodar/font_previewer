# Flutter Application Bundler

This tool bundles a Flutter Windows application into a single executable file, similar to how Enigma Virtual Box works. It embeds all resources and assets into the executable and extracts them at runtime.

## Features

- Creates a single portable EXE file
- Bundles all DLLs, assets, and resources
- Extracts resources to a temporary location at runtime
- Uses the same app icon as the Flutter application
- Cleans up temporary files when the application exits

## Building the Bundler

### Prerequisites

1. Visual Studio 2019 or newer with C++ desktop development workload
2. Flutter SDK (for building the Flutter app)
3. CMake 3.10 or higher (optional, you can use Visual Studio directly)

### Option 1: Automated Build (Recommended)

Run the `build.bat` script to build the bundler after building your Flutter app:

```
cd bundler
build.bat
```

### Option 2: Manual Build Steps

1. Build your Flutter app in release mode:
   ```
   flutter build windows --release
   ```

2. Build the bundler using one of these methods:
   - Run `build_manual.bat` which will attempt to use MSBuild if available
   - Open `FlutterBundler.sln` in Visual Studio and build manually
   - Use CMake if installed:
     ```
     cd src\bundler
     mkdir build
     cd build
     cmake .. -G "Visual Studio 17 2022" -A x64
     cmake --build . --config Release
     ```

## How It Works

1. The bundler embeds all necessary files as resources
2. When run, it extracts these resources to a temporary directory
3. It then starts the Flutter application from this directory
4. When the Flutter application exits, it cleans up the temporary files

## Testing the Bundled Application

After building the bundler, you'll find the output in one of these locations:
- `src\bundler\bin\x64\Release\FontPreviewer.exe` (if built with Visual Studio directly)
- `src\bundler\build\bin\Release\FontPreviewer.exe` (if built with CMake)

You can run the `test_bundled_app.bat` script to test the bundled application.

## Customizing for Your Own Flutter App

If you want to use this for another Flutter app:

1. Update the `resources.rc` file to reference your app's files:
   - Update paths to point to your Flutter release build
   - Add/remove resources as needed for your app

2. Update the `ResourceExtractor` constructor in `resource_extractor.cpp`:
   - Match the resource IDs with what's in your resources.rc
   - Update the paths for extraction

3. Rebuild the bundler as instructed above

## Troubleshooting

- **Missing files error**: Make sure you've built your Flutter app in release mode
- **Resource not found**: Check that the resource IDs in the code match those in resources.rc
- **Build errors**: Ensure you have Visual Studio with C++ desktop development workload installed
