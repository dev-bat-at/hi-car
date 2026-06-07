import 'dart:convert';

class UserModel {
  final String id;
  final String phone;
  final String name;
  final String licensePlate;
  final int generateCredits;
  final String? token;
  final String? avatarUrl;

  const UserModel({
    required this.id,
    required this.phone,
    required this.name,
    required this.licensePlate,
    required this.generateCredits,
    this.token,
    this.avatarUrl,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    // API v1.1.0 provides data in a nested structure or flat
    final token = json['token'] as String?;

    // Support both flattened and nested driver info
    final driver = json['driver'] as Map<String, dynamic>? ?? json;

    return UserModel(
      id: (driver['id'] ?? '').toString(),
      phone: driver['phone'] as String? ?? '',
      name: driver['name'] as String? ?? '',
      licensePlate: driver['active_vehicle_plate'] as String? ??
          driver['license_plate'] as String? ??
          '',
      generateCredits: driver['generate_credits'] as int? ?? 0,
      token: token ?? json['token'] as String?,
      avatarUrl: driver['avatar_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'phone': phone,
      'name': name,
      'license_plate': licensePlate,
      'generate_credits': generateCredits,
      'token': token,
      'avatar_url': avatarUrl,
    };
  }

  String toJsonString() => jsonEncode(toJson());

  factory UserModel.fromJsonString(String jsonString) {
    return UserModel.fromJson(jsonDecode(jsonString) as Map<String, dynamic>);
  }

  UserModel copyWith({
    String? id,
    String? phone,
    String? name,
    String? licensePlate,
    int? generateCredits,
    String? token,
    String? avatarUrl,
  }) {
    return UserModel(
      id: id ?? this.id,
      phone: phone ?? this.phone,
      name: name ?? this.name,
      licensePlate: licensePlate ?? this.licensePlate,
      generateCredits: generateCredits ?? this.generateCredits,
      token: token ?? this.token,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }

  @override
  String toString() => 'UserModel(id: $id, name: $name, phone: $phone)';
}
