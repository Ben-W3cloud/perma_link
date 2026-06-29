#!/bin/bash
set -e

echo "Cleaning previous builds..."
flutter clean

echo "Getting dependencies..."
flutter pub get

# 1. Load local .env variables into the shell environment if the file exists
if [ -f .env ]; then
    echo "Loading local .env file..."
    # Using export safely without breaking on spaces
    export $(grep -v '^#' .env | xargs)
fi

echo "Building Flutter Web for Release with Environment Variables..."

# 2. Match exact variable names (Changed $apiUrl to $API_URL)
flutter build web --release \
  --dart-define=API_KEY="${API_KEY:-DEFAULT_KEY}" \
  --dart-define=API_URL="${API_URL:-DEFAULT_URL}"

echo "Build complete! Variables securely baked into build/web/"
