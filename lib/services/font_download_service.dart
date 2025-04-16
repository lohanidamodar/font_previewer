import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class FontDownloadService {
  // Google Fonts API endpoint
  static const String _googleFontsApi = 'https://fonts.googleapis.com/css2';

  // Download a Google font file
  static Future<String?> downloadGoogleFont(String fontFamily,
      {BuildContext? context}) async {
    try {
      // Step 1: Get the CSS file that contains the font URL
      final Uri cssUrl = Uri.parse('$_googleFontsApi?family=$fontFamily');
      final http.Response cssResponse = await http.get(
        cssUrl,
        headers: {
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
        },
      );

      if (cssResponse.statusCode != 200) {
        debugPrint('Failed to fetch font CSS: ${cssResponse.statusCode}');
        return null;
      }

      // Step 2: Extract the font URL from the CSS
      final String css = cssResponse.body;
      final RegExp fontUrlRegex = RegExp(r'url\((https:\/\/[^)]+\.woff2)\)');
      final Match? match = fontUrlRegex.firstMatch(css);

      if (match == null || match.groupCount < 1) {
        debugPrint('Could not find font URL in CSS');
        return null;
      }

      final String fontUrl = match.group(1)!;

      // Step 3: Download the font file
      final http.Response fontResponse = await http.get(Uri.parse(fontUrl));
      if (fontResponse.statusCode != 200) {
        debugPrint('Failed to download font: ${fontResponse.statusCode}');
        return null;
      }

      // Step 4: Save the font to a local file
      final Directory downloadsDir = await _getDownloadsDirectory();
      final String filePath = path.join(
          downloadsDir.path, '${fontFamily.replaceAll(' ', '_')}.woff2');

      final File file = File(filePath);
      await file.writeAsBytes(fontResponse.bodyBytes);

      // Show success message if context is provided
      if (context != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Font $fontFamily downloaded to ${file.path}')),
        );
      }

      return file.path;
    } catch (e) {
      debugPrint('Error downloading font: $e');

      // Show error message if context is provided
      if (context != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to download font: $e')),
        );
      }

      return null;
    }
  }

  // Helper method to get the downloads directory based on platform
  static Future<Directory> _getDownloadsDirectory() async {
    Directory? directory;

    try {
      if (Platform.isAndroid || Platform.isIOS) {
        directory = await getApplicationDocumentsDirectory();
      } else if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
        directory = await getDownloadsDirectory();

        // Fall back to documents directory if downloads isn't available
        if (directory == null) {
          directory = await getApplicationDocumentsDirectory();
        }
      } else {
        directory = await getApplicationDocumentsDirectory();
      }
    } catch (e) {
      // Fall back to temp directory if all else fails
      directory = await getTemporaryDirectory();
    }

    // Create a 'downloaded_fonts' subdirectory
    final String fontsPath = path.join(directory.path, 'downloaded_fonts');
    final Directory fontsDir = Directory(fontsPath);

    if (!await fontsDir.exists()) {
      await fontsDir.create(recursive: true);
    }

    return fontsDir;
  }
}
