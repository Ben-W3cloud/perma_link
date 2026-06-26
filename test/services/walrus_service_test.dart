import 'package:fluffy_link/services/walrus_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('extracts blob ID from newlyCreated response', () {
    final blobId = WalrusService.extractBlobId({
      'newlyCreated': {
        'blobObject': {'blobId': 'new-blob'},
      },
    });

    expect(blobId, 'new-blob');
  });

  test('extracts blob ID from alreadyCertified response', () {
    final blobId = WalrusService.extractBlobId({
      'alreadyCertified': {'blobId': 'existing-blob'},
    });

    expect(blobId, 'existing-blob');
  });

  test('throws when response has no blob ID', () {
    expect(
      () => WalrusService.extractBlobId({}),
      throwsA(isA<WalrusUploadException>()),
    );
  });
}
