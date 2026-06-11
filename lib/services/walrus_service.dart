import 'dart:typed_data';
import 'dart:convert';
import 'package:dartus/dartus.dart';
import 'dart:developer' as developer;
import 'package:fluffy_link/core/constants.dart';
import 'package:http/http.dart' as http;

class WalrusUploadException implements Exception {
  const WalrusUploadException(this.message);
  final String message;
  @override
  String toString() => message;
}

class WalrusService {
  final http.Client _httpClient;

  WalrusService({http.Client? httpClient})
    : _httpClient = httpClient ?? http.Client();

  Future<String> uploadBlob(List<int> bytes, {int retries = 2}) async {
    if (bytes.isEmpty) {
      throw const WalrusUploadException('Cannot upload an empty file.');
    }

    for (var attempt = 0; attempt <= retries; attempt++) {
      try {
        return await _doUpload(bytes);
      } catch (e) {
        developer.log(
          'Upload attempt failed',
          error: e,
          name: 'WalrusService.uploadBlob',
        );
        if (attempt == retries) rethrow;
        await Future<void>.delayed(Duration(seconds: attempt + 1));
      }
    }

    throw const WalrusUploadException(
      'Storage service unavailable. Try again in a moment.',
    );
  }

  Future<String> _doUpload(List<int> bytes) async {
    final uri = Uri.parse(
      '${AppConstants.walrusPublisher}/v1/blobs?epochs=${AppConstants.storageEpochs}',
    );

    final response = await _httpClient.put(
      uri,
      headers: {'Content-Type': 'application/octet-stream'},
      body: Uint8List.fromList(bytes),
    );

    if (response.statusCode != 200) {
      throw WalrusUploadException(
        'Upload failed with status ${response.statusCode}.',
      );
    }

    final jsonMap = jsonDecode(response.body) as Map<String, dynamic>;
    return extractBlobId(jsonMap);
  }

  static String extractBlobId(Map<String, dynamic> response) {
    final newlyCreated = response['newlyCreated'];
    if (newlyCreated is Map<String, dynamic>) {
      final blobObject = newlyCreated['blobObject'];
      if (blobObject is Map<String, dynamic>) {
        final blobId = blobObject['blobId'];
        if (blobId is String && blobId.isNotEmpty) return blobId;
      }
    }

    final alreadyCertified = response['alreadyCertified'];
    if (alreadyCertified is Map<String, dynamic>) {
      final blobId = alreadyCertified['blobId'];
      if (blobId is String && blobId.isNotEmpty) return blobId;
    }

    throw const WalrusUploadException(
      'Upload succeeded but no blob ID was returned.',
    );
  }

  Future<void> dispose() async => _httpClient.close();
}
