import 'package:dartus/dartus.dart';
import 'package:fluffy_link/core/utils/error_messages.dart';
import 'package:fluffy_link/services/walrus_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test('maps upload errors to human-readable messages', () {
    expect(
      ErrorMessages.forUpload(const WalrusUploadException('custom')),
      'custom',
    );
    expect(
      ErrorMessages.forUpload(PostgrestException(message: 'db', code: '500')),
      'Failed to save your link. Try again.',
    );
    expect(
      ErrorMessages.forUpload(
        WalrusApiError(code: 503, status: 'SERVER_ERROR', message: 'down'),
      ),
      'Storage service unavailable. Try again in a moment.',
    );
    expect(
      ErrorMessages.forUpload(Exception('unknown')),
      'Something went wrong. Try again.',
    );
  });

  test('maps redirect errors to human-readable messages', () {
    expect(
      ErrorMessages.forRedirect(PostgrestException(message: 'db', code: '500')),
      'Failed to resolve this link. Try again.',
    );
    expect(
      ErrorMessages.forRedirect(Exception('unknown')),
      'Something went wrong. Try again.',
    );
  });
}
