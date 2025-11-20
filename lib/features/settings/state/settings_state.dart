import '../models/network_device.dart';

class SettingsState {
  const SettingsState({
    required this.targetUrl,
    required this.devices,
    this.selectedDevice,
    this.isScanning = false,
    this.error,
  });

  final String targetUrl;
  final List<NetworkDevice> devices;
  final NetworkDevice? selectedDevice;
  final bool isScanning;
  final String? error;

  SettingsState copyWith({
    String? targetUrl,
    List<NetworkDevice>? devices,
    NetworkDevice? selectedDevice,
    bool? isScanning,
    String? error,
    bool clearError = false,
  }) {
    return SettingsState(
      targetUrl: targetUrl ?? this.targetUrl,
      devices: devices ?? this.devices,
      selectedDevice: selectedDevice ?? this.selectedDevice,
      isScanning: isScanning ?? this.isScanning,
      error: clearError ? null : error ?? this.error,
    );
  }

  factory SettingsState.initial() => const SettingsState(
        targetUrl: 'https://easacc.com',
        devices: [],
      );
}

