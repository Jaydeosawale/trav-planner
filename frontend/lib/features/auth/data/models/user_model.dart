class UserModel {
  final String id;
  final String email;
  final String fullName;
  final bool isActive;
  final DateTime createdAt;
  final String role;

  const UserModel({
    required this.id,
    required this.email,
    required this.fullName,
    required this.isActive,
    required this.createdAt,
    required this.role,
  });

  bool get isAdmin => role.toLowerCase() == 'admin';

  bool get isUser => role.toLowerCase() == 'user';

  factory UserModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      fullName: json['full_name'] as String,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(
        json['created_at'] as String,
      ),
      role: json['role'] as String? ?? 'user',
    );
  }
}
