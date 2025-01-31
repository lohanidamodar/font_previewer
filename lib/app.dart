import 'package:flutter/material.dart';
import 'package:font_previewer/screens/home_desktop.dart';

class FontPreviewApp extends StatelessWidget {
  const FontPreviewApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Font preview",
      home: HomeDesktopScreen(),
    );
  }
}
