# ITEC Parking Mobile - Implementation Documentation (Version 2.0.26)

This document outlines the architectural and logic enhancements implemented for the ITEC Parking mobile application. The implementation focuses on **brand unification**, **offline resilience**, **security**, and **UI stability**.

---

## 1. Brand Identity & Theme Unification
### **Implementation Logic:**
*   **Primary Brand Color**: Standardized the app's primary palette to **ITEC Brown** (`#7A5B40`). This is defined in `AppTheme` and applied to all Material 3 components.
*   **Custom Branded Loader**: Developed the `BrandedLoader` widget. It utilizes a `CircularProgressIndicator` with a specific dark-grey color (`#212529`) and a stylized **ITEC PARKING** header with high letter-spacing (4.0).
*   **Animated Transitions**: Integrated `flutter_animate` to provide fade and slide entries for all major UI cards, ensuring a premium feel.

---

## 2. Navigation & Global Layout
### **Implementation Logic:**
*   **Stateful Shell (MainLayout)**: Utilized `IndexedStack` to host the primary app sections (Home, Lookup, History, Profile). This ensures that user state (scroll position, input fields) is preserved when switching tabs.
*   **Fixed Global Header**: The `AppBar` is centralized in `MainLayout`. It dynamically updates the subtitle (e.g., DASHBOARD, RECEIPTS) based on the active index.
*   **Universal Search Logic**:
    *   The header search bar updates a global `searchQuery` in the `AppProvider`.
    *   **Home Screen**: Filters the `ParkingHub` list in real-time.
    *   **History Screen**: Filters the `HistoryEntry` list (by plate or site name) in real-time.

---

## 3. Biometric Security Architecture
### **Implementation Logic:**
*   **Hardware Integration**: Utilizes `local_auth` for Fingerprint and Face ID.
*   **Android Compatibility**: Configured `MainActivity.kt` to extend `FlutterFragmentActivity`, enabling the biometric prompt system on Android.
*   **Secure Enclave Storage**: Login credentials (username/password) are encrypted and stored in the device's **Secure Enclave** using `FlutterSecureStorage` (`_keyCreds`).
*   **Biometric Login Flow**: Tapping the biometric icon triggers `AuthService.loginWithBiometrics()`, which retrieves the encrypted credentials and performs a secure background authentication.

---

## 4. Offline Data Persistence & API 2.0
### **Implementation Logic:**
*   **Defensive Sanitization**: `ApiService` includes logic to handle inconsistent JSON responses. It specifically checks if the returned data field is a `List` (`val is List ? val : []`) before parsing, preventing subtype crashes.
*   **SharedPreferences Caching**: 
    *   Successfully fetched data is cached using `prefs.setString` with unique keys (`cached_parking_v1`, `cached_receipts_v1`).
    *   On network failure, the `ApiService` catches the exception and returns the `cached` string, ensuring the UI remains populated.
*   **Status Interceptor**: Implemented `lastFetchSuccessful` and `_checkStatus(401)` to handle offline banners and auto-logout on session expiration.

---

## 5. UI Stability & UX Optimizations
### **Implementation Logic:**
*   **Overflow Resolution**: Replaced fixed-height `Column` and `Container` layouts with `SingleChildScrollView` or `CustomScrollView` (using `SliverToBoxAdapter`).
*   **Safe-Area Buffering**: Standardized a **120-pixel bottom buffer** (`SliverPadding`) on all major lists to ensure the last item is never obscured by the floating `BottomNavigationBar`.
*   **Payment Flow Safety**: Added a prominent **"CANCEL & GO BACK"** `OutlinedButton` in the payment portal for immediate exit.
*   **High-Contrast Inputs**: Standardized all `TextField` components with a white background, dark-grey text, and mono-spaced fonts for plate numbers to ensure maximum readability in low-light conditions.

---

**Technical Documentation finalized for ITEC Parking Mobile v2.0.26.**
**Implementation verified against Production Build fa737f3.**
