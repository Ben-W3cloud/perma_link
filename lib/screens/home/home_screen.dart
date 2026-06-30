import 'package:file_picker/file_picker.dart';
import 'package:fluffy_link/core/constants.dart';
import 'package:fluffy_link/core/page_scaffold.dart';
import 'package:fluffy_link/core/theme.dart';
import 'package:fluffy_link/core/utils/error_messages.dart';
import 'package:fluffy_link/core/utils/file_utils.dart';
import 'package:fluffy_link/models/link_model.dart';
import 'package:fluffy_link/screens/home/widgets/drop_zone.dart';
import 'package:fluffy_link/screens/home/widgets/error_card.dart';
import 'package:fluffy_link/screens/home/widgets/success_card.dart';
import 'package:fluffy_link/screens/home/widgets/upload_progress.dart';
import 'package:fluffy_link/services/link_service.dart';
import 'package:fluffy_link/services/upload_history_service.dart';
import 'package:fluffy_link/services/auth_service.dart';
import 'package:fluffy_link/services/walrus_service.dart';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:fluffy_link/screens/home/widgets/animated_grid_background.dart';
import 'package:fluffy_link/screens/home/widgets/recent_uploads_panel.dart';
import 'package:go_router/go_router.dart';

enum UploadState { idle, uploading, done, error }

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    WalrusService? walrusService,
    LinkService? linkService,
    UploadHistoryService? historyService,
  }) : _walrusService = walrusService,
       _linkService = linkService,
       _historyService = historyService;

  final WalrusService? _walrusService;
  final LinkService? _linkService;
  final UploadHistoryService? _historyService;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final WalrusService _walrus = widget._walrusService ?? WalrusService();
  late final LinkService _links = widget._linkService ?? LinkService();
  late final UploadHistoryService _history =
      widget._historyService ?? UploadHistoryService();

  UploadState _state = UploadState.idle;
  UploadPhase _phase = UploadPhase.walrus;
  String? _errorMessage;
  LinkModel? _createdLink;
  UploadMetadata? _uploadMetadata;
  String _uploadingFileName = '';
  List<UploadHistoryEntry> _recentUploads = const [];

  @override
  void initState() {
    super.initState();
    _checkAuthAndRedirect();
    _refreshQuotaAndHistory();
  }

  Future<void> _checkAuthAndRedirect() async {
    final auth = AuthScope.of(context);
    if (!auth.isInitialized) await auth.initialize();
    if (auth.currentUser == null && mounted) {
      final from = Uri.encodeComponent('/upload');
      context.go('/auth?redirect=$from');
    }
  }

  Future<void> _refreshQuotaAndHistory() async {
    final history = await _history.recent();
    if (!mounted) return;
    setState(() {
      _recentUploads = history;
    });
  }

  Future<void> _handleFilePick() async {
    developer.log('Opening file picker', name: 'HomeScreen._handleFilePick');
    final result = await FilePicker.platform.pickFiles(withData: true);
    if (result == null || result.files.isEmpty) return;
    developer.log(
      'File selected from picker',
      name: 'HomeScreen._handleFilePick',
      error: {'name': result.files.first.name, 'size': result.files.first.size},
    );
    await _upload(result.files.first);
  }

  Future<void> _upload(PlatformFile file) async {
    final user = AuthScope.of(context).currentUser;
    if (user == null) {
      context.go('/auth?redirect=${Uri.encodeComponent('/upload')}');
      return;
    }

    final bytes = file.bytes;
    if (bytes == null) {
      developer.log(
        'File bytes null',
        name: 'HomeScreen._upload',
        error: {'file': file.name},
      );
      _showError('Could not read the selected file.');
      return;
    }

    if (file.size > AppConstants.maxFileSizeBytes) {
      developer.log(
        'File too large',
        name: 'HomeScreen._upload',
        error: {'file': file.name, 'size': file.size},
      );
      _showError('File must be under 10MB');
      return;
    }

    setState(() {
      _state = UploadState.uploading;
      _phase = UploadPhase.walrus;
      _errorMessage = null;
      _uploadingFileName = file.name;
    });

    developer.log(
      'Starting upload flow',
      name: 'HomeScreen._upload',
      error: {'file': file.name, 'size': file.size},
    );
    developer.log(
      'Phase set to walrus',
      name: 'HomeScreen._upload',
      error: {'phase': _phase.toString()},
    );
    try {
      developer.log(
        'Calling WalrusService.uploadBlob',
        name: 'HomeScreen._upload',
      );
      final blobId = await _walrus.uploadBlob(bytes);
      developer.log(
        'Walrus.uploadBlob returned',
        name: 'HomeScreen._upload',
        error: {'blobId': blobId},
      );

      if (!mounted) return;
      setState(() => _phase = UploadPhase.saving);
      developer.log(
        'Phase set to saving',
        name: 'HomeScreen._upload',
        error: {'phase': _phase.toString()},
      );

      developer.log(
        'Calling LinkService.createLink',
        name: 'HomeScreen._upload',
        error: {'blobId': blobId},
      );

      final link = await _links.createLink(
        blobId: blobId,
        fileName: file.name,
        fileSize: file.size,
        userId: user.id,
      );
      developer.log(
        'LinkService.createLink returned',
        name: 'HomeScreen._upload',
        error: link.toString(),
      );

      if (!mounted) return;
      final metadata = UploadMetadata(
        fileName: file.name,
        fileSize: file.size,
        mimeType: FileUtils.mimeFromExtension(file.extension),
        uploadedAt: DateTime.now(),
      );
      setState(() {
        _state = UploadState.done;
        _createdLink = link;
        _uploadMetadata = metadata;
      });
      await _history.add(link, metadata);
      await _refreshQuotaAndHistory();
    } catch (error, stack) {
      if (!mounted) return;
      developer.log(
        'Home upload error',
        name: 'HomeScreen._upload',
        error: error,
        stackTrace: stack,
      );
      _showError(ErrorMessages.forUpload(error));
    }
  }

  void _showError(String message) {
    setState(() {
      _state = UploadState.error;
      _errorMessage = message;
    });
  }

  void _reset() {
    setState(() {
      _state = UploadState.idle;
      _createdLink = null;
      _uploadMetadata = null;
      _errorMessage = null;
      _phase = UploadPhase.walrus;
      _uploadingFileName = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      currentRoute: '/upload',
      maxContentWidth: 560,
      scrollable: true,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          const Positioned.fill(child: AnimatedGridBackground()),
          LayoutBuilder(
            builder: (context, constraints) {
              final body = switch (_state) {
                UploadState.idle => _UploadPicker(
                  onBrowse: _handleFilePick,
                  onFileDrop: _upload,
                  recentUploads: _recentUploads,
                ),
                UploadState.uploading => UploadProgress(
                  fileName: _uploadingFileName,
                  phase: _phase,
                ),
                UploadState.done => SuccessCard(
                  link: _createdLink!,
                  metadata: _uploadMetadata!,
                  onReset: _reset,
                ),
                UploadState.error => ErrorCard(
                  message: _errorMessage ?? 'Something went wrong. Try again.',
                  onRetry: _reset,
                ),
              };

              return ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 620),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spaceMd,
                    vertical: AppTheme.spaceLg,
                  ),
                  child: Center(child: body),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _walrus.dispose();
    super.dispose();
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// UPLOAD PICKER (idle state)
// ═══════════════════════════════════════════════════════════════════════════

class _UploadPicker extends StatelessWidget {
  const _UploadPicker({
    required this.onBrowse,
    required this.onFileDrop,
    required this.recentUploads,
  });

  final VoidCallback onBrowse;
  final Future<void> Function(PlatformFile file) onFileDrop;
  final List<UploadHistoryEntry> recentUploads;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const _EnhancedLogo(),
        const SizedBox(height: 24),
        _EnhancedDropZone(onFileDrop: onFileDrop),
        const SizedBox(height: 20),
        _GhostBrowseButton(onBrowse: onBrowse),
        const SizedBox(height: 12),
        const _TrustBadges(),
        RecentUploadsPanel(entries: recentUploads),
      ],
    );
  }
}

