import 'package:flutter/material.dart';
import 'package:font_previewer/models/font_family.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:path/path.dart' as p;

class FontPreviewList extends StatelessWidget {
  final Iterable<FontFamily> fontFamilies;
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
          child: Row(
            children: [
              Tooltip(
                message: fontFamilies.elementAt(index).path,
                child: IconButton(
                    icon: Icon(Icons.info),
                    onPressed: () async {
                      final details = fontFamilies.elementAt(index);
                      if (details.isLocal) {
                        final path = details.path;

                        final dir = p.dirname(path);
                        launchUrl(Uri.parse(dir));
                      } else {
                        if (await canLaunchUrlString(
                            'https://fonts.google.com/specimen/${details.path}')) {
                          launchUrlString(
                              'https://fonts.google.com/specimen/${details.path}');
                        }
                      }
                    }),
              ),
              Expanded(
                child: Text(previewText,
                    softWrap: true,
                    style: fontFamilies.elementAt(index).isLocal
                        ? TextStyle(
                            fontSize: fontSize,
                            fontFamily: fontFamilies.elementAt(index).name,
                          )
                        : GoogleFonts.asMap()[
                                fontFamilies.elementAt(index).name]
                            ?.call()
                            .copyWith(fontSize: fontSize)),
              ),
            ],
          ),
        );
      },
    );
  }
}
