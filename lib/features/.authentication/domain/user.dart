class User {
  final String uid;
  final String email;
  final String role;

  User({
    required this.uid,
    required this.email,
    required this.role,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      uid: json['uid'],
      email: json['email'],
      role: json['role'],
    );
  }
}
