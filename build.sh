#!/bin/bash
set -e
git clone https://github.com/flutter/flutter.git -b stable --depth 1 /opt/flutter
/opt/flutter/bin/flutter pub get
/opt/flutter/bin/flutter build web \
  --dart-define=SUPABASE_URL=$SUPABASE_URL \
  --dart-define=SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY \
  --release