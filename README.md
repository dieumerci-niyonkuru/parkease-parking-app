# 🅿️ ITEC Parking — Driver Portal

A Flutter mobile app for Rwanda's **ITEC National Parking Management System**. Drivers find parking sites, look up what a vehicle owes by plate number, pay parking fees with Mobile Money, and keep official digital receipts.

<p>
  <img alt="Flutter" src="https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white">
  <img alt="Dart" src="https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart&logoColor=white">
  <img alt="Platform" src="https://img.shields.io/badge/Platform-Android%20%7C%20iOS-lightgrey">
  <img alt="Version" src="https://img.shields.io/badge/version-1.0.0-A8845B">
</p>

---

## ✨ Features

- **Secure sign-in** — username/phone + password, Google Sign-In, and biometric (Face ID / fingerprint).
- **Pay for parking** — enter a plate → the app validates it and shows what's owed → pay instantly via **Mobile Money** (MoMo prompt + live status polling).
- **Browse parking sites** — searchable, sortable directory (Recommended / Most Available / Cheapest / A–Z) with sub-tabs for **All Sites** and **Rates**.
- **Real pricing** — per-hour rate tiers and a fee estimator, shown **exactly as returned by the API** (nothing calculated on the device).
- **Digital receipts** — full-detail receipt with Parking / Session / Payment breakdown, PDF download and share; searchable history by plate, site, or receipt number.
- **Account** — profile & photo, phone-number management, change password (current → new → confirm), notifications.
- **Polished UX** — flat brand design, swipeable tabs, notifications with swipe-to-dismiss, offline handling, session-expiry auto-logout, and app-wide text-scaling limits so nothing overflows.

---

## 🧾 How paying works

1. Tap **Pay Now** and enter the vehicle plate.
2. The app calls `POST /payment/lookup` — the API returns the current **amount owed** (which keeps growing while the vehicle stays parked and unpaid).
3. On a valid, payable plate, you go straight to payment; enter the phone that will receive the MoMo prompt.
4. The app calls `POST /payment/initiate` (the **server** computes the charge — the app never sends an amount) and polls `GET /payment/status/{db_id}/{req_ref}` until it's **SUCCESSFUL**.
5. A digital receipt is generated using the **server's exact charged amount**.

> Postpaid/company-account vehicles are blocked from self-payment (`payable: false`) with a clear message to see the attendant.

---

## 🔌 Backend API

Base URL: `https://client-api.iteccone.com` · all authed requests send `Authorization: Bearer <JWT>`.

| Area | Endpoints |
|------|-----------|
| **Auth** | `/auth/login`, `/auth/register/*`, `/auth/{google,facebook,apple}/callback`, `/auth/phone/link/*`, `/auth/password/set` |
| **Users** | `GET /users/me`, `GET/POST/DELETE /users/me/phones` |
| **Parking** | `GET /parking`, `GET /parking/{db-parking}` |
| **Pricing** | `GET /pricing/parking/{record_id}`, `GET /pricing/categories/{db_id}` |
| **Payment** | `POST /payment/lookup`, `POST /payment/initiate`, `GET /payment/status/{db_id}/{req_ref}` |
| **Receipts** | `GET /receipts`, `GET /receipts/{db-id}` |

Full request/response shapes are in the Postman collection shipped alongside this project.

---

## 🗂️ Project structure

```
lib/
├── main.dart                 App entry (+ global text-scale clamp)
├── theme/app_theme.dart      Colors, typography, component themes
├── models/models.dart        ParkingFacility, VehicleRecord, PricingData, HistoryEntry, …
├── providers/app_provider.dart   Search + lookup/payment state, session-expiry handling
├── services/                 api_service, auth_service, social_auth_service,
│                             phone_service, profile_service, notification_service
├── widgets/                  Shared widgets (PayNowCard, loaders, logo)
└── screens/                  splash, main_layout (bottom nav), home, parking_list,
                              parking_details, plate_lookup, payment, history,
                              receipt_detail, profile, notifications, auth/*
```

---

## 🚀 Getting started

```bash
flutter pub get
flutter analyze          # expect: No issues found
flutter run              # run on a connected device / emulator
```

### Build

```bash
flutter build apk --release     # → build/app/outputs/flutter-apk/app-release.apk
flutter build web               # → build/web
```

> The release APK is signed with the debug key for testing/demo. Configure a proper release keystore in `android/app/build.gradle` before a Play Store submission.

---

## ⚙️ Platform configuration

These are console registrations (not code — the app is already wired for them):

- **Google Sign-In (Android):** register `com.itec.parking` + the release SHA-1 in Google Cloud Console.
- **Google Sign-In (iOS):** iOS OAuth client is set in `ios/Runner/Info.plist` (`GIDClientID` + reversed URL scheme); the backend audience uses the **Web** client via `serverClientId`.
- **Facebook:** app id/token are in the manifests; register the key hash in the Facebook console to enable it.
- **Deep-link visibility:** Android `<queries>` and iOS `LSApplicationQueriesSchemes` are configured so tap-to-call, email, maps, and web links work.

---

## 🎨 Design system

- **Colors:** brand brown (`#7A5B40` family) + neutrals + three semantic colors (success green, warning amber, error red).
- **Type:** Inter via `google_fonts`.
- **Style:** flat (no gradients), rounded cards, soft shadows, warm brown/cream palette.

---

## 📌 Status

**Live against the API:** authentication, parking directory, real pricing, plate lookup, Mobile Money payment + confirmation, receipts with PDF, profile & phone management, notifications.

**Deferred (no API yet):** reservations/booking, active-session timer, QR check-in, favorites, ratings/reviews, saved cards, interactive GPS maps. When those endpoints exist, they slot into the existing UI.

---

<sub>Built with Flutter · ITEC Parking · Version 1.0.0</sub>
