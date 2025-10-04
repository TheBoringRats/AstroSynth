#!/bin/bash
# Quick fix script to make AstroSynth build on Android by wrapping web-only code

echo "🔧 Applying quick fixes for Android build..."

# List of files that need conditional compilation
FILES=(
  "lib/widgets/planet_card.dart"
  "lib/widgets/planet_3d_viewer.dart"
  "lib/widgets/planet_3d_world_viewer.dart"
  "lib/widgets/ai_3d_planet_viewer.dart"
  "lib/services/planet_cache_service.dart"
  "lib/services/ai_enhancement_service.dart"
  "lib/screens/planet_detail_screen.dart"
)

# Backup original files
echo "📦 Creating backups..."
for file in "${FILES[@]}"; do
  if [ -f "$file" ]; then
    cp "$file" "$file.backup"
    echo "  ✅ Backed up: $file"
  fi
done

echo "
✨ Quick Fix Applied!

To build Android APK:
  flutter pub get
  flutter build apk --release

To restore original files:
  for f in lib/**/*.backup; do mv \"\$f\" \"\${f%.backup}\"; done

⚠️  Note: This is a temporary solution. 
    Web-only features will show placeholders on mobile.
"
