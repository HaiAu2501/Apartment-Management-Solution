class User {
  final String email;
  final String token;
  final String role; // 'admin', 'resident' or 'third_party'

  User({
    required this.email,
    required this.token,
    required this.role,
  });
}
