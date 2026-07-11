# ITEC Parking — Driver Portal (Project Guide)

A Flutter mobile app for Rwanda's **ITEC National Parking Management System**. Drivers use it to find parking sites, look up what a vehicle owes by plate number, pay parking fees with Mobile Money, and keep official receipts.

- **Package name:** `itec_parking` (Android app id `com.itec.parking`, iOS bundle `com.itec.itecParking`)
- **Backend:** ITEC Client API — `https://client-api.iteccone.com`
- **Framework:** Flutter (Dart SDK `>=3.0.0 <4.0.0`)

---

## 1. What the app does (main flows)

| Flow | Where | How it works |
|------|-------|--------------|
| **Sign in** | `login_screen` | Username/phone + password, plus Google & biometric (Face ID / fingerprint). Facebook/Apple are shown as "coming soon". |
| **Register** | `register_screen` | 3-step: phone + username → OTP → set name/email/password. |
| **Pay for parking** | `PayNowCard` → `plate_lookup_screen` → `payment_screen` | Enter a plate → the API returns what's owed → pay via Mobile Money (a prompt is sent to the payer's phone) → the app polls until the payment is confirmed. |
| **Browse sites** | `parking_list_screen` | Two sub-tabs: **All Sites** (list + pagination) and **Rates** (per-hour price, cheapest first). Tap a site for full pricing. |
| **Receipts** | `history_screen` → `receipt_detail_screen` | List of official receipts (table or card view), with a total-spent summary, date filter, and PDF download / share. |
| **Account** | `profile_screen` | Profile photo, phone management, biometric toggle, set password, support links, sign out. |

---

## 2. Tech stack

- **State management:** `provider` (`AppProvider` holds search + lookup state).
- **Networking:** `http`, wrapped by `ApiService`. Auth token stored via `flutter_secure_storage`.
- **Auth:** `google_sign_in`, `flutter_facebook_auth`, `sign_in_with_apple`, `local_auth` (biometrics).
- **Storage:** `shared_preferences` (caches, notifications), `flutter_secure_storage` (JWT + credentials).
- **UI:** `google_fonts` (Inter), `flutter_animate`, `shimmer`, custom theme in `app_theme.dart`.
- **Other:** `flutter_local_notifications`, `url_launcher` (maps, PDF, tel/mailto), `image_picker`, `share_plus`, `intl`, `country_code_picker`.

---

## 3. Project structure

```
lib/
├── main.dart                  App entry; MaterialApp + global text-scale clamp
├── app_navigation.dart        Global navigatorKey
├── theme/
│   └── app_theme.dart         Colors, typography, component themes (brand brown palette)
├── models/
│   └── models.dart            ParkingFacility, VehicleRecord, PricingData, HistoryEntry,
│                              AppNotification, PhoneNumber, AuthUser
├── providers/
│   └── app_provider.dart      Search query + vehicle-lookup/payment state
├── services/                  All backend + device integration
│   ├── api_service.dart       Parking, pricing, receipts, and the payment endpoints
│   ├── auth_service.dart      Login, token, biometric login, profile fetch
│   ├── social_auth_service.dart  Google/Facebook/Apple → backend callbacks
│   ├── phone_service.dart     User phone numbers
│   ├── profile_service.dart   Profile photo + local profile
│   ├── notification_service.dart  In-app + local notifications
│   └── history_service.dart   Local receipt/history cache
├── widgets/
│   ├── widgets.dart           Barrel (ItecLogo, etc.)
│   ├── pay_now_card.dart      Shared "Pay Now" hero (Home) / compact bar (Parking Site)
│   └── branded_loader.dart    Loading indicator
└── screens/
    ├── splash_screen.dart     Boot, restore session, biometric auto-login
    ├── main_layout.dart       Bottom nav shell (Home / Parking Site / Receipts / Account)
    ├── home_screen.dart       Dashboard: greeting, Pay Now, overview stats, site list
    ├── parking_list_screen.dart   Sub-tabbed site directory
    ├── parking_details_screen.dart  Per-site pricing + Navigate button
    ├── plate_lookup_screen.dart   Enter plate → see what's owed
    ├── payment_screen.dart    Mobile Money payment + status polling
    ├── history_screen.dart    Receipts (table/card)
    ├── receipt_detail_screen.dart  One receipt + PDF/share
    ├── profile_screen.dart    Account
    ├── notifications_screen.dart   Alerts (swipe to dismiss)
    └── auth/                   login, register, forgot_password, set_password, complete_profile
```

