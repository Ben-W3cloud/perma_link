import 'package:fluffy_link/models/link_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses a Supabase link row', () {
    final createdAt = DateTime.utc(2026, 6);
    final link = LinkModel.fromJson({
      'id': 'ee51f4b2-066e-48ac-a0d5-6f674e0b0fd9',
      'short_code': 'abc123',
      'blob_id': 'blob-id',
      'file_name': 'photo.png',
      'file_size': '2048',
      'click_count': 4,
      'created_at': createdAt.toIso8601String(),
    });

    expect(link.shortCode, 'abc123');
    expect(link.fileSize, 2048);
    expect(link.clickCount, 4);
    expect(link.shortUrl, 'https://perma.link/abc123');
    expect(link.statsUrl, 'https://perma.link/s/abc123');
    expect(
      link.walrusUrl,
      'https://aggregator.walrus-testnet.walrus.space/v1/blob-id',
    );
  });
}
