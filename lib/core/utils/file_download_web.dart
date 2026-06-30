// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:async';
import 'dart:html' as html;

Future<bool> downloadFile({
  required String url,
  required String filename,
  String? mimeType,
}) async {
  try {
    final request = await html.HttpRequest.request(
      url,
      method: 'GET',
      responseType: 'blob',
    );

    final body = request.response;
    if (body is! html.Blob) {
      return false;
    }

    // Re-wrap with the desired MIME type when supplied so the browser
    // saves it with the right content-type rather than octet-stream.
    final blob = (mimeType != null && mimeType.isNotEmpty)
        ? html.Blob([body], mimeType)
        : body;

    final objectUrl = html.Url.createObjectUrlFromBlob(blob);
    try {
      final anchor = html.AnchorElement(href: objectUrl)
        ..setAttribute('download', filename)
        ..style.display = 'none';

      html.document.body?.append(anchor);
      anchor.click();
      anchor.remove();
    } finally {
      // Release the object URL on the next tick — Chrome cancels the
      // download if we revoke before the click has been fully processed.
      Timer(const Duration(seconds: 1), () {
        html.Url.revokeObjectUrl(objectUrl);
      });
    }

    return true;
  } catch (_) {
    return false;
  }
}
