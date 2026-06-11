import 'package:file_picker/file_picker.dart';

typedef HoverCallback = void Function(bool hovered);

void setupDropZone({
  required HoverCallback onHoverChanged,
  required Future<void> Function(PlatformFile file) onFileDrop,
}) {}

void teardownDropZone() {}
