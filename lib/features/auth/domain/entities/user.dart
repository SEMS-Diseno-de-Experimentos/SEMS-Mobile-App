/// User roles.
enum UserRole { admin, staff }

class User {
  final String id;
  final String email;
  final String fullName;
  final UserRole role;

  const User({
    required this.id,
    required this.email,
    required this.fullName,
    this.role = UserRole.staff,
  });

  User copyWith({
    String? id,
    String? email,
    String? fullName,
    UserRole? role,
  }) =>
      User(
        id: id ?? this.id,
        email: email ?? this.email,
        fullName: fullName ?? this.fullName,
        role: role ?? this.role,
      );

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'] as String? ?? '',
        email: json['email'] as String? ?? '',
        fullName: json['fullName'] as String? ?? '',
        role: _parseRole(json['role']),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'fullName': fullName,
        'role': role.name.toUpperCase(),
      };

  static UserRole _parseRole(dynamic v) {
    final s = (v as String? ?? '').toUpperCase();
    if (s == 'ADMIN') return UserRole.admin;
    return UserRole.staff;
  }
}

/// Auth response returned by login/register.
class AuthResponse {
  final String token;
  final User user;
  const AuthResponse({required this.token, required this.user});
}
