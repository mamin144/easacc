import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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

class PermissionsCubit extends Cubit<PermissionsState> {
  PermissionsCubit()
      : super(const PermissionsState(
          hasAllPermissions: false,
          isChecking: false,
        ));

  Future<void> _checkPermissions() async {
    emit(state.copyWith(isChecking: true, clearError: true));
    final permissions = _getRequiredPermissions();
    final statuses = await Future.wait(
      permissions.map((p) => p.status),
    );

    final hasAllRequired = statuses.every((status) => status.isGranted);

    if (!hasAllRequired) {
      final missingPermissions = <String>[];
      for (int i = 0; i < permissions.length; i++) {
        final permission = permissions[i];
        if (!statuses[i].isGranted) {
          missingPermissions.add(_getPermissionName(permission));
        }
      }

      if (missingPermissions.isNotEmpty) {
        final missingList = missingPermissions.join(', ');
        emit(state.copyWith(
          hasAllPermissions: false,
          isChecking: false,
          error:
              'Missing permissions: $missingList. Please grant all permissions to continue.',
        ));
      } else {
        emit(state.copyWith(
          hasAllPermissions: true,
          isChecking: false,
        ));
      }
    } else {
      emit(state.copyWith(
        hasAllPermissions: true,
        isChecking: false,
      ));
    }
  }

  List<Permission> _getRequiredPermissions() {
    return [
      Permission.locationWhenInUse,
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

  Future<Map<String, PermissionStatus>> requestAllPermissions() async {
    emit(state.copyWith(isChecking: true, clearError: true));
    final permissions = _getRequiredPermissions();
    final Map<String, PermissionStatus> results = {};

    try {
      for (final p in permissions) {
        final status = await p.request();
        results[_getPermissionName(p)] = status;
      }

      final allRequiredGranted = permissions
          .every((p) => results[_getPermissionName(p)]?.isGranted ?? false);

      emit(state.copyWith(
          hasAllPermissions: allRequiredGranted, isChecking: false));
      return results;
    } catch (e) {
      emit(state.copyWith(
        hasAllPermissions: false,
        isChecking: false,
        error: 'Failed to request permissions: ${e.toString()}',
      ));
      return results;
    }
  }

  Future<void> requestPermissions() async {
    emit(state.copyWith(isChecking: true, clearError: true));

    try {
      final permissions = _getRequiredPermissions();
      final results = await Future.wait(
        permissions.map((p) => p.request()),
      );

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
          emit(state.copyWith(
            hasAllPermissions: false,
            isChecking: false,
            error:
                'Missing permissions: $missingList. Some are permanently denied. Please enable them in app settings.',
          ));
        } else {
          emit(state.copyWith(
            hasAllPermissions: false,
            isChecking: false,
            error:
                'Missing permissions: $missingList. All permissions are required for the app to function. Please grant all permissions.',
          ));
        }
      } else {
        emit(state.copyWith(
          hasAllPermissions: true,
          isChecking: false,
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        hasAllPermissions: false,
        isChecking: false,
        error: 'Failed to request permissions: ${e.toString()}',
      ));
    }
  }

  Future<void> openSettings() async {
    await openAppSettings();
  }

  void recheckPermissions() {
    _checkPermissions();
  }

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
    debugPrint('Permission ${p.toString()}: isGranted=${s.isGranted}, '
        'isDenied=${s.isDenied}, isPermanentlyDenied=${s.isPermanentlyDenied}, status=$s');
  }
}
