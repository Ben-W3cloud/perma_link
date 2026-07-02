# Perma.link

> Permanent short links for files stored on Walrus decentralized storage.

Perma.link lets you upload any file, store it permanently on the Walrus network, and share it through a clean short URL like `perma.link/abc123`. Every link resolves to a file preview page that handles images, PDFs, video, audio, and text inline — and starts a download automatically for everything else. Built entirely in Flutter Web.

---

## What it does

You sign in, drop a file, and get a short link in seconds. The file lives on Walrus decentralized storage — not on a server you maintain, not behind a SaaS subscription. The short code is stored in Supabase and maps to a Walrus blob ID. Anyone with the link can view or download the file without an account.

Your dashboard shows every link you have created — with timestamps, click counts, copy actions, and the ability to delete links you no longer want to share. A rolling quota of 7 uploads per day per user keeps the service fair on the testnet.

---

## Features

- Email and password authentication via Supabase Auth
- Authenticated uploads only — no anonymous abuse
- File uploads up to 120MB stored on Walrus testnet
- Short 6-character links generated per upload
- Public file pages with inline preview for images, PDFs, video, audio, and plain text
- Automatic download trigger for unsupported file types
- Dashboard with all your links, upload dates, click counts, copy, and delete
- Server-enforced quota — 7 uploads per authenticated user per rolling 24 hours via Supabase RPC
- Fully responsive Flutter Web UI
- Protected routes — upload and dashboard require auth, file pages are public

---

## Tech Stack

| Layer | Technology |
|-------|------------|
| Frontend | Flutter Web / Dart |
| Auth + Database | Supabase Auth + Postgres |
| File storage | Walrus testnet via Dartus SDK |
| Routing | GoRouter |
| Hosting | Vercel |

---

## Local Development

**1. Install dependencies**

```bash
flutter pub get
```

**2. Run locally**

```bash
flutter run -d chrome \
  --dart-define=SUPABASE_URL=https://your-project.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your-anon-key
```

**3. Run tests**

```bash
flutter test
```

**4. Analyze**

```bash
flutter analyze
```

---

## Environment Variables

Credentials are passed at compile time via `--dart-define`. There is no `.env` file — Flutter Web builds them into the compiled output.

| Variable | Description |
|----------|-------------|
| `SUPABASE_URL` | Your Supabase project URL |
| `SUPABASE_ANON_KEY` | Your Supabase anon public key |

Walrus publisher and aggregator URLs are in `lib/core/constants.dart`.

---

## Database Setup

Run the migrations in `supabase/migrations/` against your Supabase project before first use. The `create_link_with_quota` RPC and all RLS policies are defined there. Confirm Supabase Auth has email/password sign-in enabled.

---

## Production Build

```bash
flutter build web \
  --dart-define=SUPABASE_URL=https://your-project.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your-anon-key \
  --release
```

Output lands in `build/web/`. The included `vercel.json` rewrites all routes to `index.html` so direct visits to `/:code`, `/auth`, and `/dashboard` work correctly.

**Pre-deploy checklist:**
- [ ] `SUPABASE_URL` and `SUPABASE_ANON_KEY` set in Vercel environment variables
- [ ] Supabase migrations applied
- [ ] Supabase Auth email/password enabled
- [ ] `appDomain` in `lib/core/constants.dart` set to your production domain
- [ ] `flutter test` passes
- [ ] `flutter analyze` returns no issues
- [ ] `flutter build web` completes without errors

---

## Project Structure

```
lib/
├── main.dart                       # Entry point, Supabase initialization
├── app.dart                        # GoRouter setup, app shell
├── core/
│   ├── constants.dart              # Walrus endpoints, domain, limits
│   ├── theme.dart                  # App theme
│   └── utils/                      # Shared utilities
├── screens/
│   ├── landing/                    # Public marketing page
│   ├── auth/                       # Sign in and sign up
│   ├── upload/                     # File upload tool (auth required)
│   ├── dashboard/                  # User link history (auth required)
│   ├── file/                       # Public file preview page /:code
│   └── stats/                      # Link stats
├── services/
│   ├── auth_service.dart           # Supabase Auth wrapper
│   ├── link_service.dart           # Supabase link CRUD
│   ├── walrus_service.dart         # Dartus SDK blob upload
│   └── upload_history_service.dart
supabase/
└── migrations/                     # All schema and RLS migrations
test/                               # Widget, service, and utility tests
vercel.json                         # Catch-all rewrite for Flutter Web routing
build.sh                            # Vercel build script
```

---

## Troubleshooting

**Missing Supabase config**
Pass `SUPABASE_URL` and `SUPABASE_ANON_KEY` via `--dart-define` at run or build time. The app throws on startup if either is empty.

**Upload quota error**
The signed-in user has reached 7 uploads in the last rolling 24 hours. Wait for the window to reset or use a different account for testing.

**Direct routes return 404 in production**
Confirm `vercel.json` has the catch-all rewrite:
```json
{ "source": "/(.*)", "destination": "/index.html" }
```

**Links saved but not showing in dashboard**
Confirm the `create_link_with_quota` RPC and RLS policies from the migrations are applied to your Supabase project.

**File upload fails silently**
Check the browser console for `UnsupportedError` — this means the Dartus SDK is attempting a `dart:io` HTTP call which is not supported on Flutter Web. Ensure `walrus_service.dart` is using the `http` package for the PUT request directly.

---

## Roadmap

- [ ] Mainnet Walrus storage once `dart:io` is resolved in the Dartus SDK
- [ ] Sui wallet connect as an alternative to email auth
- [ ] QR code per link on the dashboard
- [ ] File preview thumbnails in the dashboard
- [ ] Programmatic upload API for developers
- [ ] CLI tool

---

## Built With

- [Flutter](https://flutter.dev)
- [Dartus SDK](https://github.com/Immadominion/Dartus) — Flutter SDK for Walrus
- [Walrus](https://walrus.xyz) — Decentralized storage on Sui
- [Supabase](https://supabase.com)
- [Vercel](https://vercel.com)

---

*License — add before public release.*
