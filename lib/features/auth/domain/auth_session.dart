class AuthUser {
  const AuthUser({required this.id, required this.name, required this.email});

  final int id;
  final String name;
  final String email;

  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
    id: int.parse(json['id'].toString()),
    name: json['name'].toString(),
    email: json['email'].toString(),
  );
}

class AuthSession {
  const AuthSession({
    required this.accessToken,
    required this.expiresAt,
    required this.user,
  });

  final String accessToken;
  final DateTime expiresAt;
  final AuthUser user;

  factory AuthSession.fromJson(Map<String, dynamic> json) => AuthSession(
    accessToken: json['token'].toString(),
    expiresAt: DateTime.parse(json['expiresAt'].toString()),
    user: AuthUser.fromJson(Map<String, dynamic>.from(json['user'] as Map)),
  );
}
