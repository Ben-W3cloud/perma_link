import 'dart:async';

import 'package:fluffy_link/core/utils/code_generator.dart';
import 'package:fluffy_link/models/link_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LinkService {
  LinkService({SupabaseClient? client}) : _client = client;

  final SupabaseClient? _client;

  // TODO(production): add rate limiting before public launch. Supabase free tier
  // has bandwidth limits and the anon key is exposed in the compiled bundle.

  // Defer Supabase.instance access so widget/unit tests can build the UI before
  // real SUPABASE_URL and SUPABASE_ANON_KEY values exist.
  SupabaseClient get _supabase => _client ?? Supabase.instance.client;

  /// Inserts a new link row and returns the created link.
  Future<LinkModel> createLink({
    required String blobId,
    String? fileName,
    int? fileSize,
  }) async {
    for (var attempt = 0; attempt < 3; attempt++) {
      final code = CodeGenerator.generate();

      try {
        final data = await _supabase
            .from('links')
            .insert({
              'short_code': code,
              'blob_id': blobId,
              'file_name': fileName,
              'file_size': fileSize,
            })
            .select()
            .single();

        return LinkModel.fromJson(data);
      } on PostgrestException catch (error) {
        // PostgreSQL 23505 is unique_violation; retry with a new shortcode.
        if (error.code == '23505' && attempt < 2) continue;
        rethrow;
      }
    }

    throw StateError('Failed to generate a unique short code.');
  }

  /// Looks up a link by shortcode and records a click without blocking redirect.
  Future<LinkModel?> resolveAndTrack(String shortCode) async {
    final data = await _supabase
        .from('links')
        .select()
        .eq('short_code', shortCode)
        .maybeSingle();

    if (data == null) return null;

    unawaitedClickIncrement(shortCode);
    return LinkModel.fromJson(data);
  }

  /// Fetches the current link row for the stats page.
  Future<LinkModel?> getLinkStats(String shortCode) async {
    final data = await _supabase
        .from('links')
        .select()
        .eq('short_code', shortCode)
        .maybeSingle();

    if (data == null) return null;
    return LinkModel.fromJson(data);
  }

  void unawaitedClickIncrement(String shortCode) {
    // Analytics should not block redirects, so failures are intentionally
    // swallowed after the RPC is started.
    unawaited(
      _supabase
          .rpc<void>('increment_click_count', params: {'code': shortCode})
          .catchError((Object _) {}),
    );
  }
}
