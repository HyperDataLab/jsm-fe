import 'package:equatable/equatable.dart';

/// Authenticated user identity, sourced from Central SSO userinfo.
class AuthUser extends Equatable {
  final String sub;
  final String? email;
  final String? name;
  final String? picture;
  final String? role;
  final String? studentId;
  final String? major;

  const AuthUser({
    required this.sub,
    this.email,
    this.name,
    this.picture,
    this.role,
    this.studentId,
    this.major,
  });

  @override
  List<Object?> get props => [
    sub,
    email,
    name,
    picture,
    role,
    studentId,
    major,
  ];
}
