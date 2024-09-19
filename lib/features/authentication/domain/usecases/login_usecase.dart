import '../repositories/auth_repository.dart';
import '../entities/user.dart';

class LoginUseCase {
  final AuthRepository repository;

  LoginUseCase(this.repository);

  Future<UserEntity?> call(String email, String password) {
    return repository.login(email, password);
  }
}
