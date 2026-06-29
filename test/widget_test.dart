import 'package:fluffy_link/app.dart';
import 'package:fluffy_link/core/app_navbar.dart';
import 'package:fluffy_link/core/constants.dart';
import 'package:fluffy_link/models/link_model.dart';
import 'package:fluffy_link/screens/home/widgets/success_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows the landing screen and navigates to upload screen', (
    tester,
  ) async {
    // Force a desktop viewport (default 800×600 triggers the <900 mobile navbar).
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const PermaLinkApp());
    await tester.pump(const Duration(milliseconds: 100));

    // Diagnostic
    debugPrint('NavBar count: ${find.byType(AppNavBar).evaluate().length}');
    debugPrint(
      'Start Uploading count: ${find.text('Start Uploading').evaluate().length}',
    );

    // Verify Landing Screen elements
    expect(find.textContaining('PERMA', findRichText: true), findsWidgets);
    expect(find.text('Launch A File'), findsOneWidget); // Updated to match new button text
    expect(find.text('Upload a file'), findsOneWidget); // Updated from 'Start Shortening'

    // Navbar uses rocket icon + "Launch A File"; hero section uses arrow_forward icon
    await tester.tap(
      find.descendant(
        of: find.byType(AppNavBar),
        matching: find.byIcon(Icons.rocket_launch_rounded),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(
      const Duration(milliseconds: 100),
    ); // allow route transition to complete

    // Verify Upload Screen elements
    expect(find.text('Drop your file here'), findsOneWidget);
    expect(find.text('Browse files'), findsOneWidget);
    expect(
      find.text(
        'Permanent short links for your files. Powered by Walrus decentralized storage.',
      ),
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

    final baseUrl = AppConstants.appDomain.endsWith('/')
        ? AppConstants.appDomain.substring(0, AppConstants.appDomain.length - 1)
        : AppConstants.appDomain;

    expect(find.text('$baseUrl/abc123'), findsOneWidget);
    expect(find.text('$baseUrl/s/abc123'), findsOneWidget);
    expect(find.text('Share link'), findsOneWidget);
    expect(find.text('Stats link'), findsOneWidget);
    // Verify action buttons - should have View and Download, but not Copy
    expect(find.text('View'), findsOneWidget);
    expect(find.text('Download'), findsOneWidget);
    expect(find.text('Copy'), findsNothing); // Verify copy button is removed
  });
}
