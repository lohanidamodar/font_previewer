import 'dart:io';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

class FontPickerDialog extends StatefulWidget {
  const FontPickerDialog({super.key});

  @override
  State<FontPickerDialog> createState() => _FontPickerDialogState();
}

class _FontPickerDialogState extends State<FontPickerDialog> {
  late TextEditingController _controller;
  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  pickFolder() async {
    final selectedDirectory = await FilePicker.platform
        .getDirectoryPath(dialogTitle: 'Select folder containing your fonts');
    if (selectedDirectory != null) {
      // load fonts in the directory
      _controller.text = selectedDirectory;
      final dir = Directory.fromUri(Uri.file(selectedDirectory));
      final items = dir.listSync(recursive: true);
      for (final item in items) {
        if (item.statSync().type == FileSystemEntityType.file) {
          print(item.path);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Select a folder with your fonts",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18.0),
          ),
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
          )
        ],
      ),
    );
  }
}
