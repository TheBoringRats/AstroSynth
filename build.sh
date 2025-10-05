#!/bin/bash
set -e

echo "📦 Installing Flutter SDK..."

# Install Flutter - Using latest stable version
FLUTTER_URL="https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_stable.tar.xz"

echo "⬇️  Downloading Flutter (latest stable)..."
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
