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