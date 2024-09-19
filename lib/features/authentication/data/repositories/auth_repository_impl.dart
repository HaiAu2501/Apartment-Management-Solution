import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;

  AuthRepositoryImpl({required this.remoteDataSource});

  @override
  Future<UserEntity?> login(String email, String password) {
    return remoteDataSource.login(email, password);
  }

  @override
  Future<UserEntity?> register(String email, String password) {
    return remoteDataSource.register(email, password);
  }

  @override
  Future<void> logout() {
    return remoteDataSource.logout();
  }

  @override
  Future<UserEntity?> getCurrentUser() {
    return remoteDataSource.getCurrentUser();
  }

  @override
  Future<void> changePassword(String newPassword) {
    return remoteDataSource.changePassword(newPassword);
  }
}
