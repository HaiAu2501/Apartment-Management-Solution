import 'package:flutter/material.dart';
import '../../domain/entities/user.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/register_usecase.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../data/datasources/auth_remote_data_source.dart';

class AuthProvider with ChangeNotifier {
  User? _user;
  User? get user => _user;

  final LoginUseCase loginUseCase;
  final RegisterUseCase registerUseCase;

  AuthProvider()
      : loginUseCase = LoginUseCase(
          AuthRepositoryImpl(
            remoteDataSource: AuthRemoteDataSourceImpl(),
          ),
        ),
        registerUseCase = RegisterUseCase(
          AuthRepositoryImpl(
            remoteDataSource: AuthRemoteDataSourceImpl(),
          ),
        );

  Future<void> login(String email, String password) async {
    _user = await loginUseCase(email, password);
    notifyListeners();
  }

  Future<void> register(String email, String password) async {
    _user = await registerUseCase(email, password);
    notifyListeners();
  }

  void logout() {
    _user = null;
    notifyListeners();
  }
}
