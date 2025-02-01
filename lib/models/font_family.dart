class FontFamily {
  final String name;
  final String path;
  final bool isLocal;

  FontFamily({
    required this.name,
    required this.path,
    this.isLocal = true,
  });
}
