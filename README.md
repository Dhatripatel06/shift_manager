# Shift Manager 🕐

**Manage your shifts. Master your day.**

A Flutter mobile application designed for **UK shift workers** to efficiently manage daily tasks, track working hours, and monitor earnings on Android. Built with offline-first principles and professional-grade features.

---

## ✨ Features

### 🔐 Authentication
- **Google Sign In** (Firebase Authentication)
- **Persistent login** with auto-login capability
- **Secure sign out** with session management

### 📊 Dashboard
- **Weekly & Monthly Earnings Overview** – Visual earnings cards at a glance
- **Live Dual Timezone Clocks** – 🇬🇧 UK Time / 🇮🇳 India Time (real-time updates)
- **Recent Shifts View** – Quick access to your latest shifts
- **Key Statistics** – Total shifts, hours worked, and cumulative earnings

### 📝 Shift Management (CRUD)
- **Add Shift** – Intuitive form with date and time pickers
- **Edit Shift** – Pre-populated form with existing shift data
- **Delete Shift** – Confirmation dialog with soft-delete sync
- **Auto Calculations** – Net hours and total pay computed instantly
- **Complete Shift Fields**:
  - Date
  - Event/Location Name
  - Job Role
  - Start & End Time
  - Break Duration (hours)
  - Pay Rate (£/hour)
  - Optional Notes

### 🔍 Filters & Search
- **Quick Filters**: All | Today | This Week | This Month
- **Smart Search**: Find shifts by event name or job role

### 📈 Statistics & Analytics
- **Weekly Earnings Bar Chart** – Visualize your earnings by day
- **Monthly Earnings Trend** – 6-month historical analysis
- **Weekly Hours Worked Chart** – Track time investment
- **All-Time Summary**:
  - Total earnings (£)
  - Total hours worked
  - Average earnings per shift

### ☁️ Sync System (Offline-First Architecture)
- **Local First**: All data saved to Hive (local database) immediately
- **Background Sync**: Automatic synchronisation to Cloud Firestore
- **Auto-Recovery**: Full data restore on app reinstall
- **Offline Support**: Full functionality without internet
- **Visual Sync Indicator**: Real-time status (Synced | Syncing | Offline | Error)

### 📤 Export & Reporting
- **CSV Export** – Compatible with Excel and spreadsheet applications
- **PDF Export** – Professional reports with shift summary and analytics

### 🎨 Professional UI/UX
- **Material 3 Design** – Modern, accessibility-focused interface
- **Dark Navy + Gold Theme** – Professional colour scheme optimised for readability
- **Light Mode Support** – Toggle between dark and light themes
- **Smooth Animations** – Polished user experience throughout
- **Google Fonts (Outfit)** – Clean, modern typography
- **Loading Skeletons** – Shimmer effect for content placeholders
- **Animated Cards** – Engaging stat cards with transitions

---

## 🏗️ Architecture

The app follows a **layered architecture** pattern with clean separation of concerns:

```
lib/
├── main.dart                       # App entry point & initialization
├── core/
│   ├── constants/
│   │   ├── app_constants.dart      # App-wide configuration constants
│   │   └── app_colors.dart         # Unified colour palette
│   └── theme/
│       └── app_theme.dart          # Material 3 theme configuration
├── data/
│   ├── providers/
│   │   └── hive_provider.dart      # Hive local database operations
│   └── repositories/
│       └── shift_repository.dart   # Repository pattern implementation
├── models/
│   ├── shift_model.dart            # Shift data model (domain entity)
│   └── shift_model.g.dart          # Hive type adapter (code-gen)
├── services/
│   ├── auth_service.dart           # Firebase Auth & Google Sign In logic
│   ├── connectivity_service.dart   # Network status monitoring
│   ├── sync_service.dart           # Bidirectional Firestore synchronisation
│   └── export_service.dart         # CSV & PDF export functionality
├── controllers/
│   ├── auth_controller.dart        # Authentication flow management
│   ├── dashboard_controller.dart   # Dashboard stats & clock updates
│   ├── shift_controller.dart       # Shift CRUD & filtering logic
│   ├── statistics_controller.dart  # Chart data computation
│   └── theme_controller.dart       # Dark/Light mode toggle
├── bindings/
│   ├── initial_binding.dart        # Core services dependency injection
│   ├── home_binding.dart           # Dashboard & Shift controllers
│   ├── shift_binding.dart          # Shift management DI
│   └── statistics_binding.dart     # Statistics module DI
├── views/
│   ├── splash/
│   │   └── splash_screen.dart
│   ├── auth/
│   │   └── login_screen.dart
│   ├── home/
│   │   └── home_screen.dart        # Main navigation hub
│   ├── dashboard/
│   │   └── dashboard_screen.dart   # Overview & stats
│   ├── shift/
│   │   ├── add_shift_screen.dart   # Add/Edit form
│   │   └── shift_list_screen.dart  # Shifts list with filters
│   ├── statistics/
│   │   └── statistics_screen.dart  # Analytics & charts
│   └── settings/
│       └── settings_screen.dart    # App preferences & theme
├── widgets/
│   ├── earning_card.dart           # Animated earnings stat card
│   ├── shift_card.dart             # Individual shift display card
│   ├── clock_widget.dart           # Live timezone clock display
│   ├── sync_indicator.dart         # Sync status badge
│   ├── empty_state.dart            # Empty list placeholder
│   └── loading_shimmer.dart        # Skeleton loading effect
├── routes/
│   ├── app_routes.dart             # Route name constants
│   └── app_pages.dart              # Page routing & middleware config
└── utils/
    └── formatters.dart             # Date/Time/Currency formatting utilities
```

