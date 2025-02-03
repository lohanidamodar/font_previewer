import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

class FontPickerDialog extends StatefulWidget {
  const FontPickerDialog({super.key});

  @override
  State<FontPickerDialog> createState() => _FontPickerDialogState();
}

class _FontPickerDialogState extends State<FontPickerDialog> {
  late TextEditingController _controller;
  String name = '';
  List<String> fontFiles = [];
  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  pickFolder() async {
    final selectedDirectory = await FilePicker.platform
        .getDirectoryPath(dialogTitle: 'Select folder containing your fonts');
    if (selectedDirectory != null) {
      _controller.text = selectedDirectory;
      final dir = Directory.fromUri(Uri.file(selectedDirectory));
      final items = dir.listSync(recursive: true);
      name = p.basename(dir.path);
      setState(() {
        fontFiles = [];
      });
      for (final item in items) {
        if (item.statSync().type == FileSystemEntityType.file) {
          final file = File.fromUri(item.uri);
          final extension = p.extension(item.path);
          if (extension != '.ttf' && extension != '.otf') {
            continue;
          }
          fontFiles.add(file.path);
        }
        setState(() {});
      }
    }
  }

  addTolibrary() async {
    final sp = await SharedPreferencesWithCache.create(
        cacheOptions: SharedPreferencesWithCacheOptions());
    final existing = sp.getString('font_library');
    final fontLibrary = jsonDecode(existing ?? '{}');
    fontLibrary[DateTime.now().millisecondsSinceEpoch.toString()] = {
      'name': name,
      'fonts': fontFiles
    };
    sp.setString('font_library', jsonEncode(fontLibrary));
    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.0),
      width: 500,
      height: 400,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Select a folder with your fonts",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18.0),
          ),
          const SizedBox(height: 10.0),
          Row(
            children: [
              Expanded(
                child: TextField(controller: _controller),
              ),
              ElevatedButton(
                onPressed: pickFolder,
                child: Text("Select folder"),
              ),
            ],
          ),
          if (fontFiles.isNotEmpty) ...[
            const SizedBox(height: 10.0),
            Text("Fonts found: ${fontFiles.length}")
          ],
          const SizedBox(height: 10.0),
          ElevatedButton(
            onPressed:
                name.isNotEmpty && fontFiles.isNotEmpty ? addTolibrary : null,
            child: Text("Add to library"),
          ),
        ],
      ),
    );
  }
}
