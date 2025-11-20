# easacc

Cross-platform (iOS + Android) Flutter application with:
- Configurable Settings page with network device scanning (Wi-Fi + Bluetooth printers)
- Embedded WebView that renders any user-supplied URL

## Project structure

```
lib/
 ├── app.dart                     # Root MaterialApp with routes
 ├── core/
 │   ├── routing/app_router.dart
 │   └── theme/app_theme.dart
 └── features/
     ├── settings/
     │   ├── controller/settings_controller.dart
     │   ├── models/network_device.dart
     │   ├── state/settings_state.dart
     │   └── view/settings_page.dart
     └── webview/
         └── view/webview_page.dart
```

## Packages

| Feature | Package |
| --- | --- |
| Embedded browser | [`webview_flutter`](https://pub.dev/packages/webview_flutter) |
| Wi-Fi discovery | [`wifi_iot`](https://pub.dev/packages/wifi_iot) |
| Bluetooth discovery | [`flutter_blue_plus`](https://pub.dev/packages/flutter_blue_plus) |
| Permissions | [`permission_handler`](https://pub.dev/packages/permission_handler) |
| State management | [`flutter_riverpod`](https://pub.dev/packages/flutter_riverpod) |

## Getting started

```bash
flutter pub get
flutter run
```

## Platform permissions

Android manifest already declares Wi-Fi/Bluetooth + location permissions required by `wifi_iot`, `flutter_blue_plus`, and `permission_handler`. iOS `Info.plist` strings are provided for App Store privacy review—update their wording if needed.

## Sending the deliverable

When you’re ready to share the build or repository snapshot, email the deliverables to **hiring@easacc.com** as requested.
