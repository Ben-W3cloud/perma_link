import 'dart:typed_data';
import 'package:dartus/dartus.dart';
import 'package:fluffy_link/core/constants.dart';

class WalrusUploadException implements Exception {
  const WalrusUploadException(this.message);

  final String message;

  @override
  String toString() => message;
}

class WalrusService {
  WalrusService({WalrusClient? client}) : _client = client ?? _createClient();

  final WalrusClient _client;

  static WalrusClient _createClient() {
    return WalrusClient(
      publisherBaseUrl: Uri.parse(AppConstants.walrusPublisher),
      aggregatorBaseUrl: Uri.parse(AppConstants.walrusAggregator),
      useSecureConnection: false,
      logLevel: WalrusLogLevel.warning,
    );
  }

  /// Uploads bytes to Walrus and returns the certified blob ID.
  Future<String> uploadBlob(List<int> bytes, {int retries = 2}) async {
    if (bytes.isEmpty) {
      throw const WalrusUploadException('Cannot upload an empty file.');
    }

    for (var attempt = 0; attempt <= retries; attempt++) {
      try {
        return await _doUpload(bytes);
      } on RetryableWalrusClientError {
        if (attempt == retries) break;
        await Future<void>.delayed(Duration(seconds: attempt + 1));
      } on WalrusApiError catch (error) {
        if (!_isRetryableApiError(error) || attempt == retries) break;
        await Future<void>.delayed(Duration(seconds: attempt + 1));
      } on FormatException {
        throw const WalrusUploadException(
          'Storage service unavailable. Try again in a moment.',
        );
      }
    }

    throw const WalrusUploadException(
      'Storage service unavailable. Try again in a moment.',
    );
  }

  Future<String> _doUpload(List<int> bytes) async {
    try {
      final response = await _client.putBlob(
        data: Uint8List.fromList(bytes),
        epochs: AppConstants.storageEpochs,
      );
      return extractBlobId(response);
    } catch (e, stackTrace) {
      print('UPLOAD ERROR TYPE: ${e.runtimeType}');
      print('UPLOAD ERROR: $e');
      print('STACK: $stackTrace');
      rethrow;
    }
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

    throw const FormatException('Walrus upload returned no blobId.');
  }

  Future<void> dispose() => _client.close();

  bool _isRetryableApiError(WalrusApiError error) {
    return error.code == 429 || error.code >= 500;
  }
}
