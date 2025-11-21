import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionsState {
  const PermissionsState({
    required this.hasAllPermissions,
    required this.isChecking,
    this.error,
  });

  final bool hasAllPermissions;
  final bool isChecking;
  final String? error;

  PermissionsState copyWith({
    bool? hasAllPermissions,
    bool? isChecking,
    String? error,
    bool clearError = false,
  }) {
    return PermissionsState(
      hasAllPermissions: hasAllPermissions ?? this.hasAllPermissions,
      isChecking: isChecking ?? this.isChecking,
      error: clearError ? null : error ?? this.error,
    );
  }
}

final permissionsControllerProvider =
    StateNotifierProvider<PermissionsController, PermissionsState>((ref) {
  return PermissionsController();
});

class PermissionsController extends StateNotifier<PermissionsState> {
  PermissionsController()
      : super(const PermissionsState(
          hasAllPermissions: false,
          // Do not check permissions automatically on creation. The app will
          // request/check permissions when the user navigates to the
          // Permissions page or triggers the flow from Settings.
          isChecking: false,
        ));

  Future<void> _checkPermissions() async {
    state = state.copyWith(isChecking: true, clearError: true);
    final permissions = _getRequiredPermissions();
    final statuses = await Future.wait(
      permissions.map((p) => p.status),
    );

    // Check required permissions (all must be granted)
    final hasAllRequired = statuses.every((status) => status.isGranted);

    if (!hasAllRequired) {
      // Find missing required permissions (excluding optional ones)
      final missingPermissions = <String>[];
      for (int i = 0; i < permissions.length; i++) {
        final permission = permissions[i];
        if (!statuses[i].isGranted) {
          missingPermissions.add(_getPermissionName(permission));
        }
      }

      if (missingPermissions.isNotEmpty) {
        final missingList = missingPermissions.join(', ');
        state = state.copyWith(
          hasAllPermissions: false,
          isChecking: false,
          error:
              'Missing permissions: $missingList. Please grant all permissions to continue.',
        );
      } else {
        state = state.copyWith(
          hasAllPermissions: true,
          isChecking: false,
        );
      }
    } else {
      state = state.copyWith(
        hasAllPermissions: true,
        isChecking: false,
      );
    }
  }

  List<Permission> _getRequiredPermissions() {
    return [
      // Location is required on Android to run Bluetooth scans in the background
      Permission.locationWhenInUse,
      // Bluetooth runtime permissions (Android 12+ granular permissions)
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.bluetoothAdvertise,
    ];
  }

  String _getPermissionName(Permission permission) {
    if (permission == Permission.locationWhenInUse) {
      return 'Location';
    } else if (permission == Permission.bluetoothScan) {
      return 'Bluetooth Scan';
    } else if (permission == Permission.bluetoothConnect) {
      return 'Bluetooth Connect';
    } else if (permission == Permission.bluetoothAdvertise) {
      return 'Bluetooth Advertise';
    } else if (permission == Permission.bluetooth) {
      return 'Bluetooth';
    }
    return permission.toString();
  }

  /// Requests each required permission sequentially and returns a map of
  /// permission name -> [PermissionStatus]. This is useful when you want to
  /// present system dialogs one-by-one and report granular results to the UI.
  Future<Map<String, PermissionStatus>> requestAllPermissions() async {
    state = state.copyWith(isChecking: true, clearError: true);
    final permissions = _getRequiredPermissions();
    final Map<String, PermissionStatus> results = {};

    try {
      for (final p in permissions) {
        final status = await p.request();
        results[_getPermissionName(p)] = status;
      }

      // Check if all required (non-optional) permissions are granted
      final allRequiredGranted = permissions
          .every((p) => results[_getPermissionName(p)]?.isGranted ?? false);

      state = state.copyWith(
          hasAllPermissions: allRequiredGranted, isChecking: false);
      return results;
    } catch (e) {
      state = state.copyWith(
        hasAllPermissions: false,
        isChecking: false,
        error: 'Failed to request permissions: ${e.toString()}',
      );
      return results;
    }
  }

  Future<void> requestPermissions() async {
    state = state.copyWith(isChecking: true, clearError: true);

    try {
      final permissions = _getRequiredPermissions();
      final results = await Future.wait(
        permissions.map((p) => p.request()),
      );

      // Find missing required permissions (excluding optional ones)
      final missingPermissions = <String>[];
      for (int i = 0; i < permissions.length; i++) {
        final permission = permissions[i];
        if (!results[i].isGranted) {
          missingPermissions.add(_getPermissionName(permission));
        }
      }

      if (missingPermissions.isNotEmpty) {
        final permanentlyDenied =
            results.any((status) => status.isPermanentlyDenied);
        final missingList = missingPermissions.join(', ');

        if (permanentlyDenied) {
          state = state.copyWith(
            hasAllPermissions: false,
            isChecking: false,
            error:
                'Missing permissions: $missingList. Some are permanently denied. Please enable them in app settings.',
          );
        } else {
          state = state.copyWith(
            hasAllPermissions: false,
            isChecking: false,
            error:
                'Missing permissions: $missingList. All permissions are required for the app to function. Please grant all permissions.',
          );
        }
      } else {
        // All required permissions are granted (optional ones may be missing, which is OK)
        state = state.copyWith(
          hasAllPermissions: true,
          isChecking: false,
        );
      }
    } catch (e) {
      state = state.copyWith(
        hasAllPermissions: false,
        isChecking: false,
        error: 'Failed to request permissions: ${e.toString()}',
      );
    }
  }

  Future<void> openSettings() async {
    await openAppSettings();
  }

  void recheckPermissions() {
    _checkPermissions();
  }

  /// Public check that updates internal state and returns whether all
  /// required permissions are currently granted. Useful for callers that want
  /// to decide whether to show the Permissions UI before attempting network
  /// operations.
  Future<bool> checkPermissions() async {
    await _checkPermissions();
    return state.hasAllPermissions;
  }
}

Future<void> dumpPermissionStatuses() async {
  final permissions = <Permission>[
    Permission.locationWhenInUse,
    Permission.bluetooth,
    Permission.bluetoothScan,
    Permission.bluetoothConnect,
  ];

  for (final p in permissions) {
    final s = await p.status;
    print('Permission ${p.toString()}: isGranted=${s.isGranted}, '
        'isDenied=${s.isDenied}, isPermanentlyDenied=${s.isPermanentlyDenied}, status=$s');
  }
}
