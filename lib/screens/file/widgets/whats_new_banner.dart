import 'package:fluffy_link/core/theme.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// One-time banner shown on the file page after we switched /:code from an
// instant Walrus redirect to a full file page. Dismissed via SharedPreferences
// so we don't keep nagging returning users.
class WhatsNewBanner extends StatefulWidget {
  const WhatsNewBanner({super.key});

  static const String _prefsKey = 'permalink.fileUx.bannerDismissed_v1';

  @override
  State<WhatsNewBanner> createState() => _WhatsNewBannerState();
}

class _WhatsNewBannerState extends State<WhatsNewBanner> {
  bool _ready = false;
  bool _dismissed = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dismissed = prefs.getBool(WhatsNewBanner._prefsKey) ?? false;
      if (!mounted) return;
      setState(() {
        _dismissed = dismissed;
        _ready = true;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _ready = true);
    }
  }

  Future<void> _dismiss() async {
    setState(() => _dismissed = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(WhatsNewBanner._prefsKey, true);
    } catch (_) {
      // Swallow — at worst the banner reappears next session.
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready || _dismissed) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.auto_awesome_rounded, size: 18, color: AppTheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text.rich(
              TextSpan(
                style: TextStyle(color: AppTheme.onSurface, fontSize: 13),
                children: const [
                  TextSpan(text: 'New: short links open a file page now. '),
                  TextSpan(
                    text: 'Tap View to open the file, or append ?download=1 '
                        'to auto-download.',
                    style: TextStyle(color: AppTheme.muted),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'Dismiss',
            icon: const Icon(Icons.close_rounded, size: 18),
            onPressed: _dismiss,
          ),
        ],
      ),
    );
  }
}
