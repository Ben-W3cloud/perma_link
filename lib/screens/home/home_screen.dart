import 'package:file_picker/file_picker.dart';
import 'package:fluffy_link/core/constants.dart';
import 'package:fluffy_link/core/utils/error_messages.dart';
import 'package:fluffy_link/core/utils/file_utils.dart';
import 'package:fluffy_link/models/link_model.dart';
import 'package:fluffy_link/screens/home/widgets/drop_zone.dart';
import 'package:fluffy_link/screens/home/widgets/error_card.dart';
import 'package:fluffy_link/screens/home/widgets/success_card.dart';
import 'package:fluffy_link/screens/home/widgets/upload_progress.dart';
import 'package:fluffy_link/services/link_service.dart';
import 'package:fluffy_link/services/walrus_service.dart';
import 'package:flutter/material.dart';

enum UploadState { idle, uploading, done, error }

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    WalrusService? walrusService,
    LinkService? linkService,
  }) : _walrusService = walrusService,
       _linkService = linkService;

  final WalrusService? _walrusService;
  final LinkService? _linkService;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final WalrusService _walrus = widget._walrusService ?? WalrusService();
  late final LinkService _links = widget._linkService ?? LinkService();

  UploadState _state = UploadState.idle;
  UploadPhase _phase = UploadPhase.walrus;
  String? _errorMessage;
  LinkModel? _createdLink;
  UploadMetadata? _uploadMetadata;
  String _uploadingFileName = '';

  Future<void> _handleFilePick() async {
    final result = await FilePicker.platform.pickFiles(withData: true);
    if (result == null || result.files.isEmpty) return;

    await _upload(result.files.first);
  }

  Future<void> _upload(PlatformFile file) async {
    final bytes = file.bytes;
    if (bytes == null) {
      _showError('Could not read the selected file.');
      return;
    }

    if (file.size > AppConstants.maxFileSizeBytes) {
      _showError('File must be under 10MB');
      return;
    }

    setState(() {
      _state = UploadState.uploading;
      _phase = UploadPhase.walrus;
      _errorMessage = null;
      _uploadingFileName = file.name;
    });

    try {
      final blobId = await _walrus.uploadBlob(bytes);

      if (!mounted) return;
      setState(() => _phase = UploadPhase.saving);

      final link = await _links.createLink(
        blobId: blobId,
        fileName: file.name,
        fileSize: file.size,
      );

      if (!mounted) return;
      setState(() {
        _state = UploadState.done;
        _createdLink = link;
        _uploadMetadata = UploadMetadata(
          fileName: file.name,
          fileSize: file.size,
          mimeType: FileUtils.mimeFromExtension(file.extension),
          uploadedAt: DateTime.now(),
        );
      });
    } catch (error) {
      if (!mounted) return;
      print('HOME ERROR TYPE: ${error.runtimeType}');
      print('HOME ERROR: $error');
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
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: switch (_state) {
                UploadState.idle => _UploadPicker(
                  onBrowse: _handleFilePick,
                  onFileDrop: _upload,
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
              },
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _walrus.dispose().ignore();
    super.dispose();
  }
}

class _UploadPicker extends StatelessWidget {
  const _UploadPicker({required this.onBrowse, required this.onFileDrop});

  final VoidCallback onBrowse;
  final Future<void> Function(PlatformFile file) onFileDrop;

  @override
  Widget build(BuildContext context) {
    final muted = TextStyle(color: Colors.grey.shade600);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const _Logo(),
        const SizedBox(height: 16),
        Text(
          'Upload any file. Get a permanent short link. Powered by Walrus.',
          style: muted,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        DropZone(onFileDrop: onFileDrop),
        const SizedBox(height: 16),
        TextButton.icon(
          onPressed: onBrowse,
          icon: const Icon(Icons.folder_open_outlined),
          label: const Text('Browse files'),
        ),
        const SizedBox(height: 8),
        Text('Any file up to 10MB', style: muted),
      ],
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(
          Icons.link_rounded,
          size: 48,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: 12),
        Text('Perma.link', style: Theme.of(context).textTheme.headlineMedium),
      ],
    );
  }
}
