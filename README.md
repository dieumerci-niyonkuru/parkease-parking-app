# ITEC Parking Mobile App (v2.0.26)

Official mobile application for the **ITEC National Parking Management System**. This production-ready application provides a high-security, high-performance portal for vehicle parking management, automated fee lookup, and secure digital payments.

## 🚀 Key Features

*   **Unified Brand Identity**: Integrated ITEC Brown (`#7A5B40`) theme with custom high-contrast UI components.
*   **Offline Data Availability**: Robust local caching for Parking Hubs and Receipts ensures data is accessible without internet.
*   **Biometric Security**: Integrated Fingerprint and Face ID authentication with encrypted credential storage.
*   **Universal Search**: Global header search that filters parking sites and history records in real-time.
*   **Flexible Auth**: Support for Login via Email, Username, or Phone Number.
*   **Fixed Global Navigation**: Persistent header and footer shell for a stable, professional user experience.
*   **Responsive Payment Portal**: Secure payment flow with support for MoMo, Airtel, and Cards, optimized for all screen sizes.

## 🛠 Tech Stack

*   **Framework**: Flutter (v3.0.0+)
*   **Architecture**: Provider-based State Management with a Stateful Shell (MainLayout).
*   **Local Storage**: 
    *   `shared_preferences` (JSON Caching)
    *   `flutter_secure_storage` (Biometric Enclave)
*   **Security**: `local_auth` for hardware biometrics.
*   **UI/UX**: `flutter_animate`, `google_fonts`, and custom Sliver-based layouts.

## 📦 Project Structure & Logic

For a detailed technical breakdown of the implementation logic, security architecture, and offline fallbacks, please refer to the internal documentation:
*   [**LOGIC_DOCUMENTATION.md**](./LOGIC_DOCUMENTATION.md)

## 🏗 Setup & Build

1.  **Dependencies**:
    ```bash
    flutter pub get
    ```
2.  **Run (Debug)**:
    ```bash
    flutter run
    ```
3.  **Build (Release APK)**:
    ```bash
    flutter build apk --release
    ```

---
© 2026 ITEC Parking · Rwanda. Final Production Version.
