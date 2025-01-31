import 'package:flutter/material.dart';
import 'package:font_previewer/widgets/font_preview_container.dart';
import 'package:font_previewer/widgets/font_preview_list.dart';
import 'package:font_previewer/widgets/font_type_list.dart';
import 'package:google_fonts/google_fonts.dart';

class HomeDesktopScreen extends StatefulWidget {
  const HomeDesktopScreen({super.key});

  @override
  State<HomeDesktopScreen> createState() => _HomeDesktopScreenState();
}

class _HomeDesktopScreenState extends State<HomeDesktopScreen> {
  List<String> fontFamilies = [];

  onTypeSelected(String type) {
    switch (type) {
      case 'google':
        fontFamilies = GoogleFonts.asMap().keys.toList();
        break;
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
