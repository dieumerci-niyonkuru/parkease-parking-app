# ITEC Parking — Setup & Build Guide

## Quick Start (Build APK)

1. Open Git Bash
2. `cd` into this folder
3. Run:

```bash
export PATH="$LOCALAPPDATA/Android/Sdk/platform-tools:$PATH"
flutter pub get
flutter build apk --release
```

APK will be at: `build/app/outputs/flutter-apk/app-release.apk`

---

## Before Building — Check local.properties

Open `android/local.properties` and confirm paths match your PC:

```properties
sdk.dir=C:\\Users\\Merci\\AppData\\Local\\Android\\sdk
flutter.sdk=C:\\src\\flutter
```

To find your Flutter SDK path, run: `flutter --version` and note the path.
To find your Android SDK path, run: `echo $LOCALAPPDATA/Android/Sdk`

---

## Run on Emulator (no APK needed)

```bash
flutter emulators --launch Pixel_6_API_33
flutter run
```

---

## Install APK on Phone

Once the APK is built:
1. Copy `build/app/outputs/flutter-apk/app-release.apk` to your phone
2. Open it on your phone (allow "Install unknown apps" if prompted)

OR install via USB (once phone is connected):
```bash
adb install build/app/outputs/flutter-apk/app-release.apk
```

---

## What Was Fixed

- Removed conflicting `build.gradle.kts` / `settings.gradle.kts` (Kotlin DSL conflict)
- Removed duplicate `MainActivity.kt` with wrong namespace (`com.itec.itec_parking`)
- Fixed AGP version mismatch (settings.gradle now uses 8.1.0 to match build.gradle)
- Added missing `ic_launcher_round` icons for all densities
- Added `drawable-v21/launch_background.xml` for Android 5+ splash
- Fixed CRLF line endings in all Dart/Gradle files
- Removed stale `.gradle` and `build` cache directories
- Removed asset directory declarations that had no actual files (prevents build error)
- Cleaned `debug` `applicationIdSuffix` that could cause install conflicts
