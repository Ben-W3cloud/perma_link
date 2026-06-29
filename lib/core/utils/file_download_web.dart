// ignore_for_file: avoid_web_libraries_in_flutter

import 'dart:html' as html;

Future<bool> downloadFile({required String url, required String filename}) async {
  try {
    // Create an anchor element
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', filename)
      ..style.display = 'none';
    
    // Append to document body
    html.document.body?.append(anchor);
    
    // Trigger click
    anchor.click();
    
    // Remove the anchor
    anchor.remove();
    
    return true;
  } catch (e) {
    return false;
  }
}