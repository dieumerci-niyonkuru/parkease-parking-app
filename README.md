# ITEC Parking Mobile App

Official mobile application for the ITEC National Parking Management System. This production-ready app provides drivers with a seamless experience for finding parking hubs, tracking parking history, and performing secure payments.

## 🚀 Key Features

*   **Unified Brand Identity**: Standardized Brownian theme (`#7A5B40`) across all UI components.
*   **Offline Data Persistence**: Full access to parking receipts and history even without an internet connection using local JSON caching.
*   **Biometric Security**: Secure login using Fingerprint (Android) and Face ID (iOS).
*   **Flexible Authentication**: Support for signing in via Email, Username, or Phone Number.
*   **Real-time Plate Lookup**: Instantly retrieve active parking sessions and amounts due by entering a plate number.
*   **Secure Payments**: Integrated payment gateway support for MoMo, Airtel Money, and Bank Cards.
*   **Fixed Global Navigation**: Persistent header and footer architecture for stable navigation while scrolling.
*   **Real-time Notifications**: Background updates and local notifications for parking status.

## 🛠 Tech Stack

*   **Framework**: Flutter (Dart)
*   **State Management**: Provider
*   **Storage**: 
    *   `shared_preferences` (Offline Cache)
    *   `flutter_secure_storage` (Encrypted Credentials)
*   **Security**: `local_auth` (Biometrics)
*   **API**: ITEC Client API 2.0 Integration
*   **UI/UX**: Custom Sliver layouts, Flutter Animate, and Google Fonts.

## 📦 Getting Started

### Prerequisites
*   Flutter SDK (v3.0.0+)
*   Android Studio / VS Code
*   A physical device or emulator (Physical device recommended for Biometrics)

### Installation
1.  Clone the repository:
    ```bash
    git clone https://github.com/dieumerci-niyonkuru/parkease-parking-app.git
    ```
2.  Navigate to the project directory:
    ```bash
    cd itec_parking_fixed
    ```
3.  Install dependencies:
    ```bash
    flutter pub get
    ```
4.  Run the application:
    ```bash
    flutter run
    ```

## 📄 Documentation
For detailed architectural decisions and logic implementation, please refer to:
*   [LOGIC_DOCUMENTATION.md](./LOGIC_DOCUMENTATION.md) - Deep dive into brand unification, offline logic, and security integration.

## ⚖️ Legal
© 2026 ITEC Parking · Rwanda. All rights reserved.
