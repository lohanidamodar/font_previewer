import 'package:flutter/material.dart';

typedef OnTapFontType = Function(String);

class FontTypeList extends StatefulWidget {
  final OnTapFontType onTapFontType;
  const FontTypeList({super.key, required this.onTapFontType});

  @override
  State<FontTypeList> createState() => _FontTypeListState();
}

class _FontTypeListState extends State<FontTypeList> {
  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        ListTile(
          title: Text("Google fonts"),
          onTap: () => widget.onTapFontType('google'),
        ),
        Center(
          child: ElevatedButton(onPressed: () {}, child: Text("Add my fonts")),
        ),
      ],
    );
  }
}
