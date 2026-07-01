#!/bin/bash
# ================================================================
# ITEC Parking - Build APK Script
# Run this from inside the itec_parking folder
# ================================================================

echo "================================================"
echo "  ITEC Parking - APK Builder"
echo "================================================"

# Add ADB to PATH (in case it's not there)
export PATH="$LOCALAPPDATA/Android/Sdk/platform-tools:$PATH"

echo ""
echo "[1/3] Getting dependencies..."
flutter pub get

if [ $? -ne 0 ]; then
  echo "ERROR: flutter pub get failed. Check your internet connection."
  exit 1
fi

echo ""
echo "[2/3] Building APK (release)..."
flutter build apk --release

if [ $? -ne 0 ]; then
  echo ""
  echo "Release build failed. Trying debug APK..."
  flutter build apk --debug
fi

if [ $? -eq 0 ]; then
  echo ""
  echo "================================================"
  echo "  BUILD SUCCESSFUL!"
  echo "  APK is at:"
  echo "  build/app/outputs/flutter-apk/app-release.apk"
  echo "  (or app-debug.apk if debug)"
  echo "================================================"
  
  # Open the output folder in Explorer
  if command -v explorer.exe &> /dev/null; then
    explorer.exe "$(wslpath -w build/app/outputs/flutter-apk/ 2>/dev/null || echo build/app/outputs/flutter-apk/)"
  fi
else
  echo "ERROR: Build failed. Check errors above."
fi
