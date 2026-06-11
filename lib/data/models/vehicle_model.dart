class VehicleModel {
  final int id;
  final String plateNumber;
  final String? model;
  final String? color;
  final bool isActive;

  VehicleModel({
    required this.id,
    required this.plateNumber,
    this.model,
    this.color,
    this.isActive = false,
  });

  factory VehicleModel.fromJson(Map<String, dynamic> json) {
    return VehicleModel(
      id: json['id'] as int,
      plateNumber: json['plate_number'] ?? json['active_vehicle_plate'] ?? '',
      model: json['model'],
      color: json['color'],
      isActive: json['is_active'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'plate_number': plateNumber,
      'model': model,
      'color': color,
      'is_active': isActive,
    };
  }
}
