enum NetworkDeviceType { wifi, bluetooth }

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

