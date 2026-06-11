class FileUtils {
  const FileUtils._();

  static const Map<String, String> _mimeByExtension = {
    'png': 'image/png',
    'jpg': 'image/jpeg',
    'jpeg': 'image/jpeg',
    'gif': 'image/gif',
    'webp': 'image/webp',
    'svg': 'image/svg+xml',
    'pdf': 'application/pdf',
    'txt': 'text/plain',
    'html': 'text/html',
    'htm': 'text/html',
    'css': 'text/css',
    'js': 'text/javascript',
    'json': 'application/json',
    'xml': 'application/xml',
    'zip': 'application/zip',
    'gz': 'application/gzip',
    'tar': 'application/x-tar',
    'mp4': 'video/mp4',
    'mp3': 'audio/mpeg',
    'wav': 'audio/wav',
    'wasm': 'application/wasm',
    'md': 'text/markdown',
    'csv': 'text/csv',
  };

  static String mimeFromExtension(String? ext) {
    if (ext == null || ext.isEmpty) return 'application/octet-stream';
    return _mimeByExtension[ext.toLowerCase()] ?? 'application/octet-stream';
  }

  static String formatBytes(int bytes) {
    if (bytes < 0) {
      throw ArgumentError.value(bytes, 'bytes', 'Must not be negative.');
    }
    if (bytes < 1024) return '$bytes B';

    final kb = bytes / 1024;
    if (kb < 1024) return '${kb.toStringAsFixed(1)} KB';

    final mb = kb / 1024;
    if (mb < 1024) return '${mb.toStringAsFixed(1)} MB';

    final gb = mb / 1024;
    return '${gb.toStringAsFixed(1)} GB';
  }
}
