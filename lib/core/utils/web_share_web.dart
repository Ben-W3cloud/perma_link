// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use, unnecessary_null_comparison, unnecessary_non_null_assertion

import 'dart:html' as html;

bool get isWebShareSupported => html.window.navigator.share != null;

Future<bool> shareUrl({required String title, required String url}) async {
  try {
    await html.window.navigator.share!({'title': title, 'url': url});
    return true;
  } catch (_) {
    return false;
  }
}
