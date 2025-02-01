import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_previewer/models/font_family.dart';
import 'package:font_previewer/widgets/font_preview_container.dart';
import 'package:font_previewer/widgets/font_type_list.dart';
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
      default:
        loadFonts(type);
        break;
    }

    setState(() {});
  }

  loadFonts(String type) async {
    final sp = await SharedPreferencesWithCache.create(
        cacheOptions: SharedPreferencesWithCacheOptions());
    final existing = sp.getString('font_library');
    final fontLibrary = jsonDecode(existing ?? '{}');
    final fonts = List<String>.from(fontLibrary[type]['fonts'] ?? []);

    if (fonts.isEmpty) {
      return;
    }

    int index = 0;
    final name = fontLibrary[type]['name'] ?? type;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(children: [
        Container(
          width: 240,
          color: Colors.blueGrey,
          child: FontTypeList(
            onTapFontType: onTypeSelected,
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
