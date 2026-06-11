import 'dart:async';

import 'package:dartus/dartus.dart';
import 'package:fluffy_link/services/walrus_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ErrorMessages {
  ErrorMessages._();

  static String forUpload(Object error) {
    if (error is WalrusUploadException) {
      return error.message;
    }
    if (error is PostgrestException) {
      return 'Failed to save your link. Try again.';
    }
    if (error is TimeoutException || _isNetworkError(error)) {
      return 'Upload failed. Check your connection and try again.';
    }
    if (error is RetryableWalrusClientError || error is WalrusApiError) {
      return 'Storage service unavailable. Try again in a moment.';
    }
    return 'Something went wrong. Try again.';
  }

  static String forRedirect(Object error) {
    if (error is PostgrestException) {
      return 'Failed to resolve this link. Try again.';
    }
    if (error is TimeoutException || _isNetworkError(error)) {
      return 'Check your connection and try again.';
    }
    return 'Something went wrong. Try again.';
  }

  static bool _isNetworkError(Object error) {
    final type = error.runtimeType.toString();
    return type.contains('SocketException') ||
        type.contains('ClientException') ||
        type.contains('NetworkException');
  }
}
