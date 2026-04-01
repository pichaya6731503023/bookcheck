<div align="center">

<br>

<img src="assets/icon/Bookcheck.png" alt="Bookcheck" width="100" />

<h1>Bookcheck</h1>

<p><strong>A personal manga & comic collection tracker.<br>Track what you own, what you've read, and what you still need to buy.</strong></p>

<br>

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=flat-square&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?style=flat-square&logo=dart&logoColor=white)](https://dart.dev)
[![Firebase](https://img.shields.io/badge/Firebase-Firestore-FF6F00?style=flat-square&logo=firebase&logoColor=white)](https://firebase.google.com)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20Web-4CAF50?style=flat-square)](https://github.com)
[![License](https://img.shields.io/badge/License-MIT-9C27B0?style=flat-square)](LICENSE)
[![Analyze](https://img.shields.io/badge/flutter%20analyze-passing-brightgreen?style=flat-square)](https://flutter.dev)

<br>

</div>

---

## Overview

Bookcheck is a cross-platform Flutter application that helps manga and comic collectors manage their physical collections with precision. Built on Firebase, it syncs your data in real time across devices while keeping the UI fast and intuitive.

```
Track volumes  ·  Log reading progress  ·  Estimate collection value  ·  Plan purchases
```

---

## Features

### Collection Management
- Add, rename, and delete manga series
- Assign genre, publication status, and cover art per series
- Set total volume count per series
- Full-text search across title, genre, status, and notes

### Volume Tracking
- **Two-mode grid** — toggle between *Owned* and *Read* tracking independently
- Per-volume custom pricing override on top of a series default price
- Long-press a volume to set an individual price
- Animated volume grid with clear visual states

### Financial Overview
- Per-series and total collection value calculated automatically
- **Shopping List** — auto-generates missing volumes with estimated purchase cost
- Supports both default price and volume-specific prices in calculations

### User Experience
- Email/password authentication + Guest mode (no login required to browse)
- Real-time sync via Cloud Firestore
- Bilingual UI — English and Thai (preference saved locally)
- Animated loading screen on web

---

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Framework | Flutter 3.x + Dart 3.x |
| Auth | Firebase Authentication (Email/Password) |
| Database | Cloud Firestore (real-time NoSQL) |
| Storage | Base64 encoded in Firestore (< 800 KB per image) |
| Local State | `shared_preferences` (language preference) |
| Image Picker | `image_picker` with auto-compression |
| Env Config | `--dart-define-from-file` (no `.env` in repo) |

---

## Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) `>=3.0.0`
- A [Firebase project](https://console.firebase.google.com) with **Authentication**, **Firestore**, and **Storage** enabled
- Android Studio or VS Code

### 1 — Clone the repository

```bash
git clone https://github.com/pichaya6731503023/bookcheck.git
cd bookcheck
flutter pub get
```

### 2 — Configure environment

```bash
# Copy the template
cp .env.example .env

# Open .env and fill in your Firebase values
# (Project Settings → Your apps → SDK setup and configuration)
```

Your `.env` file should look like this:

```ini
# Android
ANDROID_API_KEY=AIzaSy...
ANDROID_APP_ID=1:000000000000:android:xxxxxxxxxxxxxxxx

# Web
WEB_API_KEY=AIzaSy...
WEB_APP_ID=1:000000000000:web:xxxxxxxxxxxxxxxx
WEB_AUTH_DOMAIN=your-project.firebaseapp.com
WEB_MEASUREMENT_ID=G-XXXXXXXXXX

# Shared
MESSAGING_SENDER_ID=000000000000
PROJECT_ID=your-project-id
STORAGE_BUCKET=your-project.firebasestorage.app
```

### 3 — Run

```bash
# Development
flutter run --dart-define-from-file=.env

# Release — Android APK
flutter build apk --dart-define-from-file=.env --release

# Release — Web
flutter build web --dart-define-from-file=.env
```

---

## Project Structure

```
bookcheck/
├── lib/
│   ├── main.dart                      # Entry point, theme, auth stream
│   ├── firebase_options.dart          # Firebase config via dart-define
│   ├── globals.dart                   # Theme color, language helpers
│   └── screens/
│       ├── login_screen.dart          # Email/password login
│       ├── register_screen.dart       # New account creation
│       ├── home_screen.dart           # Series list, search, sort
│       ├── volume_manager_screen.dart # Volume grid, read/owned tracking
│       ├── profile_screen.dart        # Stats, value summary, settings
│       └── shopping_list_screen.dart  # Missing volumes + cost estimate
│
├── android/                           # Android native project
│   └── app/
│       ├── build.gradle.kts
│       └── google-services.json       # Safe to commit — see Security below
│
├── web/
│   ├── index.html                     # PWA entry + animated loader
│   └── manifest.json
│
├── assets/icon/                       # App icon source
│
├── .env                               # Local secrets — gitignored ⚠️
├── .env.example                       # Template — safe to commit ✅
├── .gitignore
└── pubspec.yaml
```

---

## Database Schema

```
Firestore
└── books/                         (collection)
    └── {docId}/                   (one document per series per user)
        ├── userId          string
        ├── title           string
        ├── genre           string   — Action | Romance | Sci-Fi | etc.
        ├── status          string   — Ongoing | Completed | Hiatus
        ├── maxVolumes      number
        ├── ownedVolumes    number[] — volumes physically owned
        ├── readVolumes     number[] — volumes read
        ├── price           number   — default price per volume
        ├── specificPrices  map      — { "3": 159, "12": 200, ... }
        ├── imageUrl        string   — base64 encoded cover image
        ├── note            string
        └── createdAt       timestamp
```

---

## Security

Firebase keys are never stored in source control. The app uses Dart's `--dart-define-from-file` to inject configuration at compile time.

| File | Committed | Reason |
|------|-----------|--------|
| `.env` | ❌ No | Contains real API keys |
| `.env.example` | ✅ Yes | Empty template, safe |
| `firebase_options.dart` | ✅ Yes | Uses `String.fromEnvironment()` — no hardcoded values |
| `google-services.json` | ✅ Yes | Contains only project identifiers, [designed for VCS by Firebase](https://firebase.google.com/docs/projects/learn-more#config-files-objects) |

> **Note:** If you fork this project, generate your own Firebase project. Do not reuse the project IDs in `.env.example`.

---

## Platform Support

| Platform | Status | Notes |
|----------|--------|-------|
| Android | ✅ Supported | Min SDK 21 (Android 5.0+) |
| Web | ✅ Supported | PWA-ready with manifest |
| iOS | ⚠️ Not configured | FlutterFire CLI reconfiguration required |
| macOS / Windows / Linux | ⚠️ Not configured | FlutterFire CLI reconfiguration required |

---

## Contributing

Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change.

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/your-feature`)
3. Commit your changes (`git commit -m 'Add your feature'`)
4. Push to the branch (`git push origin feature/your-feature`)
5. Open a Pull Request

---

## License

[MIT](LICENSE) — © 2024 Bookcheck

---

<div align="center">

Built with [Flutter](https://flutter.dev) · Powered by [Firebase](https://firebase.google.com)

</div>
