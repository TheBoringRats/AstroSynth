# 📱 AstroSynth Android Installation Guide

## Quick Install

### Method 1: Direct APK Install (Recommended)

1. **Locate the APK**:
   ```bash
   build/app/outputs/flutter-apk/app-release.apk
   ```

2. **Transfer to Android Device**:
   - Via USB cable
   - Via cloud storage (Google Drive, Dropbox)
   - Via email attachment
   - Via ADB (see below)

3. **Install on Device**:
   - Open the APK file on your Android device
   - Tap "Install"
   - Allow "Install from unknown sources" if prompted
   - Wait for installation to complete
   - Tap "Open" to launch AstroSynth!

### Method 2: Install via ADB

```bash
# Make sure device is connected via USB
# and USB debugging is enabled

adb install build/app/outputs/flutter-apk/app-release.apk
```

If you get "device already exists" error:
```bash
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

### Method 3: Run from Flutter (Development)

```bash
# Connect device via USB
# Enable USB debugging on device

# Run in debug mode
flutter run

# Or run in release mode
flutter run --release
```

## System Requirements

- **Android Version**: 5.0 (API 21) or higher
- **Storage**: ~100 MB free space
- **RAM**: 2 GB minimum (4 GB recommended)
- **Internet**: Optional (app works 100% offline)

## Permissions Required

The app requires minimal permissions:
- **Internet**: For NASA Eyes webview and optional API updates
- **Storage**: For caching planet data (optional)

## First Launch

1. **App launches** showing the planet browser
2. **Planet data loads** from bundled CSV (5000+ exoplanets)
3. **Browse planets** immediately - no account needed
4. **Explore features**:
   - Search by planet name
   - Filter by habitability, size, temperature
   - Sort by distance, name, size
   - View detailed information
   - Access NASA Eyes 3D viewer

## Troubleshooting

### Installation Failed
- Enable "Install from unknown sources" in Settings
- Make sure you have enough storage space
- Try rebooting your device

### App Won't Open
- Make sure your Android version is 5.0 or higher
- Clear app cache and try again
- Reinstall the app

### NASA Eyes Not Loading
- Check internet connection
- Clear webview cache in app settings
- Try again after a few minutes

### App Crashes
- Make sure you have at least 2 GB RAM
- Close other apps to free memory
- Reinstall the app

## Features Available on Mobile

✅ **Fully Working**:
- Browse 5000+ confirmed exoplanets
- Search and filter planets
- View detailed planet information
- NASA Eyes interactive 3D viewer
- Offline mode (100% functional)
- Favorites system

⚠️ **Limited on Mobile**:
- 3D Planet Viewer (shows placeholder)
- 3D World Viewer (shows placeholder)
- AI-Generated 3D (shows placeholder)

## Updating the App

To update to a newer version:
1. Uninstall the old version
2. Install the new APK
3. Your favorites may be lost (until persistent storage is added)

## Uninstalling

To remove the app:
1. Go to Settings → Apps
2. Find "AstroSynth"
3. Tap "Uninstall"
4. Confirm

## Building from Source

If you want to build the APK yourself:

```bash
# Clone the repository
git clone <repository-url>
cd AstroSynth

# Checkout mobile branch
git checkout mobile

# Get dependencies
flutter pub get

# Build APK
flutter build apk --release

# APK will be at:
# build/app/outputs/flutter-apk/app-release.apk
```

## Support

For issues or questions:
1. Check `ANDROID_BUILD_SUCCESS.md` for known issues
2. Review `MOBILE_BRANCH_STATUS.md` for feature status
3. Create an issue on GitHub

---

**Enjoy exploring the universe with AstroSynth! 🚀🌍**
