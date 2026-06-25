# Assets

This directory contains app assets.

## Structure

```
assets/
├── images/        # PNG/JPG images
├── animations/    # Lottie JSON animation files  
├── icons/         # SVG icons
└── fonts/         # Custom font files (SpaceGrotesk)
```

## Fonts

Download Space Grotesk from Google Fonts and place in `assets/fonts/`:
- SpaceGrotesk-Regular.ttf
- SpaceGrotesk-Medium.ttf  
- SpaceGrotesk-SemiBold.ttf
- SpaceGrotesk-Bold.ttf

Or remove the custom font declaration from `pubspec.yaml` to use system fonts.
The app falls back gracefully to the system font if files are missing.
