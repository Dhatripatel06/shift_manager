# VD Shift Manager 🕐

**Track shifts. Track growth.**

A premium Flutter application for Vishrut Donda to manage daily shift jobs, working hours, and earnings professionally.

---

## ✨ Features

### 🔐 Authentication
- Google Sign In (Firebase Auth)
- Persistent login / Auto-login
- Secure sign out

### 📊 Dashboard
- **Earnings Overview**: Weekly & monthly earnings cards
- **Live Dual Clocks**: 🇮🇳 India Time / 🇬🇧 London Time (updates every second)
- **Recent Shifts**: Quick view of latest shifts
- **Stats at a Glance**: Total shifts, hours worked, earnings

### 📝 Shift Management (CRUD)
- **Add Shift**: Beautiful form with date/time pickers
- **Edit Shift**: Pre-populated form with existing data
- **Delete Shift**: Confirmation dialog, soft-delete with sync
- **Auto Calculations**: Net Hours & Total Pay computed instantly
- **Fields**: Date, Event Name, Job Role, Start/End Time, Break Hours, Pay/Hr, Notes

### 🔍 Filters & Search
- Filter by: All | Today | This Week | This Month
- Search by event name or job role

### 📈 Statistics
- Weekly earnings bar chart
- Monthly earnings trend (6 months)
- Weekly hours worked chart
- All-time summary: total earnings, hours, avg per shift

### ☁️ Sync System (Offline-First)
- Data saved to **Hive (local)** first — ALWAYS
- Background sync to **Cloud Firestore**
- Auto-sync when internet returns
- Visual sync indicator: Synced / Syncing / Offline / Error
- Full cloud restore after app reinstall

### 📤 Export
- Export shifts as **CSV** (spreadsheet-compatible)
- Export shifts as **PDF** (professional report with summary)

### 🎨 Premium UI
- Material 3 Design
- Dark Navy + Gold professional theme
- Light mode support
- Smooth animations throughout
- Google Fonts (Outfit)
- Shimmer loading skeletons
- Animated stat cards

---

## 🏗️ Architecture

```
lib/
├── main.dart                    # App entry point
├── core/
│   ├── constants/
│   │   ├── app_constants.dart   # App-wide constants
│   │   └── app_colors.dart      # Color palette
│   └── theme/
│       └── app_theme.dart       # Material 3 theme
├── data/
│   ├── providers/
│   │   └── hive_provider.dart   # Local Hive DB operations
│   └── repositories/
│       └── shift_repository.dart # Repository pattern
├── models/
│   ├── shift_model.dart         # Shift data model
│   └── shift_model.g.dart       # Hive type adapter
├── services/
│   ├── auth_service.dart        # Firebase Auth + Google Sign In
│   ├── connectivity_service.dart # Network monitoring
│   ├── sync_service.dart        # Bidirectional Firestore sync
│   └── export_service.dart      # CSV/PDF export
├── controllers/
│   ├── auth_controller.dart     # Auth flow management
│   ├── dashboard_controller.dart # Dashboard stats & clocks
│   ├── shift_controller.dart    # Shift CRUD + filtering
│   ├── statistics_controller.dart # Chart data computation
│   └── theme_controller.dart    # Dark/Light mode
├── bindings/
│   ├── initial_binding.dart     # Core services registration
│   ├── home_binding.dart        # Dashboard + Shift controllers
│   ├── shift_binding.dart       # Shift controller
│   └── statistics_binding.dart  # Statistics controller
├── views/
│   ├── splash/splash_screen.dart
│   ├── auth/login_screen.dart
│   ├── home/home_screen.dart
│   ├── dashboard/dashboard_screen.dart
│   ├── shift/
│   │   ├── add_shift_screen.dart
│   │   └── shift_list_screen.dart
│   ├── statistics/statistics_screen.dart
│   └── settings/settings_screen.dart
├── widgets/
│   ├── earning_card.dart        # Animated stat card
│   ├── shift_card.dart          # Shift detail card
│   ├── clock_widget.dart        # Live timezone clock
│   ├── sync_indicator.dart      # Sync status badge
│   ├── empty_state.dart         # Empty list placeholder
│   └── loading_shimmer.dart     # Skeleton loading
├── routes/
│   ├── app_routes.dart          # Route constants
│   └── app_pages.dart           # Page routing config
└── utils/
    └── formatters.dart          # Date/Time/Currency formatting
```

