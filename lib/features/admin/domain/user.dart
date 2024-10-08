// lib/features/admin/domain/user.dart
class User {
  final String id;
  final String email;
  final String fullName;
  final String role;
  final String gender;
  final String dob;
  final String phone;
  final int? floor;
  final int? apartmentNumber;
  final String? jobTitle;
  final String status;

  User({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    required this.gender,
    required this.dob,
    required this.phone,
    this.floor,
    this.apartmentNumber,
    this.jobTitle,
    required this.status,
  });

  factory User.fromFirestore(Map<String, dynamic> data, String documentId) {
    return User(
      id: documentId,
      email: data['email']['stringValue'] ?? '',
      fullName: data['fullName']['stringValue'] ?? '',
      role: data['role']['stringValue'] ?? '',
      gender: data['gender']['stringValue'] ?? '',
      dob: data['dob']['stringValue'] ?? '',
      phone: data['phone']['stringValue'] ?? '',
      floor: data.containsKey('floor') ? int.parse(data['floor']['integerValue']) : null,
      apartmentNumber: data.containsKey('apartmentNumber') ? int.parse(data['apartmentNumber']['integerValue']) : null,
      jobTitle: data.containsKey('jobTitle') ? data['jobTitle']['stringValue'] : null,
      status: data['status']['stringValue'] ?? '',
    );
  }
}
