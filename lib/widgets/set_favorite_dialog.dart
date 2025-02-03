import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SetFavoriteDialog extends StatefulWidget {
  const SetFavoriteDialog({super.key});

  @override
  State<SetFavoriteDialog> createState() => _SetFavoriteDialogState();
}

class _SetFavoriteDialogState extends State<SetFavoriteDialog> {
  late TextEditingController _controller;
  String selectedDirectory = '';
  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    getFavoriteFolder();
  }

  getFavoriteFolder() async {
    final sp = await SharedPreferencesWithCache.create(
        cacheOptions: SharedPreferencesWithCacheOptions());

    final path = sp.getString('favourites') ?? '';
    _controller.text = path;
    setState(() {});
  }

  pickFolder() async {
    selectedDirectory = await FilePicker.platform.getDirectoryPath(
            dialogTitle: 'Select folder containing your fonts') ??
        '';

    _controller.text =
        selectedDirectory.isNotEmpty ? selectedDirectory : _controller.text;
    setState(() {});
  }

  addTolibrary() async {
    if (_controller.text.isEmpty) {
      return;
    }
    final sp = await SharedPreferencesWithCache.create(
        cacheOptions: SharedPreferencesWithCacheOptions());

    await sp.setString('favourites', _controller.text);
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
            "Select a folder to copy favourite fonts to",
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
          const SizedBox(height: 10.0),
          ElevatedButton(
            onPressed: _controller.text.isNotEmpty ? addTolibrary : null,
            child: Text("Save"),
          ),
        ],
      ),
    );
  }
}
