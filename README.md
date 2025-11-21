# easacc_task

Cross-platform (iOS + Android) Flutter application with:
- Configurable Settings page with Bluetooth scanning for printers and earbuds
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
| Bluetooth discovery | [`flutter_blue_plus`](https://pub.dev/packages/flutter_blue_plus) |
| Permissions | [`permission_handler`](https://pub.dev/packages/permission_handler) |
| State management | [`flutter_riverpod`](https://pub.dev/packages/flutter_riverpod) |

## Getting started

```bash
flutter pub get
flutter run
```

## Platform permissions

Android manifest already declares the Bluetooth and location permissions required by `flutter_blue_plus` and `permission_handler`. iOS `Info.plist` strings are provided for App Store privacy review—update their wording if needed.

## Sending the deliverable

When you're ready to share the build or repository snapshot, email the deliverables to **hiring@easacc.com** as requested.