### Design Patterns Used
- **Repository Pattern** – Abstraction of data sources
- **Service Locator (GetX)** – Dependency injection
- **State Management (GetX Controllers)** – Reactive UI updates
- **Offline-First Architecture** – Local-first data synchronisation
- **MVVM-inspired** – Clear separation between UI and business logic

---

## 🔧 Setup Instructions

### Prerequisites
- **Flutter**: 3.35+ (stable channel)
- **Dart**: 3.9+
- **Android Studio** or **VS Code** with Flutter extension
- **Android SDK**: API level 21+ (for app deployment)
- **Firebase Project** (with Android app configured)

### 1. Clone Repository & Install Dependencies

```bash
git clone https://github.com/Dhatripatel06/shift_manager.git
cd shift_manager
flutter pub get
```

### 2. Firebase Setup

#### Create Firebase Project
1. Visit [Firebase Console](https://console.firebase.google.com)
2. Click **Create Project** → Name: `Shift Manager`
3. Accept default settings and create

#### Enable Firebase Services

**Authentication:**
1. Navigate to **Build** → **Authentication**
2. Click **Get Started**
3. Select **Google** as sign-in method
4. Provide a support email
5. Save

**Cloud Firestore:**
1. Navigate to **Build** → **Firestore Database**
2. Click **Create Database**
3. Select region closest to UK (e.g., `europe-west2`)
4. Start in **Test Mode** (later configure security rules)

#### Android Configuration

1. **Register Android App in Firebase:**
   - In Firebase Console → **Project Settings** → **Your apps**
   - Click **Add App** → **Android**
   - Enter package name: `com.shiftmanager.app` (or your package)
   - Run to get SHA-1 fingerprint:
     ```bash
     ./gradlew signingReport
     ```
     Copy the **SHA1** value and paste into Firebase

2. **Download Configuration File:**
   - Firebase will provide `google-services.json`
   - Place it in: `android/app/google-services.json`

3. **Update Android Build Files:**
   
   `android/build.gradle`:
   ```gradle
   buildscript {
       dependencies {
           classpath 'com.google.gms:google-services:4.4.0'
       }
   }
   ```

   `android/app/build.gradle`:
   ```gradle
   apply plugin: 'com.google.gms.google-services'
   ```

#### Enable Required APIs (if not automatic)
- Firebase Authentication API
- Cloud Firestore API
- Google Identity Services

### 3. Configure Firestore Security Rules

Replace default Firestore rules with:

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
# Run on connected Android device or emulator
flutter run

# Run with verbose logging (for debugging)
flutter run -v

# Run specific device
flutter devices  # List available devices
flutter run -d <device-id>
```

---

## 📱 Database Structure

### Local Database (Hive)
Hive stores data locally on the device for offline-first functionality:

```
shifts_box (HiveBox<ShiftModel>)
├── [shift-id-1] → ShiftModel object
├── [shift-id-2] → ShiftModel object
└── [shift-id-N] → ShiftModel object

settings_box (HiveBox<dynamic>)
├── theme_mode: String ('light' | 'dark')
└── last_sync_time: DateTime
```

### Cloud Database (Firestore)
Cloud Firestore stores authoritative copies of all shifts for multi-device sync:

```
users/
└── {firebaseUID}/
    ├── email: string
    ├── createdAt: timestamp
    └── shifts/
        └── {shiftId}/
            ├── id: string (unique identifier)
            ├── date: string (ISO 8601: "2024-06-13")
            ├── eventName: string (e.g., "Tesco", "Amazon Warehouse")
            ├── jobRole: string (e.g., "Warehouse Associate", "Delivery Driver")
            ├── startTime: string (24-hour format: "09:00")
            ├── endTime: string (24-hour format: "17:30")
            ├── breakHours: number (decimal: 0.5, 1.0)
            ├── netHours: number (calculated: endTime - startTime - breakHours)
            ├── payPerHour: number (GBP: 10.42, 12.50)
            ├── totalPay: number (calculated: netHours × payPerHour)
            ├── notes: string (optional: "High demand day", "Extra breaks")
            ├── createdAt: timestamp
            ├── updatedAt: timestamp
            └── isDeleted: boolean (soft-delete flag)
```

---

## 🧮 Calculation Formulas

All calculations are performed client-side and synced to the cloud:

```
Total Hours = Time Difference (handles overnight shifts: 22:00 to 06:00 = 8 hours)
Net Hours   = Total Hours - Break Hours
Total Pay   = Net Hours × Pay Per Hour (rounded to 2 decimal places)

Example:
  Start Time: 09:00
  End Time:   17:30
  Total Hours: 8.5
  Break Hours: 0.5
  Net Hours:   8.0
  Pay/Hr:      £12.50
  Total Pay:   £100.00
```

---

## 📦 Key Dependencies

| Package | Version | Purpose |
|---------|---------|---------|
| `get` | ^4.6.0 | State management, routing, dependency injection |
| `hive` | ^2.2.0 | Local NoSQL database |
| `hive_flutter` | ^1.1.0 | Hive integration with Flutter |
| `firebase_core` | ^2.24.0 | Firebase initialization |
| `firebase_auth` | ^4.15.0 | Google Sign In & auth |
| `cloud_firestore` | ^4.14.0 | Cloud database sync |
| `google_sign_in` | ^6.1.0 | Google OAuth integration |
| `fl_chart` | ^0.72.0 | Animated bar & line charts |
| `pdf` | ^3.10.0 | PDF report generation |
| `printing` | ^5.11.0 | PDF preview & print |
| `csv` | ^6.0.0 | CSV file generation |
| `connectivity_plus` | ^5.0.0 | Network status monitoring |
| `shimmer` | ^3.0.0 | Loading skeleton animations |
| `google_fonts` | ^6.1.0 | Outfit & other fonts |
| `animate_do` | ^3.1.0 | Entrance animations |
| `intl` | ^0.19.0 | Localization & date formatting |

Full `pubspec.yaml` available in the repository.

---

## 🚀 Building for Production

### Android APK (for manual distribution)
```bash
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

### Android App Bundle (for Google Play Store)
```bash
flutter build appbundle --release
# Output: build/app/outputs/bundle/release/app-release.aab
```

### Verify Release Build
```bash
# Check app size
ls -lh build/app/outputs/flutter-apk/app-release.apk

# Install & test on device
adb install build/app/outputs/flutter-apk/app-release.apk
```

---

## 🔒 Security & Privacy

### Data Protection
- **Local Data**: All data stored in Hive is encrypted at device level (device OS encryption)
- **Cloud Data**: Firestore enforces per-user access control via security rules
- **Authentication**: Firebase Auth handles OAuth security; no password storage
- **Soft Deletes**: Deleted shifts marked as `isDeleted: true` rather than removed (GDPR audit trail)

### Privacy Considerations
- No analytics tracking (no Firebase Analytics or third-party trackers)
- No data sharing with external services
- All exports (CSV/PDF) remain on user's device
- Firestore rules ensure users cannot access other users' data

---

## 📝 Development Workflow

### Adding a New Shift Field
1. **Update Model** (`lib/models/shift_model.dart`):
   - Add field to `ShiftModel` class
   - Update `toMap()` and `fromMap()` methods
   - Add Hive type ID annotations

2. **Regenerate Hive Adapter**:
   ```bash
   flutter pub run build_runner build
   ```

3. **Update UI** (`lib/views/shift/add_shift_screen.dart`):
   - Add new form field widget
   - Bind to controller

4. **Sync Firestore** (`lib/services/sync_service.dart`):
   - Include new field in cloud payload

### Code Generation
The project uses `build_runner` for code generation (Hive adapters):
```bash
# Generate code
flutter pub run build_runner build

# Watch for changes (auto-regenerate)
flutter pub run build_runner watch
```

---

## 🐛 Troubleshooting

| Issue | Solution |
|-------|----------|
| **Firebase authentication fails** | Verify SHA-1 fingerprint in Firebase Console matches your signing key. Run `./gradlew signingReport` |
| **Offline data not syncing** | Check network connectivity. Sync indicator shows status. Manual refresh via pull-to-refresh or app restart |
| **Shifts not appearing after login** | First login triggers Firestore sync. Wait a few seconds or restart app. Check Firestore rules are correctly set |
| **Build errors with Hive** | Run `flutter clean` then `flutter pub get` then `flutter pub run build_runner build` |
| **PDF/CSV export fails** | Ensure app has file write permissions (Android 6+: runtime permissions prompted on first export) |
| **Slow performance on lists** | Large shift history (1000+) may cause UI lag. Consider pagination or filtering by date range |

---

## 📞 Support & Contributions

- **Report Issues**: Open a GitHub issue with reproduction steps
- **Feature Requests**: Discuss in issues or submit a pull request
- **Development**: Fork repository, create feature branch, submit PR

---

## 📄 License

This project is provided as-is. Modify freely for personal or commercial use.

---

## 🙏 Acknowledgments

Built with ❤️ for UK shift workers managing their daily tasks efficiently.

**Developed with:**
- Flutter & Dart
- Firebase & Firestore
- GetX state management
- Material 3 design principles

---

**Current Status**: Android support active. iOS support coming soon.

Last Updated: June 2026
