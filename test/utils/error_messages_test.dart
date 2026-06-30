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
      "We couldn't save your link. Please try again.",
    );
    expect(
      ErrorMessages.forUpload(
        PostgrestException(message: 'upload_limit_exceeded', code: 'P0001'),
      ),
      "You've reached the upload limit (7 uploads per day). Please try again later.",
    );
    expect(
      ErrorMessages.forUpload(
        PostgrestException(message: 'not_authenticated', code: 'P0001'),
      ),
      'Please sign in before uploading a file.',
    );
    expect(
      ErrorMessages.forUpload(
        WalrusApiError(code: 503, status: 'SERVER_ERROR', message: 'down'),
      ),
      'Storage service unavailable. Try again in a moment.',
    );
    expect(
      ErrorMessages.forUpload(Exception('unknown')),
      "We couldn't upload your file. Please try again.",
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
