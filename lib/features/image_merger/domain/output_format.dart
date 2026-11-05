enum OutputFormat {
  png('png', 'image/png', 'PNG'),
  pdf('pdf', 'application/pdf', 'PDF');

  const OutputFormat(this.extension, this.mimeType, this.label);

  /// 파일 확장자이자 DB에 쓰는 값.
  final String extension;
  final String mimeType;
  final String label;

  static OutputFormat fromCode(String code) =>
      values.firstWhere((f) => f.extension == code, orElse: () => png);
}
