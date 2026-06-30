import 'dart:async';
import 'dart:convert';
import 'package:fluffy_link/core/constants.dart';
import 'package:fluffy_link/core/theme.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

/// Shows Walrus storage epoch information for a given blob.
///
/// Displays the current network (testnet/mainnet), storage epoch info, and
/// a warning chip when storage is close to expiring.
class StorageStatusChip extends StatefulWidget {
  const StorageStatusChip({
    super.key,
    required this.blobId,
    required this.createdAt,
  });

  final String blobId;
  final DateTime createdAt;

  @override
  State<StorageStatusChip> createState() => _StorageStatusChipState();
}

class _StorageStatusChipState extends State<StorageStatusChip> {
  int? _currentEpoch;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchEpoch();
  }

  Future<void> _fetchEpoch() async {
    try {
      // Walrus testnet exposes the current epoch via a system info endpoint.
      // We probe the aggregator's root or a known info endpoint.
      // Fallback: if the endpoint doesn't exist, we calculate from storage constants.
      final response = await http
          .get(Uri.parse(AppConstants.walrusAggregator))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        try {
          final body = jsonDecode(response.body);
          final epoch = body['epoch'];
          if (epoch is int) {
            if (!mounted) return;
            setState(() {
              _currentEpoch = epoch;
              _loading = false;
            });
            return;
          }
        } catch (_) {
          // Body wasn't JSON or didn't contain epoch — fall through to fallback.
        }
      }
    } catch (_) {
      // Network error — use fallback.
    }

    // Fallback: estimate epoch from the blob's creation time.
    // Walrus testnet epochs are ~1 day. Storage is 3 epochs.
    if (!mounted) return;
    final now = DateTime.now().toUtc();
    final age = now.difference(widget.createdAt.toUtc());
    final estimatedEpoch = age.inDays;
    setState(() {
      _currentEpoch = estimatedEpoch;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const SizedBox.shrink();
    }

    final isTestnet = AppConstants.walrusPublisher.contains('testnet');
    final epoch = _currentEpoch;
    final storageEpochs = AppConstants.storageEpochs;

    // Estimate how many epochs have passed since upload.
    // We use days as a rough proxy for testnet epochs (~1 day each).
    final now = DateTime.now().toUtc();
    final age = now.difference(widget.createdAt.toUtc());
    final epochsElapsed = (age.inDays).clamp(0, storageEpochs);
    final epochsRemaining = (storageEpochs - epochsElapsed).clamp(
      0,
      storageEpochs,
    );
    final isExpiring = epochsRemaining <= 1;
    final isExpired = epochsRemaining <= 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(
          color: isExpired
              ? AppTheme.error.withValues(alpha: 0.4)
              : isExpiring
              ? Colors.amber.withValues(alpha: 0.4)
              : AppTheme.border.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isExpired
                ? Icons.error_outline_rounded
                : isExpiring
                ? Icons.warning_amber_rounded
                : Icons.cloud_done_outlined,
            size: 16,
            color: isExpired
                ? AppTheme.error
                : isExpiring
                ? Colors.amber
                : AppTheme.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isExpired
                      ? 'Storage expired'
                      : isExpiring
                      ? 'Storage expiring soon'
                      : 'Storage active',
                  style: TextStyle(
                    color: isExpired
                        ? AppTheme.error
                        : isExpiring
                        ? Colors.amber
                        : AppTheme.onSurface,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _storageDetail(epoch, epochsRemaining, isTestnet),
                  style: TextStyle(color: AppTheme.mutedDim, fontSize: 11),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: isTestnet
                  ? Colors.amber.withValues(alpha: 0.1)
                  : AppTheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusPill),
              border: Border.all(
                color: isTestnet
                    ? Colors.amber.withValues(alpha: 0.3)
                    : AppTheme.primary.withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              isTestnet ? 'TESTNET' : 'MAINNET',
              style: TextStyle(
                color: isTestnet ? Colors.amber : AppTheme.primary,
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _storageDetail(int? epoch, int remaining, bool isTestnet) {
    final epochLabelPlural = isTestnet ? 'days' : 'epochs';
    final total = AppConstants.storageEpochs;

    if (remaining <= 0) {
      return 'Stored for $total $epochLabelPlural — now expired';
    }
    return 'Epoch ${epoch ?? '?'} · $remaining of $total $epochLabelPlural remaining';
  }
}
