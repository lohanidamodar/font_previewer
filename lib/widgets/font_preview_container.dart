import 'dart:io';

import 'package:flutter/material.dart';
import 'package:font_previewer/models/font_family.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path/path.dart' as path;
import 'package:url_launcher/url_launcher.dart';

class FontPreviewContainer extends StatefulWidget {
  final List<FontFamily> fontFamilies;

  const FontPreviewContainer({super.key, required this.fontFamilies});

  @override
  State<FontPreviewContainer> createState() => _FontPreviewContainerState();
}

class _FontPreviewContainerState extends State<FontPreviewContainer> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  final _sampleTextController = TextEditingController(
      text: "The quick brown fox jumps over the lazy dog");
  List<FontFamily> _filteredFonts = [];
  String _sampleText = "The quick brown fox jumps over the lazy dog";
  double _fontSize = 16.0;

  @override
  void initState() {
    super.initState();
    _filteredFonts = widget.fontFamilies;
  }

  @override
  void didUpdateWidget(covariant FontPreviewContainer oldWidget) {
    super.didUpdateWidget(oldWidget);
    _filteredFonts = widget.fontFamilies;
  }

  void _filterFonts(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredFonts = widget.fontFamilies;
      } else {
        _filteredFonts = widget.fontFamilies
            .where(
                (font) => font.name.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  void _openGoogleFontsUrl(String fontName) async {
    final url = Uri.parse('https://fonts.google.com/specimen/$fontName');
    if (!await launchUrl(url)) {
      debugPrint('Could not launch $url');
    }
  }

  void _openLocalFontLocation(String fontPath) async {
    try {
      final directory = path.dirname(fontPath);
      if (Platform.isWindows) {
        await Process.run('explorer', [directory]);
      } else if (Platform.isMacOS) {
        await Process.run('open', [directory]);
      } else if (Platform.isLinux) {
        await Process.run('xdg-open', [directory]);
      }
    } catch (e) {
      debugPrint('Error opening font location: $e');
    }
  }

  void _increaseFontSize() {
    setState(() {
      _fontSize += 2.0;
    });
  }

  void _decreaseFontSize() {
    setState(() {
      if (_fontSize > 6.0) {
        _fontSize -= 2.0;
      }
    });
  }

  String _getDisplayName(FontFamily font) {
    if (font.isLocal) {
      // Extract file name without extension for local fonts
      return path.basenameWithoutExtension(font.path);
    } else {
      return font.name;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            controller: _searchController,
            onChanged: _filterFonts,
            decoration: const InputDecoration(
              labelText: "Search Fonts",
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _sampleTextController,
                  onChanged: (text) {
                    setState(() {
                      _sampleText = text;
                    });
                  },
                  decoration: const InputDecoration(
                    labelText: "Sample Text",
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.text_decrease),
                onPressed: _decreaseFontSize,
                tooltip: 'Decrease font size',
              ),
              Text(
                '${_fontSize.toInt()}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.text_increase),
                onPressed: _increaseFontSize,
                tooltip: 'Increase font size',
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            itemCount: _filteredFonts.length,
            itemBuilder: (context, index) {
              final font = _filteredFonts[index];
              // Load font on demand when it's about to be displayed
              if (font.isLocal && font.loadFont != null) {
                // Call loadFont just before displaying
                font.loadFont!();
              }

              final displayName = _getDisplayName(font);

              return ListTile(
                title: Row(
                  children: [
                    Expanded(
                      child: Text(
                        displayName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(
                      icon: Icon(font.isLocal ? Icons.folder_open : Icons.link),
                      onPressed: () {
                        if (font.isLocal) {
                          _openLocalFontLocation(font.path);
                        } else {
                          _openGoogleFontsUrl(font.name);
                        }
                      },
                      tooltip: font.isLocal
                          ? 'Open font location'
                          : 'View on Google Fonts',
                    ),
                  ],
                ),
                subtitle: Text(
                  _sampleText,
                  style: (font.isLocal
                      ? TextStyle(fontFamily: font.name, fontSize: _fontSize)
                      : GoogleFonts.getFont(font.name, fontSize: _fontSize)),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _sampleTextController.dispose();
    super.dispose();
  }
}
