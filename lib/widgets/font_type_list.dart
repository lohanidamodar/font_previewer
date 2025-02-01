import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:font_previewer/widgets/font_picker_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';

typedef OnTapFontType = Function(String);

class FontTypeList extends StatefulWidget {
  final OnTapFontType onTapFontType;
  const FontTypeList({super.key, required this.onTapFontType});

  @override
  State<FontTypeList> createState() => _FontTypeListState();
}

class _FontTypeListState extends State<FontTypeList> {
  Map<String, dynamic> fontLibrary = {};
  @override
  void initState() {
    super.initState();
    getFontLibraries();
  }

  getFontLibraries() async {
    final sp = await SharedPreferencesWithCache.create(
        cacheOptions: SharedPreferencesWithCacheOptions());
    final existing = sp.getString('font_library');
    fontLibrary = jsonDecode(existing ?? '{}');
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        ListTile(
          title: Text("Google fonts"),
          onTap: () => widget.onTapFontType('google'),
        ),
        ...fontLibrary.keys.map((key) => ListTile(
              key: ValueKey(key),
              title: Text(fontLibrary[key]['name'] ?? ''),
              onTap: () => widget.onTapFontType(key),
            )),
        Center(
          child: ElevatedButton(
              onPressed: () async {
                final added = await showDialog(
                    context: context,
                    builder: (context) {
                      return Dialog(
                        child: FontPickerDialog(),
                      );
                    });
                if (added ?? false) {
                  getFontLibraries();
                }
              },
              child: Text("Add my fonts")),
        ),
      ],
    );
  }
}
