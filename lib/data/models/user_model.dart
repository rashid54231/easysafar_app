class UserModel {
  final String id;
  final String fullName;
  final String phoneNumber;
  final String role; // 'driver' or 'passenger'

  UserModel({
    required this.id,
    required this.fullName,
    required this.phoneNumber,
    required this.role,
  });

  // Database (JSON) se Flutter Object banane ke liye
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      fullName: json['full_name'] ?? '',
      phoneNumber: json['phone_number'] ?? '',
      role: json['user_role'] ?? 'passenger',
    );
  }

  // Flutter se Database (JSON) mein bhejne ke liye
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'phone_number': phoneNumber,
      'user_role': role,
    };
  }
}