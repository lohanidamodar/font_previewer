import 'package:flutter/material.dart';
import 'package:font_previewer/widgets/font_preview_list.dart';

class FontPreviewContainer extends StatefulWidget {
  final Iterable<String> fontFamilies;
  const FontPreviewContainer({super.key, required this.fontFamilies});

  @override
  State<FontPreviewContainer> createState() => _FontPreviewContainerState();
}

class _FontPreviewContainerState extends State<FontPreviewContainer> {
  double fontSize = 20;
  String previewText = 'Namaste';

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            const SizedBox(width: 10.0),
            Expanded(
              child: TextField(
                decoration: InputDecoration(hintText: 'Type to preview'),
                onChanged: (value) {
                  setState(() {
                    previewText = value;
                  });
                },
              ),
            ),
            const SizedBox(width: 10.0),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  fontSize++;
                });
              },
              child: Icon(Icons.add),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  fontSize--;
                });
              },
              child: Icon(Icons.remove),
            ),
          ],
        ),
        const SizedBox(height: 10.0),
        Expanded(
            child: FontPreviewList(
          fontFamilies: widget.fontFamilies,
          previewText: previewText,
          fontSize: fontSize,
        ))
      ],
    );
  }
}
