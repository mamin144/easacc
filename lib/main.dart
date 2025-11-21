import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:permission_handler/permission_handler.dart';
import 'firebase_options.dart';

import 'app.dart';

/// Requests all required permissions on app startup.
/// This will only show system dialogs for permissions that are not yet granted.
/// Note: nearbyWifiDevices is optional and won't block the app if not granted.
Future<void> _requestAllPermissionsOnStartup() async {
  final requiredPermissions = [
    // Location is required for Wi-Fi scanning on older Android versions
    Permission.locationWhenInUse,
    // Bluetooth runtime permissions (Android 12+ granular permissions)
    Permission.bluetooth,
    Permission.bluetoothScan,
    Permission.bluetoothConnect,
    Permission.bluetoothAdvertise,
  ];

  final optionalPermissions = [
    // Android 13+ permission for nearby Wi-Fi devices (optional)
    if (Platform.isAndroid) Permission.nearbyWifiDevices,
  ];

  // Check current status of required permissions
  final requiredStatuses = await Future.wait(
    requiredPermissions.map((p) => p.status),
  );

  // Request only required permissions that are not granted
  for (int i = 0; i < requiredPermissions.length; i++) {
    if (!requiredStatuses[i].isGranted) {
      await requiredPermissions[i].request();
    }
  }

  // Try to request optional permissions, but don't fail if they're not granted
  for (final permission in optionalPermissions) {
    try {
      final status = await permission.status;
      if (!status.isGranted) {
        await permission.request();
      }
    } catch (e) {
      // Ignore errors for optional permissions
      // They may not be available on this Android version
    }
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Request all required permissions on first app launch
  // This will only show dialogs for permissions that are not yet granted
  await _requestAllPermissionsOnStartup();

  runApp(const ProviderScope(child: EasaccApp()));
}