---

## 🔧 Setup Instructions

### Prerequisites
- Flutter 3.35+ (stable channel)
- Dart 3.9+
- Android Studio or VS Code
- A Firebase project

### 1. Clone & Install
```bash
cd c:\vd
flutter pub get
```

### 2. Firebase Setup

#### Create Firebase Project
1. Go to [Firebase Console](https://console.firebase.google.com)
2. Create a new project: **"VD Shift Manager"**
3. Enable **Authentication** → Sign-in method → **Google**
4. Enable **Cloud Firestore** → Create database → Start in test mode

#### Android Setup
1. Add Android app in Firebase Console:
   - Package name: `com.vishrutdonda.vd_shift_manager`
   - App nickname: VD Shift Manager
   - SHA-1: Run `keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android` (or use `./gradlew signingReport`)
2. Download `google-services.json` → place in `android/app/`
3. Ensure `android/build.gradle` has Google services classpath
4. Ensure `android/app/build.gradle` applies the plugin

#### iOS Setup
1. Add iOS app in Firebase Console:
   - Bundle ID: `com.vishrutdonda.vdShiftManager`
2. Download `GoogleService-Info.plist` → place in `ios/Runner/`
3. Open `ios/Runner.xcworkspace` in Xcode
4. Add `GoogleService-Info.plist` to Runner target
5. Add URL scheme for Google Sign In in `Info.plist`

### 3. Firestore Security Rules
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can only access their own data
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;

      match /shifts/{shiftId} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
    }
  }
}
```

### 4. Run the App
```bash
# Android
flutter run

# iOS
cd ios && pod install && cd ..
flutter run

# Web
flutter run -d chrome
```

---

## 📱 Database Structure

### Hive (Local)
- `shifts_box` → `ShiftModel` objects keyed by ID
- `settings_box` → App preferences (theme, last sync time)

### Firestore (Cloud)
```
users/
  └── {uid}/
      └── shifts/
          └── {shiftId}/
              ├── id: string
              ├── date: string (ISO 8601)
              ├── eventName: string
              ├── jobRole: string
              ├── startTime: string (HH:mm)
              ├── endTime: string (HH:mm)
              ├── breakHours: number
              ├── netHours: number
              ├── payPerHour: number
              ├── totalPay: number
              ├── notes: string?
              ├── createdAt: string (ISO 8601)
              ├── updatedAt: string (ISO 8601)
              └── isDeleted: boolean
```

---

## 🧮 Calculation Formula

```
Total Hours = End Time - Start Time (handles overnight shifts)
Net Hours   = Total Hours - Break Hours
Total Pay   = Net Hours × Pay Per Hour
```

---

## 📦 Key Dependencies

| Package | Purpose |
|---------|---------|
| `get` | State management, navigation, DI |
| `hive` / `hive_flutter` | Local offline database |
| `firebase_core` | Firebase initialization |
| `firebase_auth` | Google Sign In authentication |
| `cloud_firestore` | Cloud database sync |
| `google_sign_in` | Google OAuth flow |
| `fl_chart` | Animated bar charts |
| `pdf` / `printing` | PDF report generation |
| `csv` | CSV export |
| `connectivity_plus` | Network status monitoring |
| `shimmer` | Loading skeleton animations |
| `google_fonts` | Outfit typography |
| `animate_do` | Entrance animations |
| `intl` | Date/number formatting |

---

## 🏗️ Build for Production

```bash
# Android APK
flutter build apk --release

# Android App Bundle (for Play Store)
flutter build appbundle --release

# iOS
flutter build ios --release
```

---

## 🙏 Personalization

> "You can do all this stuff, just trust yourself ❤️"

*जय श्री राम 🙏 | ॐ नमः शिवाय | जय बजरंगबली*

---

**Built with ❤️ for Vishrut Donda**
