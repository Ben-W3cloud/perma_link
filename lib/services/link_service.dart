import 'dart:async';
import 'dart:developer' as developer;

import 'package:fluffy_link/core/utils/code_generator.dart';
import 'package:fluffy_link/models/link_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LinkService {
  LinkService({SupabaseClient? client}) : _client = client;

  final SupabaseClient? _client;

  // Defer Supabase.instance access so widget/unit tests can build the UI before
  // real SUPABASE_URL and SUPABASE_ANON_KEY values exist.
  SupabaseClient get _supabase => _client ?? Supabase.instance.client;

  /// Inserts a new link row and returns the created link.
  Future<LinkModel> createLink({
    required String blobId,
    String? fileName,
    int? fileSize,
    String? userId,
  }) async {
    developer.log(
      'createLink called',
      name: 'LinkService.createLink',
      error: {'blobId': blobId, 'fileName': fileName, 'fileSize': fileSize},
    );
    for (var attempt = 0; attempt < 3; attempt++) {
      final code = CodeGenerator.generate();

      developer.log(
        'Attempting to insert link row',
        name: 'LinkService.createLink',
        error: {'attempt': attempt + 1, 'code': code},
      );

      try {
        if (userId == null || userId.isEmpty) {
          throw const AuthException('You must be signed in to upload files.');
        }

        final data = await _supabase.rpc<Map<String, dynamic>>(
          'create_link_with_quota',
          params: {
            'p_short_code': code,
            'p_blob_id': blobId,
            'p_file_name': fileName,
            'p_file_size': fileSize,
          },
        );

        developer.log(
          'Link inserted',
          name: 'LinkService.createLink',
          error: data,
        );
        return LinkModel.fromJson(data);
      } on PostgrestException catch (error) {
        developer.log(
          'PostgrestException during createLink',
          name: 'LinkService.createLink',
          error: {
            'code': error.code,
            'message': error.message,
            'details': error.details,
          },
        );
        // PostgreSQL 23505 is unique_violation; retry with a new shortcode.
        if (error.code == '23505' && attempt < 2) {
          developer.log(
            'Unique violation, retrying with new code',
            name: 'LinkService.createLink',
            error: {'attempt': attempt + 1},
          );
          continue;
        }
        rethrow;
      }
    }

    throw StateError('Failed to generate a unique short code.');
  }

  /// Looks up a link by shortcode and records a click without blocking redirect.
  Future<LinkModel?> resolveAndTrack(String shortCode) async {
    developer.log(
      'resolveAndTrack called with code: $shortCode',
      name: 'LinkService',
    );

    try {
      final data = await _supabase
          .from('links')
          .select()
          .eq('short_code', shortCode)
          .maybeSingle();

      if (data == null) {
        developer.log(
          'resolveAndTrack: No link found',
          name: 'LinkService',
          error: {'code': shortCode},
        );
        return null;
      }

      unawaitedClickIncrement(shortCode);
      return LinkModel.fromJson(data);
    } catch (e) {
      developer.log('resolveAndTrack error', name: 'LinkService', error: e);
      rethrow;
    }
  }

  /// Fetches the current link row for the stats page.
  Future<LinkModel?> getLinkStats(String shortCode) async {
    developer.log(
      'getLinkStats called with code: $shortCode',
      name: 'LinkService',
    );

    try {
      final data = await _supabase
          .from('links')
          .select()
          .eq('short_code', shortCode)
          .maybeSingle();

      if (data == null) {
        developer.log(
          'getLinkStats: No link found',
          name: 'LinkService',
          error: {'code': shortCode},
        );
        return null;
      }
      return LinkModel.fromJson(data);
    } catch (e) {
      developer.log('getLinkStats error', name: 'LinkService', error: e);
      rethrow;
    }
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

  /// Returns the current user's links, newest first.
  /// RLS allows public read so we filter explicitly by user_id here.
  /// Supports pagination via [limit] and [offset].
  Future<List<LinkModel>> listMine({
    required String userId,
    int limit = 100,
    int offset = 0,
  }) async {
    developer.log(
      'listMine called',
      name: 'LinkService',
      error: {'userId': userId, 'limit': limit, 'offset': offset},
    );
    final rows = await _supabase
        .from('links')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1)
        .limit(limit);
    return (rows as List)
        .cast<Map<String, dynamic>>()
        .map(LinkModel.fromJson)
        .toList();
  }

  /// Deletes a link by short code. RLS enforces that only the owner can
  /// delete; for non-owners this completes silently with zero rows affected.
  Future<void> deleteLink(String shortCode) async {
    developer.log(
      'deleteLink called',
      name: 'LinkService',
      error: {'shortCode': shortCode},
    );
    await _supabase.from('links').delete().eq('short_code', shortCode);
  }
}
