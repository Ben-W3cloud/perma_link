# Perma.link — Build Guide

> TinyURL for Walrus-hosted files. Share `perma.link/abc123` instead of long blob IDs.  
> Stack: Flutter Web · Dartus SDK · Supabase · Vercel

---

## Table of Contents

1. [Folder Structure](#1-folder-structure)
2. [Phase 0 — Prerequisites](#2-phase-0--prerequisites)
3. [Phase 1 — Project Bootstrap](#3-phase-1--project-bootstrap)
4. [Phase 2 — Supabase Setup](#4-phase-2--supabase-setup)
5. [Phase 3 — Core Services Layer](#5-phase-3--core-services-layer)
6. [Phase 4 — Routing](#6-phase-4--routing)
7. [Phase 5 — Upload Screen](#7-phase-5--upload-screen)
8. [Phase 6 — Redirect Screen](#8-phase-6--redirect-screen)
9. [Phase 7 — Polish & Error States](#9-phase-7--polish--error-states)
10. [Phase 8 — Build & Deploy](#10-phase-8--build--deploy)
11. [Environment Variables Reference](#11-environment-variables-reference)
12. [Key Gotchas](#12-key-gotchas)

---

## 1. Folder Structure

```
perma_link/
├── lib/
│   ├── main.dart                    # App entry point, Supabase init
│   ├── app.dart                     # MaterialApp + GoRouter setup
│   │
│   ├── core/
│   │   ├── constants.dart           # Walrus endpoints, app name, domain
│   │   ├── theme.dart               # Colors, text styles, app theme
│   │   └── utils/
│   │       ├── code_generator.dart  # Nanoid-style short code generator
│   │       └── file_utils.dart      # File size formatting, MIME helpers
│   │
│   ├── services/
│   │   ├── walrus_service.dart      # Dartus WalrusClient wrapper
│   │   └── link_service.dart        # Supabase CRUD for links table
│   │
│   ├── models/
│   │   └── link_model.dart          # Link data class (shortCode, blobId, etc.)
│   │
│   └── screens/
│       ├── home/
│       │   ├── home_screen.dart     # Upload UI (drag-drop + file picker)
│       │   └── widgets/
│       │       ├── drop_zone.dart   # Drag-and-drop target widget
│       │       ├── upload_progress.dart
│       │       └── success_card.dart # Shows generated link + copy button
│       │
│       └── redirect/
│           ├── redirect_screen.dart # Resolves short code → Walrus URL
│           └── widgets/
│               └── loading_view.dart
│
├── web/
│   ├── index.html                   # Flutter web entry (keep minimal)
│   └── favicon.png
│
├── test/
│   ├── services/
│   │   ├── walrus_service_test.dart
│   │   └── link_service_test.dart
│   └── utils/
│       └── code_generator_test.dart
│
├── .env.example                     # Template for env vars
├── pubspec.yaml
├── vercel.json                      # Vercel SPA rewrite rules
└── README.md
```

---

## 2. Phase 0 — Prerequisites

Complete these before touching any code.

### 2.1 Install tools

```bash
# Flutter stable channel (3.35.0+)
flutter channel stable
flutter upgrade

# Verify Flutter Web is enabled
flutter config --enable-web
flutter devices   # should list Chrome and Edge

# Dart SDK comes with Flutter — verify version
dart --version    # needs >= 3.9.2
```

### 2.2 Accounts to create

| Service | URL | Notes |
|---------|-----|-------|
| Supabase | https://supabase.com | Free tier is enough for MVP |
| Vercel | https://vercel.com | Free hobby plan works |
| Domain registrar | https://porkbun.com or Cloudflare | Buy your `.link` domain (~$10/yr) |

### 2.3 VS Code extensions (recommended)

- Dart (by Dart Code)
- Flutter (by Dart Code)
- Pubspec Assist

---

## 3. Phase 1 — Project Bootstrap

### 3.1 Create the Flutter project

```bash
flutter create perma_link --platforms web --org com.yourname
cd perma_link

# Verify web target works before adding any packages
flutter run -d chrome
```

### 3.2 Update `pubspec.yaml`

Replace the `dependencies` and `dev_dependencies` se?ctions:

```yaml
dependencies:
  flutter:
    sdk: flutter

  # Walrus blob storage SDK
  dartus: ^0.2.0

  # Supabase client
  supabase_flutter: ^2.5.0

  # Routing
  go_router: ^14.0.0

  # File picking (web-compatible)
  file_picker: ^8.1.2

  # Clipboard
  flutter_clipboard_manager: ^0.0.2

  # URL launcher (for redirect)
  url_launcher: ^6.3.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^4.0.0
```

```bash
flutter pub get
```

### 3.3 Create the folder structure

```bash
mkdir -p lib/core/utils
mkdir -p lib/services
mkdir -p lib/models
mkdir -p lib/screens/home/widgets
mkdir -p lib/screens/redirect/widgets
mkdir -p test/services test/utils
```

### 3.4 Create `.env.example`

```bash
cat > .env.example << 'EOF'
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key-here
EOF
```

Copy it to `.env` and fill in your real values after Phase 2.

> **Important:** add `.env` to `.gitignore` right now.

```bash
echo ".env" >> .gitignore
```

---

## 4. Phase 2 — Supabase Setup

### 4.1 Create Supabase project

1. Go to https://supabase.com/dashboard → New project
2. Pick a region close to your target users
3. Save the database password somewhere safe

### 4.2 Run the schema SQL

In the Supabase dashboard → SQL Editor → New query, paste and run:

```sql
-- Links table
create table links (
  id           uuid primary key default gen_random_uuid(),
  short_code   text not null unique,
  blob_id      text not null,
  file_name    text,
  file_size    bigint,
  click_count  int8 not null default 0,
  created_at   timestamptz not null default now()
);

-- Index for the most common lookup (short_code → blob_id)
create index idx_links_short_code on links(short_code);

-- Enable Row Level Security
alter table links enable row level security;

-- Allow anyone to read links (needed for the redirect flow)
create policy "Public read"
  on links for select
  using (true);

-- Allow anyone to insert (no auth in base version)
create policy "Public insert"
  on links for insert
  with check (true);

-- Allow click count to be updated by anyone
create policy "Public update click_count"
  on links for update
  using (true)
  with check (true);
```

### 4.3 Create a function for atomic click increment

```sql
create or replace function increment_click_count(code text)
returns void
language plpgsql
as $$
begin
  update links
  set click_count = click_count + 1
  where short_code = code;
end;
$$;
```

### 4.4 Copy your credentials

From Supabase → Settings → API:
- Project URL → goes into `SUPABASE_URL`
- `anon` public key → goes into `SUPABASE_ANON_KEY`

Paste both into your `.env` file.

---

## 5. Phase 3 — Core Services Layer

Build the services before the UI. This lets you test them in isolation.

### 5.1 `lib/core/constants.dart`

```dart
class AppConstants {
  // Walrus testnet endpoints (HTTP mode, no wallet needed)
  static const String walrusPublisher =
      'https://publisher.walrus-testnet.walrus.space';
  static const String walrusAggregator =
      'https://aggregator.walrus-testnet.walrus.space';

  // How many epochs to store blobs (1 epoch ≈ 1 day on testnet)
  static const int storageEpochs = 3;

  // Short code length
  static const int shortCodeLength = 6;

  // Your domain (change before deploy)
  static const String appDomain = 'https://perma.link';
}
```

### 5.2 `lib/core/utils/code_generator.dart`

```dart
import 'dart:math';

class CodeGenerator {
  static const _chars =
      'abcdefghijklmnopqrstuvwxyz0123456789';
  static final _rand = Random.secure();

  static String generate({int length = 6}) {
    return List.generate(
      length,
      (_) => _chars[_rand.nextInt(_chars.length)],
    ).join();
  }
}
```

### 5.3 `lib/models/link_model.dart`

```dart
class LinkModel {
  final String id;
  final String shortCode;
  final String blobId;
  final String? fileName;
  final int? fileSize;
  final int clickCount;
  final DateTime createdAt;

  const LinkModel({
    required this.id,
    required this.shortCode,
    required this.blobId,
    this.fileName,
    this.fileSize,
    required this.clickCount,
    required this.createdAt,
  });

  factory LinkModel.fromJson(Map<String, dynamic> json) => LinkModel(
        id: json['id'] as String,
        shortCode: json['short_code'] as String,
        blobId: json['blob_id'] as String,
        fileName: json['file_name'] as String?,
        fileSize: json['file_size'] as int?,
        clickCount: json['click_count'] as int,
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  String get shortUrl => '${AppConstants.appDomain}/${shortCode}';
  String get walrusUrl =>
      '${AppConstants.walrusAggregator}/v1/${blobId}';
}
```

> Don't forget to import `constants.dart` at the top of this file.

### 5.4 `lib/services/walrus_service.dart`

```dart
import 'package:dartus/dartus.dart';

class WalrusService {
  late final WalrusClient _client;

  WalrusService() {
    _client = WalrusClient(
      publisherBaseUrl: Uri.parse(AppConstants.walrusPublisher),
      aggregatorBaseUrl: Uri.parse(AppConstants.walrusAggregator),
      useSecureConnection: false, // testnet uses self-signed certs
      logLevel: WalrusLogLevel.info,
    );
  }

  /// Uploads [bytes] to Walrus and returns the blob ID.
  /// Throws [WalrusClientError] on failure.
  Future<String> uploadBlob(List<int> bytes) async {
    final response = await _client.putBlob(
      data: bytes,
      epochs: AppConstants.storageEpochs,
    );

    // Dartus returns either newlyCreated or alreadyCertified
    final blobId =
        response['newlyCreated']?['blobObject']?['blobId'] as String? ??
        response['alreadyCertified']?['blobId'] as String?;

    if (blobId == null) {
      throw Exception('Walrus upload succeeded but returned no blobId');
    }
    return blobId;
  }

  void dispose() => _client.close();
}
```

### 5.5 `lib/services/link_service.dart`

```dart
import 'package:supabase_flutter/supabase_flutter.dart';

class LinkService {
  final _supabase = Supabase.instance.client;

  /// Inserts a new link row and returns the created [LinkModel].
  Future<LinkModel> createLink({
    required String blobId,
    String? fileName,
    int? fileSize,
  }) async {
    // Retry up to 3 times on short code collision (very unlikely at 6 chars)
    for (int attempt = 0; attempt < 3; attempt++) {
      final code = CodeGenerator.generate();
      try {
        final data = await _supabase
            .from('links')
            .insert({
              'short_code': code,
              'blob_id': blobId,
              'file_name': fileName,
              'file_size': fileSize,
            })
            .select()
            .single();
        return LinkModel.fromJson(data);
      } on PostgrestException catch (e) {
        // 23505 = unique_violation; retry with a new code
        if (e.code == '23505' && attempt < 2) continue;
        rethrow;
      }
    }
    throw Exception('Failed to generate a unique short code');
  }

  /// Looks up a link by [shortCode] and increments the click counter.
  /// Returns null if the code does not exist.
  Future<LinkModel?> resolveAndTrack(String shortCode) async {
    final data = await _supabase
        .from('links')
        .select()
        .eq('short_code', shortCode)
        .maybeSingle();

    if (data == null) return null;

    // Increment click count (fire-and-forget is fine here)
    _supabase.rpc(
      'increment_click_count',
      params: {'code': shortCode},
    ).catchError((_) {}); // don't block on analytics failure

    return LinkModel.fromJson(data);
  }
}
```

---

## 6. Phase 4 — Routing

### 6.1 `lib/app.dart`

```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

final _router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/:code',
      builder: (context, state) => RedirectScreen(
        code: state.pathParameters['code']!,
      ),
    ),
  ],
  errorBuilder: (context, state) => const NotFoundScreen(),
);

class PermaLinkApp extends StatelessWidget {
  const PermaLinkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Perma.link',
      theme: AppTheme.light,
      routerConfig: _router,
    );
  }
}
```

### 6.2 `lib/main.dart`

```dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: const String.fromEnvironment('SUPABASE_URL'),
    anonKey: const String.fromEnvironment('SUPABASE_ANON_KEY'),
  );

  runApp(const PermaLinkApp());
}
```

> `String.fromEnvironment` reads compile-time `--dart-define` flags —  
> see Phase 8 for how to pass these at build time.

### 6.3 `vercel.json`

GoRouter needs a catch-all rewrite so Vercel doesn't return a 404 on deep links:

```json
{
  "rewrites": [
    { "source": "/(.*)", "destination": "/index.html" }
  ]
}
```

---

## 7. Phase 5 — Upload Screen

### 7.1 `lib/screens/home/home_screen.dart`

This screen has three visual states: **idle** (drop zone), **uploading** (progress), and **done** (success card).

```dart
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

enum UploadState { idle, uploading, done, error }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _walrus = WalrusService();
  final _links = LinkService();

  UploadState _state = UploadState.idle;
  String? _errorMessage;
  LinkModel? _createdLink;

  Future<void> _handleFilePick() async {
    final result = await FilePicker.platform.pickFiles(
      withData: true, // needed for Flutter Web
    );
    if (result == null || result.files.isEmpty) return;
    await _upload(result.files.first);
  }

  Future<void> _upload(PlatformFile file) async {
    setState(() {
      _state = UploadState.uploading;
      _errorMessage = null;
    });

    try {
      final bytes = file.bytes!;

      // 1. Upload to Walrus
      final blobId = await _walrus.uploadBlob(bytes);

      // 2. Store mapping in Supabase
      final link = await _links.createLink(
        blobId: blobId,
        fileName: file.name,
        fileSize: file.size,
      );

      setState(() {
        _state = UploadState.done;
        _createdLink = link;
      });
    } catch (e) {
      setState(() {
        _state = UploadState.error;
        _errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: switch (_state) {
              UploadState.idle || UploadState.error => Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const _Logo(),
                    const SizedBox(height: 40),
                    DropZone(onFileDrop: _upload),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: _handleFilePick,
                      child: const Text('or click to browse'),
                    ),
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        style: TextStyle(color: Theme.of(context).colorScheme.error),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              UploadState.uploading => const UploadProgress(),
              UploadState.done => SuccessCard(
                  link: _createdLink!,
                  onReset: () => setState(() {
                    _state = UploadState.idle;
                    _createdLink = null;
                  }),
                ),
            },
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _walrus.dispose();
    super.dispose();
  }
}
```

### 7.2 `lib/screens/home/widgets/drop_zone.dart`

```dart
// Flutter Web drag-and-drop using the browser's native DragEvent.
// Use the `desktop_drop` package if you need desktop native support too.
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

class DropZone extends StatefulWidget {
  final Future<void> Function(PlatformFile file) onFileDrop;
  const DropZone({super.key, required this.onFileDrop});

  @override
  State<DropZone> createState() => _DropZoneState();
}

class _DropZoneState extends State<DropZone> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 200,
        decoration: BoxDecoration(
          color: _hovered
              ? Theme.of(context).colorScheme.primaryContainer
              : Theme.of(context).colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _hovered
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outline,
            width: 1.5,
          ),
        ),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.upload_file_outlined, size: 40),
              SizedBox(height: 12),
              Text('Drop your file here'),
            ],
          ),
        ),
      ),
    );
  }
}
```

> **Note on web drag-and-drop:** Flutter Web does not natively expose `DragEvent` bytes in all  
> versions. If `file_picker` doesn't support drag-drop out of the box for your Flutter version,  
> use the [`drop_zone`](https://pub.dev/packages/drop_zone) package or the native HTML interop  
> approach with `dart:html`. Log an issue — this is a known Flutter Web limitation.

### 7.3 `lib/screens/home/widgets/success_card.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SuccessCard extends StatefulWidget {
  final LinkModel link;
  final VoidCallback onReset;
  const SuccessCard({super.key, required this.link, required this.onReset});

  @override
  State<SuccessCard> createState() => _SuccessCardState();
}

class _SuccessCardState extends State<SuccessCard> {
  bool _copied = false;

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.link.shortUrl));
    setState(() => _copied = true);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _copied = false);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.check_circle_outline, color: Colors.green, size: 48),
        const SizedBox(height: 16),
        Text(
          'Your link is ready',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceVariant,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  widget.link.shortUrl,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 15),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(_copied ? Icons.check : Icons.copy_outlined),
                tooltip: _copied ? 'Copied!' : 'Copy link',
                onPressed: _copy,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        TextButton(
          onPressed: widget.onReset,
          child: const Text('Upload another file'),
        ),
      ],
    );
  }
}
```

---

## 8. Phase 6 — Redirect Screen

This screen runs the **resolve path**: lookup → increment → redirect.

### 8.1 `lib/screens/redirect/redirect_screen.dart`

```dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class RedirectScreen extends StatefulWidget {
  final String code;
  const RedirectScreen({super.key, required this.code});

  @override
  State<RedirectScreen> createState() => _RedirectScreenState();
}

class _RedirectScreenState extends State<RedirectScreen> {
  final _links = LinkService();

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  Future<void> _resolve() async {
    final link = await _links.resolveAndTrack(widget.code);

    if (!mounted) return;

    if (link == null) {
      // Navigate to a 404 view — handled by GoRouter errorBuilder
      // or push a local not-found widget
      setState(() => _notFound = true);
      return;
    }

    // Redirect browser directly to Walrus aggregator URL.
    // We open externally to avoid CORS issues on blob serving.
    final uri = Uri.parse(link.walrusUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  bool _notFound = false;

  @override
  Widget build(BuildContext context) {
    if (_notFound) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('404 — Link not found', style: TextStyle(fontSize: 20)),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => context.go('/'),
                child: const Text('Go home'),
              ),
            ],
          ),
        ),
      );
    }

    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
```

---

## 9. Phase 7 — Polish & Error States

### 9.1 Add a basic theme in `lib/core/theme.dart`

```dart
import 'package:flutter/material.dart';

class AppTheme {
  static final light = ThemeData(
    useMaterial3: true,
    colorSchemeSeed: const Color(0xFF6750A4), // swap for your brand color
    fontFamily: 'Inter',                       // or leave as system default
  );
}
```

### 9.2 Handle file size limits

Add a guard in `_upload()` in `home_screen.dart` before calling the service:

```dart
const int maxBytes = 10 * 1024 * 1024; // 10 MB — adjust as needed

if (file.size > maxBytes) {
  setState(() {
    _state = UploadState.error;
    _errorMessage = 'File must be under 10 MB.';
  });
  return;
}
```

### 9.3 Add a loading indicator in `upload_progress.dart`

```dart
import 'package:flutter/material.dart';

class UploadProgress extends StatelessWidget {
  const UploadProgress({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircularProgressIndicator(),
        SizedBox(height: 16),
        Text('Uploading to Walrus…'),
      ],
    );
  }
}
```

### 9.4 Retry logic for Walrus uploads

Wrap the `_walrus.uploadBlob` call with retry on retryable errors:

```dart
// In walrus_service.dart
import 'package:dartus/dartus.dart';

Future<String> uploadBlob(List<int> bytes, {int retries = 2}) async {
  for (int i = 0; i <= retries; i++) {
    try {
      return await _doUpload(bytes);
    } on RetryableWalrusClientError catch (_) {
      _client.reset();
      if (i == retries) rethrow;
      await Future.delayed(Duration(seconds: i + 1));
    }
  }
  throw Exception('Upload failed after $retries retries');
}
```

---

## 10. Phase 8 — Build & Deploy

### 10.1 Run locally with env vars

```bash
flutter run -d chrome \
  --dart-define=SUPABASE_URL=https://your-project.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your-anon-key
```

### 10.2 Build for production

```bash
flutter build web \
  --dart-define=SUPABASE_URL=https://your-project.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your-anon-key \
  --release
```

Output lands in `build/web/`.

### 10.3 Deploy to Vercel

**Option A — Vercel CLI (fastest)**

```bash
npm i -g vercel
cd build/web
vercel --prod
```

Vercel will detect the static files. Point it to `build/web` as the output directory.

**Option B — GitHub CI (recommended for ongoing deploys)**

1. Push your repo to GitHub.
2. In Vercel dashboard → New Project → Import your repo.
3. Set the **Build Command** to:
   ```
   flutter build web --dart-define=SUPABASE_URL=$SUPABASE_URL --dart-define=SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY --release
   ```
4. Set the **Output Directory** to `build/web`.
5. Add `SUPABASE_URL` and `SUPABASE_ANON_KEY` as environment variables in Vercel's project settings.

### 10.4 Attach your custom domain

1. In Vercel → your project → Settings → Domains → add `perma.link` (or `www.perma.link`).
2. Vercel gives you the DNS records. Add them at your registrar.
3. Wait for propagation (usually under 10 minutes on Cloudflare DNS).

### 10.5 Verify the Walrus testnet endpoints work on HTTPS

Your `useSecureConnection: false` setting accepts self-signed certs. On production, you may want to proxy Walrus requests through a small edge function or switch to a publisher that has a valid TLS cert. For the base MVP, leaving it as-is on testnet is fine.

---

## 11. Environment Variables Reference

| Variable | Where set | Example |
|----------|-----------|---------|
| `SUPABASE_URL` | `.env` + Vercel project settings | `https://xyz.supabase.co` |
| `SUPABASE_ANON_KEY` | `.env` + Vercel project settings | `eyJhbGci...` |

Both are passed at **compile time** via `--dart-define`. There is no runtime `.env` file in Flutter Web builds.

---

## 12. Key Gotchas

| # | Issue | Fix |
|---|-------|-----|
| 1 | Walrus testnet uses self-signed TLS | Set `useSecureConnection: false` on `WalrusClient` |
| 2 | `file.bytes` is null on web | Always pass `withData: true` to `FilePicker.platform.pickFiles()` |
| 3 | GoRouter deep links 404 on Vercel | Add the catch-all rewrite in `vercel.json` |
| 4 | `String.fromEnvironment` returns empty at runtime | Always pass `--dart-define` at **build time**, not just run time |
| 5 | CORS on blob serving | Redirect browser directly to Walrus aggregator URL — do NOT proxy through Flutter |
| 6 | Supabase `anon` key exposed in JS bundle | Expected for this model — the RLS policies are your security layer |
| 7 | Short code collision | The `createLink` service retries up to 3 times on Postgres `23505` error |
| 8 | `RetryableWalrusClientError` | Call `client.reset()` before retrying — it refreshes epoch/committee state |

---

*Built with Dartus SDK (Walrus decentralized storage) · Supabase · Flutter Web · Vercel*