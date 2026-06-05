class BluetoothDeviceModel {
  final String name;
  final String address;
  final bool isSelected;
  final bool isConnected;

  const BluetoothDeviceModel({
    required this.name,
    required this.address,
    this.isSelected = false,
    this.isConnected = false,
  });

  BluetoothDeviceModel copyWith({
    String? name,
    String? address,
    bool? isSelected,
    bool? isConnected,
  }) {
    return BluetoothDeviceModel(
      name: name ?? this.name,
      address: address ?? this.address,
      isSelected: isSelected ?? this.isSelected,
      isConnected: isConnected ?? this.isConnected,
    );
  }

  factory BluetoothDeviceModel.fromMap(Map<dynamic, dynamic> map) {
    return BluetoothDeviceModel(
      name: map['name'] as String? ?? 'Unknown',
      address: map['address'] as String? ?? '',
      isConnected: map['isConnected'] as bool? ?? false,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BluetoothDeviceModel && other.address == address;
  }

  @override
  int get hashCode => address.hashCode;

  @override
  String toString() => 'BluetoothDeviceModel(name: $name, address: $address)';
}
