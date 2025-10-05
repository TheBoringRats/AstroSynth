#!/bin/bash
set -e

echo "📦 Installing Flutter SDK..."

# Install Flutter
FLUTTER_VERSION="3.24.3"
FLUTTER_TAR="flutter_linux_${FLUTTER_VERSION}-stable.tar.xz"
FLUTTER_URL="https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/${FLUTTER_TAR}"

echo "⬇️  Downloading Flutter ${FLUTTER_VERSION}..."
curl -L -o flutter.tar.xz $FLUTTER_URL

echo "📂 Extracting Flutter..."
tar xf flutter.tar.xz

echo "🔧 Setting up Flutter..."
export PATH="$PATH:`pwd`/flutter/bin"

# Disable analytics
flutter config --no-analytics

# Check Flutter installation
echo "✅ Flutter version:"
flutter --version

# Enable web
echo "🌐 Enabling Flutter web..."
flutter config --enable-web

# Get dependencies
echo "📚 Getting dependencies..."
flutter pub get

# Build web app
echo "🔨 Building Flutter web app..."
flutter build web --release --web-renderer canvaskit

echo "✅ Build complete!"
