// Stub implementation for non-web platforms.
Future<bool> downloadFile({
  required String url,
  required String filename,
  String? mimeType,
}) async {
  return false;
}
