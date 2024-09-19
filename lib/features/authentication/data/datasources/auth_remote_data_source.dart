import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/user.dart';

abstract class AuthRemoteDataSource {
  Future<UserEntity?> login(String email, String password);
  Future<UserEntity?> register(String email, String password);
  Future<void> logout();
  Future<UserEntity?> getCurrentUser();
  Future<void> changePassword(String newPassword);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final firebase_auth.FirebaseAuth auth;
  final FirebaseFirestore firestore;

  AuthRemoteDataSourceImpl({required this.auth, required this.firestore});

  @override
  Future<UserEntity?> login(String email, String password) async {
    try {
      firebase_auth.UserCredential result = await auth
          .signInWithEmailAndPassword(email: email, password: password);
      firebase_auth.User user = result.user!;

      // Lấy thông tin người dùng từ Firestore
      DocumentSnapshot doc =
          await firestore.collection('users').doc(user.uid).get();
      if (doc.exists) {
        return UserEntity(
          uid: user.uid,
          email: user.email ?? '',
          role: doc.get('role'),
          status: doc.get('status'),
          associatedApartment: doc.get('associatedApartment'), // Lấy trường này
        );
      } else {
        return null;
      }
    } catch (e) {
      throw Exception('Đăng nhập thất bại: $e');
    }
  }

  @override
  Future<UserEntity?> register(String email, String password) async {
    try {
      firebase_auth.UserCredential result = await auth
          .createUserWithEmailAndPassword(email: email, password: password);
      firebase_auth.User user = result.user!;

      // Lưu thông tin người dùng vào Firestore
      await firestore.collection('users').doc(user.uid).set({
        'email': email,
        'role': 'resident', // Mặc định là cư dân
        'status': 'pending',
        'associatedApartment': null, // Ban đầu chưa có căn hộ
        'createdAt': FieldValue.serverTimestamp(),
      });

      return UserEntity(
        uid: user.uid,
        email: email,
        role: 'resident',
        status: 'pending',
        associatedApartment: null,
      );
    } catch (e) {
      throw Exception('Đăng ký thất bại: $e');
    }
  }

  @override
  Future<void> logout() async {
    await auth.signOut();
  }

  @override
  Future<UserEntity?> getCurrentUser() async {
    firebase_auth.User? user = auth.currentUser;
    if (user != null) {
      DocumentSnapshot doc =
          await firestore.collection('users').doc(user.uid).get();
      if (doc.exists) {
        return UserEntity(
          uid: user.uid,
          email: user.email ?? '',
          role: doc.get('role'),
          status: doc.get('status'),
          associatedApartment: doc.get('associatedApartment'), // Lấy trường này
        );
      }
    }
    return null;
  }

  @override
  Future<void> changePassword(String newPassword) async {
    firebase_auth.User? user = auth.currentUser;
    if (user != null) {
      await user.updatePassword(newPassword);
    }
  }
}
