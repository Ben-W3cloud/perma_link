// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:fluffy_link/screens/home/widgets/drop_zone_listener.dart';

StreamSubscription<html.Event>? _dragOverSub;
StreamSubscription<html.Event>? _dropSub;
HoverCallback? _onHoverChanged;
Future<void> Function(PlatformFile file)? _onFileDrop;

void setupDropZone({
  required HoverCallback onHoverChanged,
  required Future<void> Function(PlatformFile file) onFileDrop,
}) {
  teardownDropZone();
  _onHoverChanged = onHoverChanged;
  _onFileDrop = onFileDrop;

  _dragOverSub = html.document.onDragOver.listen((event) {
    event.preventDefault();
    _onHoverChanged?.call(true);
  });

  _dropSub = html.document.onDrop.listen((event) async {
    event.preventDefault();
    _onHoverChanged?.call(false);

    final files = event.dataTransfer.files;
    if (files == null || files.isEmpty) return;

    final file = files.first;
    final reader = html.FileReader();
    final completer = Completer<Uint8List>();

    reader.onLoadEnd.listen((_) {
      final result = reader.result;
      if (result is Uint8List) {
        completer.complete(result);
      } else if (result is ByteBuffer) {
        completer.complete(result.asUint8List());
      } else {
        completer.completeError(StateError('Could not read dropped file.'));
      }
    });

    reader.readAsArrayBuffer(file);

    try {
      final bytes = await completer.future;
      await _onFileDrop?.call(
        PlatformFile(name: file.name, size: file.size, bytes: bytes),
      );
    } catch (_) {
      // Upload errors are handled by the caller.
    }
  });
}

void teardownDropZone() {
  _dragOverSub?.cancel();
  _dropSub?.cancel();
  _dragOverSub = null;
  _dropSub = null;
  _onHoverChanged = null;
  _onFileDrop = null;
}
