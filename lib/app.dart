import 'package:flutter/material.dart';
import 'package:font_previewer/screens/home_desktop.dart';

class FontPreviewApp extends StatelessWidget {
  const FontPreviewApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Font preview",
      theme: ThemeData.light().copyWith(
          listTileTheme: ListTileThemeData(
        selectedColor: Colors.amber,
        selectedTileColor: Colors.amber.withAlpha(30),
      )),
      home: HomeDesktopScreen(),
    );
  }
}
