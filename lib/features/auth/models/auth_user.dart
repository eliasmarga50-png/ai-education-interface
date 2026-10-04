
class AuthUser {
  final String id;
  final String name;
  final String email;
  final bool isVerified;

  const AuthUser({
    required this.id,
    required this.name,
    required this.email,
    required this.isVerified,
  });

  AuthUser copyWith({
    String? id,
    String? name,
    String? email,
    bool? isVerified,
  }) {
    return AuthUser(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      isVerified: isVerified ?? this.isVerified,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'isVerified': isVerified,
    };
  }

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      isVerified: json['isVerified'] as bool? ?? false,
    );
  }
}

