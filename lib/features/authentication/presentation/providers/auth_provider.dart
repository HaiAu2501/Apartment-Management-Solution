import 'package:flutter/material.dart';
import '../../domain/entities/user.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/register_usecase.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../data/datasources/auth_remote_data_source.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class AuthProvider with ChangeNotifier {
  UserEntity? _user;
  UserEntity? get user => _user;

  final AuthRepositoryImpl authRepository;

  AuthProvider()
      : authRepository = AuthRepositoryImpl(
          remoteDataSource: AuthRemoteDataSourceImpl(
            auth: FirebaseAuth.instance,
            firestore: FirebaseFirestore.instance,
          ),
        );

  Future<void> login(String email, String password) async {
    _user = await authRepository.login(email, password);
    notifyListeners();
  }

  Future<void> register(String email, String password) async {
    _user = await authRepository.register(email, password);
    notifyListeners();
  }

  Future<void> logout() async {
    await authRepository.logout();
    _user = null;
    notifyListeners();
  }

  Future<void> changePassword(String newPassword) async {
    await authRepository.changePassword(newPassword);
    notifyListeners();
  }

  Future<void> getCurrentUser() async {
    _user = await authRepository.getCurrentUser();
    notifyListeners();
  }
}
