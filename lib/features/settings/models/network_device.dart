enum NetworkDeviceType {
  bluetoothPrinter,
  bluetoothEarbuds,
  bluetoothOther,
}

class NetworkDevice {
  const NetworkDevice({
    required this.id,
    required this.name,
    required this.type,
    this.address,
  });

  final String id;
  final String name;
  final NetworkDeviceType type;
  final String? address;

  @override
  String toString() => '$name ($type)';
}

extension NetworkDeviceTypeLabel on NetworkDeviceType {
  String get label {
    switch (this) {
      case NetworkDeviceType.bluetoothPrinter:
        return 'Bluetooth printer';
      case NetworkDeviceType.bluetoothEarbuds:
        return 'Bluetooth earbuds';
      case NetworkDeviceType.bluetoothOther:
        return 'Bluetooth device';
    }
  }
}
