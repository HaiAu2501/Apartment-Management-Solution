class UserEntity {
  final String uid;
  final String email;
  final String role;
  final String status;
  final String? associatedApartment; // Thêm trường này

  UserEntity({
    required this.uid,
    required this.email,
    required this.role,
    required this.status,
    this.associatedApartment,
  });
}
