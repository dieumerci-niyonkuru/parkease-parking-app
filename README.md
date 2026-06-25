# 🅿 ITEC Parking — Rwanda National Parking Driver Portal

Official Flutter mobile application for the ITEC National Parking Management System.  
Built for Android — professional, fast, and production-ready.

---

## 📱 Screenshots & Flow

```
Splash → Dashboard → EBM (Facilities) → Lookup → Vehicle Detail → Pay → Receipt
                                      ↘ History → Re-lookup
                                      ↘ Notifications
```

---

## ✨ Features

| Feature | Details |
|---|---|
| **No Login Required** | Driver opens app → straight to dashboard |
| **EBM Browser** | All parking facilities with search, filter, live counts |
| **Park Slot Lookup** | Enter `DB-ID` (e.g. `1-101`) → full vehicle info |
| **Vehicle Details** | Plate, owner name, phone, email, vehicle make/type/color |
| **Entry & Exit Dates** | Full date + time for entry; exit populated on payment |
| **Live Timer** | Real-time duration counter that updates every second |
| **Live Amount** | Fee recalculates live (RWF 500/hr, ceiling per minute) |
| **Payment** | One-tap payment → receipt with full breakdown |
| **Receipt** | Plate, owner, parking, entry/exit, duration, receipt number |
| **History** | Persistent lookup history with search, swipe-to-delete |
| **Notifications** | Push + in-app: lookup found, payment confirmed, long stay |
| **Dark Theme** | Full dark UI — `#080C14` deep background |
| **Animations** | Shimmer loaders, slide/fade transitions, live pulse |

---

## 🚀 Quick Start

### Prerequisites
- Flutter SDK ≥ 3.0.0
- Android Studio / VS Code with Flutter extension
- Android device or emulator (API 24+)

### Setup

```bash
# 1. Clone / download and enter project
cd itec_parking

# 2. Install dependencies
flutter pub get

# 3. Generate Hive adapters (optional — pre-generated included)
flutter pub run build_runner build --delete-conflicting-outputs

# 4. Run on connected Android device
flutter run

# 5. Build release APK
flutter build apk --release
# → build/app/outputs/flutter-apk/app-release.apk
```

### Run on specific device
```bash
flutter devices                    # list available
flutter run -d <device-id>         # run on specific device
flutter run --release              # release mode
```

---

## 🗂 Project Structure

```
lib/
├── main.dart                      # App entry + Provider setup
├── theme/
│   └── app_theme.dart             # Colors, typography, ThemeData
├── models/
│   ├── models.dart                # ParkingFacility, VehicleRecord, HistoryEntry
│   └── models.g.dart              # Hive type adapters
├── services/
│   ├── api_service.dart           # HTTP → ITEC API + mock fallback
│   ├── history_service.dart       # SharedPreferences persistence
│   └── notification_service.dart  # Push + in-app notifications
├── providers/
│   └── app_provider.dart          # ChangeNotifier state management
├── utils/
│   └── app_utils.dart             # Formatters, validators, helpers
├── widgets/
│   └── widgets.dart               # GradientButton, DataField, SkeletonCard, etc.
└── screens/
    ├── splash_screen.dart         # Animated boot screen
    ├── dashboard_screen.dart      # Home tab + bottom nav
    ├── ebm_screen.dart            # Facilities list + detail sheet
    ├── lookup_screen.dart         # ★ Core: search, validate, results, pay
    ├── history_screen.dart        # Persistent history + swipe-delete
    └── notifications_screen.dart  # Notification center
```

---

## 🔌 API Integration

Base URL: `https://client-api.iteccone.com`

| Endpoint | Used For |
|---|---|
| `GET /parking` | All facilities list (EBM) |
| `GET /parking/:recordId` | Single facility detail |

All API calls fall back to built-in mock data when offline or if the server is unreachable — the app always works.

### Slot ID Format
`{dbId}-{parkingId}` — e.g. `1-101`, `2-104`, `3-106`

---

## 💰 Pricing

Default rate: **RWF 500 / hour** (ceiling per partial hour)

To change: update `ratePerHour` in `models.dart` → `VehicleRecord.fromMock()`.

---

## 📦 Key Dependencies

```yaml
flutter_animate: ^4.5.0          # Smooth animations
shimmer: ^3.0.0                  # Skeleton loading effects
provider: ^6.1.2                 # State management
shared_preferences: ^2.2.3       # History persistence
flutter_local_notifications      # Push notifications
flutter_slidable: ^3.1.1         # Swipe-to-delete in history
google_fonts: ^6.2.1             # Space Grotesk typography
intl: ^0.19.0                    # Date/currency formatting
http: ^1.2.1                     # API calls
uuid: ^4.4.0                     # Receipt number generation
```

---

## 🏗 Build for Production

```bash
# Release APK (install directly on device)
flutter build apk --release --target-platform android-arm64

# App Bundle (for Play Store)
flutter build appbundle --release
```

APK location: `build/app/outputs/flutter-apk/app-release.apk`

---

## 🧪 Testing

```bash
flutter test                       # Run all tests
flutter analyze                    # Static analysis
flutter doctor                     # Check environment
```

---

## 📋 Screens Reference

### Splash
- Animated logo scale-in
- Progress bar with live status messages
- Auto-navigates to Dashboard after init

### Dashboard (Home)
- Live stats: facilities count, total lots, lookup count
- Quick action cards: Browse EBM / Lookup
- Recent activity from history
- Live system status pulse

### EBM (Facilities)
- Search by name, address, or Record ID
- Tap card → bottom sheet with full details
- "Look Up Here" shortcut prefills Lookup

### Lookup ★
- Progress steps indicator (Enter → Validate → View → Pay)
- Real-time input validation (format: `1-101`)
- Vehicle result shows: plate, owner, phone, email, make, type, color, spot
- **Entry date + time** and **Exit date + time**
- Live duration ticker (updates every second)
- Live amount display (recalculates in real time)
- Pay button → processing animation → receipt bottom sheet

### History
- Search by plate, owner, parking, phone
- Shows entry date/time, exit date/time, duration, amount
- Status badges: Parked / Paid / Exited
- Swipe left to delete individual entry
- "Clear All" with confirmation dialog

### Notifications
- In-app notification center
- Types: Payment confirmed, Long stay alert, Vehicle found, System
- Unread badge count on home tab
- Mark all read on open / Clear all

---

## 📱 Android Requirements

- **Min SDK**: API 24 (Android 7.0)
- **Target SDK**: API 34 (Android 14)
- **Permissions**: INTERNET, POST_NOTIFICATIONS, VIBRATE
- **Orientation**: Portrait locked

---

## 🇷🇼 About

Built for Rwanda's National Parking Management System by ITEC.  
Designed for high-volume daily use by parking operators across the country.

© 2025 ITEC Rwanda. All rights reserved.
