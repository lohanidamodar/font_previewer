class FontFamily {
  final String name;
  final String path;
  final bool isLocal;
  // Added loadFont callback for lazy loading
  final Future<void> Function()? loadFont;

  FontFamily({
    required this.name,
    required this.path,
    required this.isLocal,
    this.loadFont,
  });
}
