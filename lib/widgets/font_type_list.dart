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
  String favoritesPath = '';
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

    favoritesPath = sp.getString('favourites') ?? '';
    setState(() {});
  }

  _removeFontLibrary(String key) async {
    final sp = await SharedPreferencesWithCache.create(
        cacheOptions: SharedPreferencesWithCacheOptions());
    fontLibrary.remove(key);
    sp.setString('font_library', jsonEncode(fontLibrary));
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        if (favoritesPath.isNotEmpty) ...[
          ListTile(
            title: Text(
              "Favorites",
              style: TextStyle(
                fontSize: 18.0,
                color: Colors.white,
              ),
            ),
            onTap: () => widget.onTapFontType('favourites'),
          ),
        ],
        ListTile(
          title: Text(
            "Google fonts",
            style: TextStyle(
              fontSize: 18.0,
              color: Colors.white,
            ),
          ),
          onTap: () => widget.onTapFontType('google'),
        ),
        ...fontLibrary.keys.map((key) => ListTile(
              key: ValueKey(key),
              title: Text(
                fontLibrary[key]['name'] ?? '',
                style: TextStyle(
                  fontSize: 18.0,
                  color: Colors.white,
                ),
              ),
              onTap: () => widget.onTapFontType(key),
              trailing: IconButton(
                color: Colors.white,
                icon: Icon(Icons.delete),
                onPressed: () async {
                  final remove = await showDialog(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          title: Text("Remove?"),
                          content: Text("Are you sure you want to remove?"),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context, false);
                              },
                              child: Text("No"),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context, true);
                              },
                              child: Text("Yes, remove"),
                            ),
                          ],
                        );
                      });
                  if (remove ?? false) {
                    _removeFontLibrary(key);
                  }
                },
              ),
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
