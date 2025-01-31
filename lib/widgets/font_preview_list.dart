import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class FontPreviewList extends StatelessWidget {
  final Iterable<String> fontFamilies;
  final String previewText;
  final double fontSize;
  const FontPreviewList(
      {super.key,
      required this.fontFamilies,
      required this.previewText,
      this.fontSize = 21});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: fontFamilies.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            previewText,
            softWrap: true,
            style: GoogleFonts.asMap()[fontFamilies.elementAt(index)]
                ?.call()
                .copyWith(fontSize: fontSize),
          ),
        );
      },
    );
  }
}
