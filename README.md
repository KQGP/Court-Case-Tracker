# Court Case Tracker

A cross-platform (Flutter) **Court Case Folder Management System** for tracking court cases, their folders, sessions, transfers, and users. The UI is in Arabic (RTL) and works offline-first with Firebase Firestore sync.

## ✨ Features

- 🔐 Authentication (Firebase Auth + Google Sign-In)
- 📁 Case management: create, edit, view, list cases with case number & summary
- 👥 User management with roles
- 🔄 Folder transfers between users with return tracking
- 📅 Sessions list
- 🖨️ PDF printing of case details
- 🔔 Overdue folder alerts (configurable threshold) + push notifications (FCM)
- 📴 Offline queue (Hive) with auto-sync when connectivity returns
- 🔗 Deep links (`/case/<id>`)
- 📱 QR code generation
- ⚙️ Settings (notification preferences, overdue threshold)

## 🧱 Tech Stack

- **Flutter** (Dart SDK ^3.12)
- **State management:** Riverpod
- **Backend:** Firebase (Auth, Firestore, Messaging)
- **Local storage:** Hive
- **Other:** connectivity_plus, qr_flutter, pdf/printing, app_links, intl, uuid, flutter_slidable

## 📁 Project Structure

```
lib/
├── main.dart
├── app/          # App widget & routes
├── models/       # Case, History, Notification, Session, Transfer, User
├── providers/    # Riverpod providers
├── screens/      # UI screens (cases, users, sessions, transfers, settings, print, dashboard, login, setup)
├── services/     # Auth, Firestore, Notification, Offline sync, Print, Session
├── utils/        # Constants, helpers, validators
└── widgets/      # Reusable widgets
```

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (Dart ^3.12)
- Firebase project with Auth, Firestore, Messaging enabled
- A configured `firebase_options.dart` (generated via FlutterFire CLI)

### Install & Run
```bash
flutter pub get
flutter run
```

For Firebase setup, place your `google-services.json` (Android) / `GoogleService-Info.plist` (iOS) and regenerate `lib/firebase_options.dart`.

### Build
```bash
flutter build apk        # Android
flutter build ios        # iOS
flutter build web        # Web
```

## ⚙️ Configuration
- Locale is fixed to Arabic (Saudi Arabia) with RTL layout and the Cairo font.
- Overdue threshold (days) and notification toggles are configurable in Settings and stored in Firestore (`settings`).

## 📄 License
No license specified. Add a `LICENSE` file if you intend to open-source.