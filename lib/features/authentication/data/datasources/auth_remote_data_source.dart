import '../../domain/entities/user.dart';

abstract class AuthRemoteDataSource {
  Future<User?> login(String email, String password);
  Future<User?> register(String email, String password);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  // Danh sách người dùng giả lập
  final List<Map<String, String>> _users = [
    {'id': '1', 'email': 'test@example.com', 'password': 'password123'}
  ];

  @override
  Future<User?> login(String email, String password) async {
    // Giả lập độ trễ mạng
    await Future.delayed(Duration(seconds: 1));

    // Tìm người dùng với email và mật khẩu tương ứng
    final user = _users.firstWhere(
      (user) => user['email'] == email && user['password'] == password,
      orElse: () => {},
    );

    if (user.isNotEmpty) {
      return User(id: user['id']!, email: user['email']!);
    } else {
      throw Exception('Email hoặc mật khẩu không đúng');
    }
  }

  @override
  Future<User?> register(String email, String password) async {
    // Giả lập độ trễ mạng
    await Future.delayed(Duration(seconds: 1));

    // Kiểm tra xem email đã tồn tại chưa
    final existingUser = _users.any((user) => user['email'] == email);
    if (existingUser) {
      throw Exception('Email đã được sử dụng');
    } else {
      final newUser = {
        'id': (_users.length + 1).toString(),
        'email': email,
        'password': password
      };
      _users.add(newUser);
      return User(id: newUser['id']!, email: newUser['email']!);
    }
  }
}
