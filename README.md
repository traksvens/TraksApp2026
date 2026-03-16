# Traks Flutter App

This directory contains the Flutter client for Traks. The app is responsible for authentication, the incident feed, map discovery, post creation, replies and ratings, profile management, SOS contact management, and the subscription handoff into the payment UI.

## What The App Does

The app supports these main user-facing flows:

- sign in with email/password or Google
- browse incident reports in a feed
- create posts with coordinates and optional media
- open post details, replies, and community ratings
- search for nearby incidents on the map
- use an AI-assisted map experience when Gemini is configured
- manage profile settings, theme, and SOS contacts
- upgrade to premium or reporter tiers through the payment UI

## High-Level Flow

1. `lib/main.dart` initializes `.env`, Firebase, dependency injection, and hydrated storage.
2. `lib/presentation/splash/splash_screen.dart` shows the launch animation and forwards into auth.
3. `lib/presentation/auth/auth_wrapper.dart` switches between `LoginPage` and `HomePage`.
4. `lib/presentation/home/home_page.dart` becomes the main container for Home, Map, Profile, and conditional Premium tabs.

## Architecture

### State Management

- `flutter_bloc` is used for authentication, posts, search, location, and map navigation state.
- `hydrated_bloc` persists selected state locally, including parts of the post and location state.
- `get_it` is used for dependency injection from `lib/injection_container.dart`.
- Theme state is handled separately through `ThemeController`.

### Backend Split

- Firebase Auth handles sign-in.
- Firestore stores user profile and verification-related data.
- The FastAPI backend handles posts, replies, ratings, SOS contacts, proximity search, and semantic search.
- Google Maps, Places, and Directions APIs are used for map-related features.
- `PaymentUi/` handles the browser-based payment experience for upgrades.

## Key Directories

| Path | Purpose |
| --- | --- |
| `lib/main.dart` | App bootstrap and global providers. |
| `lib/injection_container.dart` | Dependency registration. |
| `lib/presentation/` | Screens, blocs, and UI widgets. |
| `lib/core/services/` | API, user, location, places, and directions services. |
| `lib/repository/` | Repository interfaces and implementations. |
| `lib/data/models/` | App-side data models for posts, replies, SOS, users, and search. |
| `PaymentUi/` | React/Vite payment frontend used during subscription upgrades. |
| `android/` | Android app configuration, deep links, permissions, and native map metadata. |

## Environment Variables

The app loads `.env` at startup and also includes it as a Flutter asset.

| Variable | Purpose |
| --- | --- |
| `API_BASE_URL` | Base URL for the FastAPI backend. |
| `PAYMENT_UI_BASE_URL` | Base URL for the payment frontend. |
| `GOOGLE_MAPS_API_KEY` | Google Maps key used by app map services. |
| `GEMINI_API_KEY` | Enables the AI-assisted map experience. |
| `GEMINI_MODEL` | Gemini model name for map AI calls. |
| `FIREBASE_API_KEY` | Android Firebase config. |
| `FIREBASE_APP_ID` | Android Firebase app ID. |
| `FIREBASE_MESSAGING_SENDER_ID` | Firebase messaging sender ID. |
| `FIREBASE_PROJECT_ID` | Firebase project ID. |
| `FIREBASE_STORAGE_BUCKET` | Firebase Storage bucket. |

Example local `.env`:

```env
API_BASE_URL=http://10.0.2.2:8000
PAYMENT_UI_BASE_URL=http://localhost:5173
GOOGLE_MAPS_API_KEY=your_google_maps_client_key
GEMINI_API_KEY=your_gemini_api_key
GEMINI_MODEL=gemini-3.1-flash-lite-preview
FIREBASE_API_KEY=your_firebase_api_key
FIREBASE_APP_ID=your_firebase_app_id
FIREBASE_MESSAGING_SENDER_ID=your_firebase_sender_id
FIREBASE_PROJECT_ID=your_firebase_project_id
FIREBASE_STORAGE_BUCKET=your_firebase_storage_bucket
```

## Local Setup

### Install Dependencies

```bash
cd TraksApp2026
flutter pub get
```

### Configure Android Maps

The Android manifest currently contains a native Google Maps API key entry in `android/app/src/main/AndroidManifest.xml`. Keep that value aligned with your environment strategy.

### Run The App

```bash
cd TraksApp2026
flutter run
```

### Backend Pairing

For local Android emulator work, use:

```env
API_BASE_URL=http://10.0.2.2:8000
```

If you are using a physical device, replace that with your machine's LAN IP.

## Payment Flow

- `lib/presentation/subscription/subscription_page.dart` builds the upgrade URL.
- `PaymentUi/src/App.jsx` handles the web checkout flow.
- The app listens for `traksapp://payment` deep links after the payment handoff.

## Supported Platforms

The current app configuration is Android-first.

- Android: configured
- Web: partial artifacts exist, but Firebase options are not configured as a supported target
- iOS/macOS/windows/linux: not configured in `lib/firebase_options.dart`

## Important Notes

- The generated backend contract should be treated as the source of truth for API integration: use the running API's `/docs`.
- Some integration gaps still exist between the Flutter client and the backend, especially in SOS and payment verification flows.
- See the workspace-level docs in `../docs/` for shared product, architecture, and known-gap context.
