# Perma.link

Perma.link is a Flutter web app for uploading files to Walrus decentralized storage and sharing them through short, permanent links. Users sign in with Supabase Auth, upload a file, and get a short URL that resolves to a preview page and automatically starts a download.

## Features

- Email/password authentication with Supabase.
- Authenticated uploads only.
- Dashboard for uploaded links, timestamps, copy actions, stats, and deletion.
- Server-side link creation quota: 7 uploads per authenticated user per rolling day.
- Public short-link pages with automatic download and browser previews for images, PDFs, video, audio, and text files.
- Walrus testnet storage integration.
- Responsive Flutter web UI with protected upload and dashboard routes.

## Tech Stack

- Flutter web / Dart
- Supabase Auth and Postgres
- Walrus blob storage via `dartus`
- `go_router` for routing
- Vercel static hosting

## Local Development

Install dependencies:

```bash
flutter pub get
```

Run locally:

```bash
flutter run -d chrome \
  --dart-define=SUPABASE_URL=https://your-project.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your-anon-key
```

Run tests:

```bash
flutter test
```

Analyze:

```bash
flutter analyze
```

Build for production:

```bash
flutter build web \
  --dart-define=SUPABASE_URL=https://your-project.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your-anon-key
```

## Environment Variables

The app expects these Dart defines at run/build time:

- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`

Walrus publisher and aggregator URLs are currently configured in `lib/core/constants.dart`.


## Deployment

This repo includes `vercel.json`, which serves the Flutter web build from `build/web` and rewrites routes back to `index.html` so direct visits like `/abc123`, `/auth`, and `/dashboard` work.

Before deploying:

- Set `SUPABASE_URL` and `SUPABASE_ANON_KEY` in your build environment.
- Run the Supabase migrations.
- Confirm Supabase Auth email/password is enabled.
- Confirm the app domain in `lib/core/constants.dart` matches production.
- Run `flutter test`, `flutter analyze`, and `flutter build web`.

## Folder Structure

- `lib/app.dart` - router and app shell.
- `lib/main.dart` - Flutter/Supabase initialization.
- `lib/screens` - landing, auth, dashboard, upload, file, and stats screens.
- `lib/services` - Supabase auth/link services, Walrus upload service, and local upload history.
- `lib/core` - theme, constants, shared utilities, and navigation.
- `supabase/migrations` - database migrations.
- `test` - widget, service, and utility tests.

## Troubleshooting

- Missing Supabase config: pass `SUPABASE_URL` and `SUPABASE_ANON_KEY` with `--dart-define`.
- Upload quota errors: the authenticated user has reached 7 uploads in the last rolling day.
- Direct routes 404 in production: confirm hosting rewrites all paths to `index.html`.
- Links save but do not appear in the dashboard: confirm the `create_link_with_quota` RPC and RLS policies are installed.

## License

Add the project license before public release.
