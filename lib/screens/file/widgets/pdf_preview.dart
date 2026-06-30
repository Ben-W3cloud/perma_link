import 'package:fluffy_link/core/theme.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pdfx/pdfx.dart';

class PdfPreview extends StatefulWidget {
  const PdfPreview({super.key, required this.url});

  final String url;

  @override
  State<PdfPreview> createState() => _PdfPreviewState();
}

class _PdfPreviewState extends State<PdfPreview> {
  PdfControllerPinch? _controller;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final response = await http.get(Uri.parse(widget.url));
      if (response.statusCode >= 400) {
        throw http.ClientException('HTTP ${response.statusCode}');
      }
      final document = await PdfDocument.openData(response.bodyBytes);
      if (!mounted) return;
      setState(() {
        _controller = PdfControllerPinch(document: Future.value(document));
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not load PDF preview';
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      child: Container(
        height: 360,
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          border: Border.all(color: AppTheme.border),
        ),
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(strokeWidth: 2.5),
        ),
      );
    }
    final error = _error;
    if (error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.picture_as_pdf_rounded,
              size: 28,
              color: AppTheme.muted,
            ),
            const SizedBox(height: 8),
            Text(error, style: TextStyle(color: AppTheme.muted)),
            const SizedBox(height: 4),
            Text(
              'Click View to open the PDF.',
              style: TextStyle(color: AppTheme.mutedDim, fontSize: 12),
            ),
          ],
        ),
      );
    }
    return PdfViewPinch(controller: _controller!);
  }
}