class _EnhancedLogo extends StatefulWidget {
  const _EnhancedLogo();

  @override
  State<_EnhancedLogo> createState() => _EnhancedLogoState();
}

class _EnhancedLogoState extends State<_EnhancedLogo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final scale = 1.0 + (_controller.value * 0.03);
        final glow = _controller.value * 0.2;

        return Transform.scale(
          scale: scale,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: AppTheme.primaryGradient,
              boxShadow: AppTheme.glowShadow(opacity: 0.4 + glow, blur: 36),
            ),
            child: const Icon(
              Icons.link_rounded,
              size: 36,
              color: Colors.white,
            ),
          ),
        );
      },
    );
  }
}

class _EnhancedDropZone extends StatefulWidget {
  const _EnhancedDropZone({required this.onFileDrop});

  final Future<void> Function(PlatformFile file) onFileDrop;

  @override
  State<_EnhancedDropZone> createState() => _EnhancedDropZoneState();
}

class _EnhancedDropZoneState extends State<_EnhancedDropZone>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _setDragging(true),
      onExit: (_) => _setDragging(false),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height: 180,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: _isDragging
                  ? [
                      AppTheme.primary.withValues(alpha: 0.15),
                      AppTheme.accent.withValues(alpha: 0.1),
                    ]
                  : [
                      AppTheme.surface.withValues(alpha: 0.8),
                      AppTheme.surfaceAlt.withValues(alpha: 0.6),
                    ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: _isDragging
                  ? AppTheme.accent.withValues(alpha: 0.6)
                  : AppTheme.border.withValues(alpha: 0.3),
              width: 2,
            ),
            boxShadow: _isDragging
                ? AppTheme.glowShadow(opacity: 0.15, blur: 20)
                : AppTheme.glowShadow(opacity: 0.15, blur: 24),
          ),
          child: DropZone(onFileDrop: widget.onFileDrop),
        ),
      ),
    );
  }

  void _setDragging(bool hovering) {
    setState(() => _isDragging = hovering);
    if (hovering) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }
}

class _GhostBrowseButton extends StatelessWidget {
  const _GhostBrowseButton({required this.onBrowse});

  final VoidCallback onBrowse;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onBrowse,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          decoration: BoxDecoration(
            color: AppTheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(13),
            border: Border.all(
              color: AppTheme.primary.withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.folder_open_outlined,
                size: 18,
                color: AppTheme.primary,
              ),
              const SizedBox(width: 10),
              Text(
                'Browse files',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TrustBadges extends StatelessWidget {
  const _TrustBadges();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _TrustBadge(icon: Icons.lock, label: '10 MB max'),
            const SizedBox(width: 16),
            _TrustBadge(icon: Icons.cloud_queue, label: 'Walrus decentralized'),
            const SizedBox(width: 16),
            _TrustBadge(icon: Icons.verified_user, label: 'Account required'),
            const SizedBox(width: 16),
            _TrustBadge(
              icon: Icons.timer_outlined,
              label: 'Quota enforced by Supabase',
            ),
          ],
        ),
      ),
    );
  }
}

class _TrustBadge extends StatelessWidget {
  const _TrustBadge({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    const accent = AppTheme.primary;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.surface.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.border.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: accent),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.muted,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
