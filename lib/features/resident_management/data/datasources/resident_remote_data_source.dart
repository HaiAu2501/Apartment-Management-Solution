import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/resident.dart';

abstract class ResidentRemoteDataSource {
  Future<List<ResidentEntity>> getResidents();
  Future<void> approveResident(String residentId);
}

class ResidentRemoteDataSourceImpl implements ResidentRemoteDataSource {
  final FirebaseFirestore firestore;

  ResidentRemoteDataSourceImpl({required this.firestore});

  @override
  Future<List<ResidentEntity>> getResidents() async {
    QuerySnapshot snapshot = await firestore.collection('residents').get();

    return snapshot.docs.map((doc) {
      return ResidentEntity(
        id: doc.id,
        fullName: doc.get('fullName'),
        phoneNumber: doc.get('phoneNumber'),
        email: doc.get('email'),
        apartmentId: doc.get('apartmentId'),
      );
    }).toList();
  }

  @override
  Future<void> approveResident(String residentId) async {
    // Cập nhật trạng thái người dùng
    await firestore.collection('users').doc(residentId).update({
      'status': 'active',
    });
  }
}
