# EASACC

A cross-platform Flutter application featuring authentication, Bluetooth device scanning, and embedded WebView functionality.

## Features

### 🔐 Authentication
- **Google Sign-In**: Sign in with your Google account
- **Facebook Sign-In**: Sign in with your Facebook account
- **Firebase Authentication**: Secure authentication powered by Firebase
- **Session Persistence**: Your login state is saved and restored automatically

### 📱 Settings & Configuration
- **WebView URL Configuration**: Set and manage the URL that will be displayed in the WebView
- **Bluetooth Device Scanning**: Discover nearby Bluetooth devices (printers, earbuds, and other accessories)
- **Device Selection**: Select from discovered Bluetooth devices
- **Permission Management**: Request and manage app permissions (Location, Bluetooth)

### 🌐 WebView
- **Embedded Browser**: View any website within the app
- **Dynamic URL Loading**: Load URLs configured in the settings page
- **Refresh Support**: Reload the current page with a single tap

## Project Structure

```
lib/
 ├── app.dart                     # Root MaterialApp with routes
 ├── main.dart                    # Application entry point
 ├── firebase_options.dart        # Firebase configuration
 ├── core/
 │   ├── routing/
 │   │   └── app_router.dart      # Route definitions
 │   ├── theme/
 │   │   └── app_theme.dart       # App theme configuration
 │   └── permissions/
 │       ├── permissions_controller.dart
 │       └── permissions_page.dart
 └── features/
     ├── auth/
     │   ├── controller/
     │   │   └── auth_controller.dart
     │   ├── state/
     │   │   └── auth_state.dart
     │   └── view/
     │       └── login_page.dart
     ├── settings/
     │   ├── controller/
     │   │   └── settings_controller.dart
     │   ├── models/
     │   │   └── network_device.dart
     │   ├── state/
     │   │   └── settings_state.dart
     │   └── view/
     │       └── settings_page.dart
     └── webview/
         └── view/
             └── webview_page.dart
```

## Getting Started

### Prerequisites

- Flutter SDK (3.6.1 or higher)
- Dart SDK
- Android Studio / Xcode (for mobile development)
- Firebase project configured

### Installation

1. Clone the repository:
```bash
git clone https://github.com/mamin144/easacc.git
cd easacc
```

2. Install dependencies:
```bash
flutter pub get
```

3. Configure Firebase:
   - Ensure `firebase_options.dart` is properly configured
   - Add your `google-services.json` file for Android
   - Configure iOS Firebase settings

4. Run the app:
```bash
flutter run
```

## Dependencies

| Package | Purpose |
|---------|---------|
| `flutter_bloc` | State management |
| `firebase_core` & `firebase_auth` | Authentication |
| `flutter_blue_plus` | Bluetooth device scanning |
| `permission_handler` | Permission management |
| `webview_flutter` | Embedded browser |
| `flutter_facebook_auth` | Facebook authentication |
| `google_sign_in` | Google authentication |
| `shared_preferences` | Local data persistence |

## Platform Support

- ✅ Android
- ✅ iOS
- ✅ Web

## Permissions

The app requires the following permissions:

- **Location**: Required by Android to discover nearby Bluetooth devices
- **Bluetooth**: Needed to scan for printers, earbuds, and other accessories
- **Bluetooth Scan**: Required for Bluetooth device discovery
- **Bluetooth Connect**: Required to connect to Bluetooth devices
- **Bluetooth Advertise**: Required for Bluetooth advertising

## Usage

1. **Sign In**: Launch the app and sign in with Google or Facebook
2. **Configure URL**: Go to Settings and enter the URL you want to display in the WebView
3. **Scan for Devices**: Tap "Scan" to discover nearby Bluetooth devices
4. **Open WebView**: Tap "Open Web View" to view the configured website
5. **Sign Out**: Use the "Sign Out" button in Settings to log out

## Development

### State Management
The app uses BLoC (Business Logic Component) pattern for state management:
- `AuthCubit`: Manages authentication state
- `SettingsCubit`: Manages settings and Bluetooth scanning
- `PermissionsCubit`: Manages app permissions

### Architecture
- **Feature-based structure**: Code is organized by features
- **Separation of concerns**: Controllers, views, and state are separated
- **Reactive UI**: UI updates automatically based on state changes

## License

This project is private and proprietary.

## Contact

For questions or support, please contact the development team.
