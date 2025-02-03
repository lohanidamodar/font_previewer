import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_previewer/models/font_family.dart';
import 'package:font_previewer/widgets/font_preview_container.dart';
import 'package:font_previewer/widgets/font_type_list.dart';
import 'package:font_previewer/widgets/set_favorite_dialog.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeDesktopScreen extends StatefulWidget {
  const HomeDesktopScreen({super.key});

  @override
  State<HomeDesktopScreen> createState() => _HomeDesktopScreenState();
}

class _HomeDesktopScreenState extends State<HomeDesktopScreen> {
  List<FontFamily> fontFamilies = [];

  onTypeSelected(String type) {
    fontFamilies = [];
    switch (type) {
      case 'google':
        final googleFonts = GoogleFonts.asMap().keys.toList();
        for (final font in googleFonts) {
          fontFamilies.add(FontFamily(name: font, path: font, isLocal: false));
        }
        break;
      case 'favourites':
        loadFontsFromFolder();
        break;
      default:
        loadFontsFromType(type);
        break;
    }

    setState(() {});
  }

  loadFontsFromFolder() async {
    final sp = await SharedPreferencesWithCache.create(
        cacheOptions: SharedPreferencesWithCacheOptions());

    final favoritesPath = sp.getString('favourites') ?? '';
    if (favoritesPath.isEmpty) {
      return;
    }
    final fontFiles = <String>[];
    final dir = Directory.fromUri(Uri.file(favoritesPath));
    final items = dir.listSync(recursive: true);
    for (final item in items) {
      if (item.statSync().type == FileSystemEntityType.file) {
        final file = File.fromUri(item.uri);
        final extension = p.extension(item.path);
        if (extension != '.ttf' && extension != '.otf') {
          continue;
        }
        fontFiles.add(file.path);
      }
    }

    loadFontsFromFiles(fontFiles, 'favourites');
  }

  loadFontsFromFiles(List<String> fonts, String name) async {
    if (fonts.isEmpty) {
      return;
    }

    int index = 0;
    for (final path in fonts) {
      final fontFile = File(path);
      if (fontFile.existsSync()) {
        final family = '$name$index';
        final data = ByteData.sublistView(fontFile.readAsBytesSync());
        final loader = FontLoader(family);
        loader.addFont(Future.value(data));
        await loader.load();
        fontFamilies.add(FontFamily(name: family, path: path));
        index++;
      }
    }
    setState(() {});
  }

  loadFontsFromType(String type) async {
    final sp = await SharedPreferencesWithCache.create(
        cacheOptions: SharedPreferencesWithCacheOptions());
    final existing = sp.getString('font_library');
    final fontLibrary = jsonDecode(existing ?? '{}');
    final fonts = List<String>.from(fontLibrary[type]['fonts'] ?? []);
    final name = fontLibrary[type]['name'] ?? type;
    loadFontsFromFiles(fonts, name);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(children: [
        Ink(
          width: 240,
          color: Colors.blueGrey,
          child: Column(
            children: [
              Expanded(
                child: FontTypeList(
                  onTapFontType: onTypeSelected,
                ),
              ),
              ListTile(
                title: Text(
                  "Settings",
                  style: TextStyle(
                    color: Colors.white,
                  ),
                ),
                onTap: () async {
                  final saved = await showDialog(
                      context: context,
                      builder: (context) {
                        return Dialog(
                          child: SetFavoriteDialog(),
                        );
                      });
                  if (saved ?? false) {
                    setState(() {});
                  }
                },
              )
            ],
          ),
        ),
        Expanded(
            child: FontPreviewContainer(
          fontFamilies: fontFamilies,
        )),
      ]),
    );
  }
}
