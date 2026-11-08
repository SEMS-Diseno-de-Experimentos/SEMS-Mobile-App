/// User roles.
enum UserRole { admin, staff }

class User {
  final String id;
  final String email;
  final String fullName;
  final UserRole role;
  final String segment;

  const User({
    required this.id,
    required this.email,
    required this.fullName,
    this.role = UserRole.staff,
    this.segment = 'RETAIL',
  });

  User copyWith({
    String? id,
    String? email,
    String? fullName,
    UserRole? role,
    String? segment,
  }) =>
      User(
        id: id ?? this.id,
        email: email ?? this.email,
        fullName: fullName ?? this.fullName,
        role: role ?? this.role,
        segment: segment ?? this.segment,
      );

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: (json['userId'] ?? json['id'] ?? '').toString(),
        email: (json['emailAddress'] ?? json['email'] ?? '').toString(),
        fullName: (json['fullName'] ?? json['name'] ?? '').toString(),
        role: _parseRole(json['roles'] is List && (json['roles'] as List).isNotEmpty
            ? (json['roles'] as List).first
            : json['role']),
        segment: json['segment']?.toString() ?? 'RETAIL',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': id,
        'email': email,
        'emailAddress': email,
        'fullName': fullName,
        'role': role.name.toUpperCase(),
        'roles': [role.name.toUpperCase()],
        'segment': segment,
      };

  static UserRole _parseRole(dynamic v) {
    final s = (v as String? ?? '').toUpperCase();
    if (s.contains('ADMIN')) return UserRole.admin;
    return UserRole.staff;
  }
}

/// Auth response returned by login/register.
class AuthResponse {
  final String token;
  final String? refreshToken;
  final User user;
  const AuthResponse({required this.token, required this.user, this.refreshToken});
}
