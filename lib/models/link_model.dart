import 'package:fluffy_link/core/constants.dart';
import 'package:fluffy_link/core/utils/file_utils.dart';

class LinkModel {
  const LinkModel({
    required this.id,
    required this.shortCode,
    required this.blobId,
    this.fileName,
    this.fileSize,
    required this.clickCount,
    required this.createdAt,
    this.userId,
  });

  final String id;
  final String shortCode;
  final String blobId;
  final String? fileName;
  final int? fileSize;
  final int clickCount;
  final DateTime createdAt;
  final String? userId;

  factory LinkModel.fromJson(Map<String, dynamic> json) {
    return LinkModel(
      id: json['id'] as String,
      shortCode: json['short_code'] as String,
      blobId: json['blob_id'] as String,
      fileName: json['file_name'] as String?,
      fileSize: _readNullableInt(json['file_size']),
      clickCount: _readInt(json['click_count']) ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      userId: json['user_id'] as String?,
    );
  }

  // Extension-derived MIME — the DB doesn't store the original Content-Type,
  // so we infer from the filename. Phase 4 previews key off this.
  String get mimeType {
    final name = fileName;
    if (name == null) return 'application/octet-stream';
    final dot = name.lastIndexOf('.');
    if (dot < 0 || dot == name.length - 1) {
      return 'application/octet-stream';
    }
    return FileUtils.mimeFromExtension(name.substring(dot + 1));
  }

  String get _baseUrl {
    final domain = AppConstants.appDomain;
    return domain.endsWith('/')
        ? domain.substring(0, domain.length - 1)
        : domain;
  }

  String get shortUrl => '$_baseUrl/$shortCode';

  String get statsUrl => '$_baseUrl/s/$shortCode';

  String get walrusUrl => '${AppConstants.walrusAggregator}/v1/blobs/$blobId';

  static int? _readNullableInt(Object? value) => _readInt(value);

  static int? _readInt(Object? value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    throw FormatException('Expected an integer-compatible value, got $value.');
  }
}
