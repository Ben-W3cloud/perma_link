import 'dart:convert';

import 'package:fluffy_link/core/constants.dart';
import 'package:fluffy_link/models/link_model.dart';
import 'package:fluffy_link/screens/home/widgets/success_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UploadHistoryEntry {
  const UploadHistoryEntry({
    required this.shortCode,
    required this.blobId,
    required this.fileName,
    required this.fileSize,
    required this.mimeType,
    required this.uploadedAt,
  });

  final String shortCode;
  final String blobId;
  final String fileName;
  final int fileSize;
  final String mimeType;
  final DateTime uploadedAt;

  String get shortUrl {
    final domain = AppConstants.appDomain.endsWith('/')
        ? AppConstants.appDomain.substring(0, AppConstants.appDomain.length - 1)
        : AppConstants.appDomain;
    return '$domain/$shortCode';
  }

  String get walrusUrl =>
      '${AppConstants.walrusAggregator}/v1/blobs/$blobId';

  Map<String, dynamic> toJson() => {
        'shortCode': shortCode,
        'blobId': blobId,
        'fileName': fileName,
        'fileSize': fileSize,
        'mimeType': mimeType,
        'uploadedAt': uploadedAt.toIso8601String(),
      };

  factory UploadHistoryEntry.fromJson(Map<String, dynamic> json) {
    return UploadHistoryEntry(
      shortCode: json['shortCode'] as String,
      blobId: json['blobId'] as String,
      fileName: json['fileName'] as String,
      fileSize: (json['fileSize'] as num).toInt(),
      mimeType: json['mimeType'] as String,
      uploadedAt: DateTime.parse(json['uploadedAt'] as String),
    );
  }
}

class UploadHistoryService {
  UploadHistoryService({this.maxEntries = 10});

  static const String _key = 'upload_history';
  final int maxEntries;

  Future<List<UploadHistoryEntry>> recent() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .cast<Map<String, dynamic>>()
          .map(UploadHistoryEntry.fromJson)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> add(LinkModel link, UploadMetadata meta) async {
    final entry = UploadHistoryEntry(
      shortCode: link.shortCode,
      blobId: link.blobId,
      fileName: meta.fileName,
      fileSize: meta.fileSize,
      mimeType: meta.mimeType,
      uploadedAt: meta.uploadedAt,
    );

    final existing = await recent();
    final next = <UploadHistoryEntry>[entry, ...existing.where((e) => e.shortCode != entry.shortCode)];
    final trimmed = next.take(maxEntries).toList();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode(trimmed.map((e) => e.toJson()).toList()),
    );
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