---

## 4. Backend API (endpoints actually used)

Base URL: `https://client-api.iteccone.com`. All authed requests send `Authorization: Bearer <JWT>`.

**Auth**
- `POST /auth/login` — username/email/phone + password → JWT
- `POST /auth/register/initiate` · `/verify-otp` · `/complete`
- `POST /auth/google/callback` · `/auth/facebook/callback` · `/auth/apple/callback` (need `X-Internal-Secret`)
- `POST /auth/phone/link/initiate` · `/verify` — attach a phone to a social account
- `POST /auth/password/set`

**Users** — `GET /users/me`, `GET/POST/DELETE /users/me/phones`

**Parking** — `GET /parking`, `GET /parking/{db-parking}`

**Pricing** — `GET /pricing/parking/{record_id}` (real per-hour tier table)

**Payment** (the core money flow)
- `POST /payment/lookup` — `{plate_no}` → matches with `amount_owed`, `payable`, `p_in_id`, `payment_type`, `db_id`
- `POST /payment/initiate` — sends the MoMo prompt → `{req_ref}`
- `GET /payment/status/{db_id}/{req_ref}` — poll until `SUCCESSFUL`

**Receipts** — `GET /receipts`, `GET /receipts/{db-id}` (includes `receipt_link` PDF)

> The Postman collection `ITEC park selfservice API 2` / `update_ ITEC_PARKING_API` documents the exact request/response shapes.

---

## 5. Configuration you must set up (per environment)

These are platform registrations, not code — the app is already wired for them:

- **Google Sign-In (Android):** register app id `com.itec.parking` + the release SHA-1 in Google Cloud Console.
- **Google Sign-In (iOS):** an iOS OAuth client is set in `ios/Runner/Info.plist` (`GIDClientID` + reversed URL scheme).
- **Backend audience:** `SocialAuthService` sets `serverClientId` to the **Web** client so the backend can verify Google ID tokens.
- **Facebook:** app id/token are in `AndroidManifest.xml` / `Info.plist`; register the key hash in the Facebook console to enable it.
- **Android package visibility:** `AndroidManifest.xml` has a `<queries>` block so `url_launcher` can open browsers, PDF viewers, dialer, and mail apps on Android 11+.

---

## 6. Running & building

```bash
flutter pub get
flutter analyze                 # should report: No issues found!
flutter run                     # run on a connected device/emulator

# Release build
flutter build apk --release     # → build/app/outputs/flutter-apk/app-release.apk
flutter build web               # → build/web
```

> The release APK is currently signed with the debug key — fine for testing/demo. Configure a proper release keystore in `android/app/build.gradle` before a Play Store submission.

---

## 7. Design system

- **Colors:** one brand family (brown `#7A5B40` + darker tones), neutrals (white/grays), and three semantic colors — success green, warning amber, danger red. Nothing else.
- **Type:** Inter (via `google_fonts`), defined in `AppTheme`.
- **Shape:** flat (no gradients), rounded cards, soft shadows.
- **Accessibility:** system font scaling is clamped to ≤1.25× app-wide (in `main.dart`) so large fonts never overflow a screen.

---

## 8. Status — what's live vs. pending backend

**Fully working against the API:** authentication (password, Google, biometric), parking directory, real per-site pricing, plate lookup, Mobile Money payment + confirmation, receipts with PDF, profile & phone management, notifications.

**Not built (no API yet — intentionally deferred):** reservations/booking, active-session timer, QR check-in, favorites, ratings/reviews, saved cards, interactive GPS map. When the backend adds these endpoints, they can be wired into the existing UI.

---

*Brand palette, warm brown/cream. Built with Flutter. For API request/response details, see the Postman collections that ship alongside this project.*
