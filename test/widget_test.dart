import 'package:fluffy_link/app.dart';
import 'package:fluffy_link/models/link_model.dart';
import 'package:fluffy_link/screens/home/widgets/success_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows the upload screen', (tester) async {
    await tester.pumpWidget(const PermaLinkApp());

    expect(find.text('Perma.link'), findsOneWidget);
    expect(find.text('Drop your file here'), findsOneWidget);
    expect(find.text('Browse files'), findsOneWidget);
    expect(
      find.text('Upload any file. Get a permanent short link. Powered by Walrus.'),
      findsOneWidget,
    );
  });

  testWidgets('success card shows share and stats links', (tester) async {
    final link = LinkModel(
      id: 'id',
      shortCode: 'abc123',
      blobId: 'blob',
      fileName: 'test.png',
      fileSize: 2048,
      clickCount: 0,
      createdAt: DateTime.utc(2026, 6, 10),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SuccessCard(
            link: link,
            metadata: UploadMetadata(
              fileName: 'test.png',
              fileSize: 2048,
              mimeType: 'image/png',
              uploadedAt: DateTime.utc(2026, 6, 10),
            ),
            onReset: () {},
          ),
        ),
      ),
    );

    expect(find.text('https://perma.link/abc123'), findsOneWidget);
    expect(find.text('https://perma.link/s/abc123'), findsOneWidget);
    expect(find.text('Share link'), findsOneWidget);
    expect(find.text('Stats link'), findsOneWidget);
  });
}
