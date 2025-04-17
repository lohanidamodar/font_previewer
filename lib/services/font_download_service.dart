import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FontDownloadService {
  static const String _googleFontsListApi =
      'https://fonts.google.com/download/list?family=';
  static const String _lastDirPrefKey = 'last_font_download_directory';

  // Download the complete Google font with all weights and styles
  static Future<String?> downloadGoogleFont(String fontFamily,
      {BuildContext? context, String? forceSaveDirectory}) async {
    try {
      // Get save directory - either forced or user-selected
      String? saveDirectory;

      if (forceSaveDirectory != null) {
        // Use the forced directory (for favorites)
        saveDirectory = forceSaveDirectory;

        // Make sure the directory exists
        final Directory directory = Directory(saveDirectory);
        if (!await directory.exists()) {
          await directory.create(recursive: true);
        }
      } else {
        // Get initial directory (downloads or last used)
        String? initialDirectory = await _getInitialDirectory();

        // Show a dialog to let the user pick a save location
        saveDirectory = await _pickSaveDirectory(initialDirectory);
        if (saveDirectory == null) {
          // User canceled the folder selection
          if (context != null && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Download canceled')),
            );
          }
          return null;
        }

        // Save this directory as the last used
        _saveLastDirectory(saveDirectory);
      }

      // Format the font family name for URL (replace spaces with plus signs)
      final String urlFormattedFontName = fontFamily.replaceAll(' ', '+');

      // Show initial download progress
      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Preparing font download...'),
              duration: Duration(seconds: 2)),
        );
      }

      // Step 1: Get the list of font files
      final Uri listUrl =
          Uri.parse('$_googleFontsListApi$urlFormattedFontName');
      final http.Response listResponse = await http.get(
        listUrl,
        headers: {
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
        },
      );

      if (listResponse.statusCode != 200) {
        debugPrint('Failed to fetch font list: ${listResponse.statusCode}');
        if (context != null && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    'Failed to fetch font list: HTTP ${listResponse.statusCode}')),
          );
        }
        return null;
      }

      // Clean the response body by removing the ")]}'" prefix before parsing JSON
      String responseBody = listResponse.body;
      if (responseBody.startsWith(")]}'")) {
        responseBody = responseBody.substring(4);
      }

      // Parse the JSON response to get file URLs
      final Map<String, dynamic> listData = json.decode(responseBody);
      final List<dynamic> fontFiles = listData['manifest']['fileRefs'] ?? [];
      final List<dynamic> licenseFiles = listData['manifest']['files'] ?? [];
      final String zipName =
          listData['zipName'] ?? '${fontFamily.replaceAll(' ', '_')}.zip';

      if (fontFiles.isEmpty) {
        debugPrint('No font files found for $fontFamily');
        if (context != null && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('No font files found for $fontFamily')),
          );
        }
        return null;
      }

      // Create a folder for this font family using the zipName without extension
      final String fontFamilyName = path.basenameWithoutExtension(zipName);
      final String fontFamilyDir = path.join(saveDirectory, fontFamilyName);
      final Directory directory = Directory(fontFamilyDir);
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }

      // Step 2: Download each font file
      int downloadedFiles = 0;
      final List<String> downloadedFilePaths = [];

      // First save any license or readme files to the temp directory
      for (final fileData in licenseFiles) {
        final String fileName = fileData['filename'];
        final String contents = fileData['contents'];
        final String filePath = path.join(fontFamilyDir, fileName);

        final File file = File(filePath);
        await file.writeAsString(contents);
        downloadedFilePaths.add(filePath);
      }

      // Then download the font files to the temp directory
      for (final fileData in fontFiles) {
        final String fileUrl = fileData['url'];
        final String fileName = fileData['filename']; // Use filename from JSON

        // Handle potential subdirectories in the filename
        final String fileSavePath = path.join(fontFamilyDir, fileName);

        // Create directories if filename contains path separators
        if (fileName.contains('/') || fileName.contains('\\')) {
          final String dirPath = path.dirname(fileSavePath);
          final Directory dir = Directory(dirPath);
          if (!await dir.exists()) {
            await dir.create(recursive: true);
          }
        }

        // Download the font file
        final http.Response fileResponse = await http.get(Uri.parse(fileUrl));

        if (fileResponse.statusCode == 200) {
          final File file = File(fileSavePath);
          await file.writeAsBytes(fileResponse.bodyBytes);
          downloadedFilePaths.add(fileSavePath);
          downloadedFiles++;

          // Update progress
          if (context != null && context.mounted && downloadedFiles % 3 == 0) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(
                      'Downloading... ($downloadedFiles/${fontFiles.length})'),
                  duration: const Duration(milliseconds: 500)),
            );
          }
        }
      }

      // Create zip file at the final destination
      final String zipFilePath = path.join(saveDirectory, zipName);

      // Show success message
      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Font package saved with $downloadedFiles files'),
            action: SnackBarAction(
              label: 'OPEN FOLDER',
              onPressed: () => _openFolder(saveDirectory!),
            ),
          ),
        );
      }

      return zipFilePath;
    } catch (e) {
      debugPrint('Error downloading font: $e');

      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to download font: $e')),
        );
      }

      return null;
    }
  }

  // Get the initial directory for the file picker
  static Future<String?> _getInitialDirectory() async {
    // First check if we have a saved last directory
    final prefs = await SharedPreferences.getInstance();
    final String? lastDir = prefs.getString(_lastDirPrefKey);

    if (lastDir != null && Directory(lastDir).existsSync()) {
      return lastDir;
    }

    // Fall back to downloads directory
    try {
      if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
        final dir = await getDownloadsDirectory();
        return dir?.path;
      }
    } catch (_) {
      // Ignore errors, we'll return null and let the picker use its default
    }
    return null;
  }

  // Save the last used directory
  static Future<void> _saveLastDirectory(String directory) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastDirPrefKey, directory);
  }

  // Let the user pick a directory to save the font
  static Future<String?> _pickSaveDirectory(String? initialDirectory) async {
    final String? selectedDirectory =
        await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Select folder to save font package',
      initialDirectory: initialDirectory,
    );

    return selectedDirectory;
  }

  // Open the folder where the font was saved
  static Future<void> _openFolder(String folderPath) async {
    try {
      if (Platform.isWindows) {
        await Process.run('explorer', [folderPath]);
      } else if (Platform.isMacOS) {
        await Process.run('open', [folderPath]);
      } else if (Platform.isLinux) {
        await Process.run('xdg-open', [folderPath]);
      }
    } catch (e) {
      debugPrint('Error opening folder: $e');
    }
  }
}
