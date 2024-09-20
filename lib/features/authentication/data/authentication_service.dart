import 'dart:convert';
import 'package:http/http.dart' as http;
import '../domain/user.dart';

class AuthenticationService {
  final String apiKey;
  final String projectId;

  AuthenticationService({required this.apiKey, required this.projectId});

  // Đăng ký người dùng
  Future<String?> signUp(String email, String password) async {
    final url =
        'https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=$apiKey';

    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
        'returnSecureToken': true,
      }),
    );

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      return responseData['idToken'];
    } else {
      print('Lỗi đăng ký: ${response.statusCode}');
      print('Chi tiết lỗi: ${response.body}');
      return null;
    }
  }

  // Đăng nhập người dùng
  Future<String?> signIn(String email, String password) async {
    final url =
        'https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=$apiKey';

    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
        'returnSecureToken': true,
      }),
    );

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      return responseData['idToken'];
    } else {
      print('Lỗi đăng nhập: ${response.statusCode}');
      print('Chi tiết lỗi: ${response.body}');
      return null;
    }
  }

  // Lấy UID từ idToken
  Future<String?> getUserUid(String idToken) async {
    final url =
        'https://identitytoolkit.googleapis.com/v1/accounts:lookup?key=$apiKey';

    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'idToken': idToken,
      }),
    );

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      if (responseData['users'] != null && responseData['users'].length > 0) {
        return responseData['users'][0]['localId'];
      } else {
        print('Không tìm thấy người dùng.');
        return null;
      }
    } else {
      print('Lỗi khi lấy thông tin người dùng: ${response.statusCode}');
      print('Chi tiết lỗi: ${response.body}');
      return null;
    }
  }

  // Tạo tài liệu người dùng trong Firestore
  Future<bool> createUserDocument(
      String idToken, String uid, String email, String role) async {
    final uri = Uri.https(
      'firestore.googleapis.com',
      '/v1/projects/$projectId/databases/(default)/documents/users/$uid',
      {
        'updateMask.fieldPaths': ['email', 'role'],
        'key': apiKey,
      },
    );

    final firestoreData = {
      'fields': {
        'email': {'stringValue': email},
        'role': {'stringValue': role}, // 'admin', 'resident', 'third_party'
      },
    };

    final response = await http.patch(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $idToken',
      },
      body: jsonEncode(firestoreData),
    );

    if (response.statusCode == 200) {
      print('Tài liệu người dùng đã được tạo thành công.');
      return true;
    } else {
      print('Lỗi khi tạo tài liệu người dùng: ${response.statusCode}');
      print('Chi tiết lỗi: ${response.body}');
      return false;
    }
  }

  // Lấy vai trò của người dùng từ Firestore
  Future<String?> getUserRole(String uid, String idToken) async {
    final uri = Uri.https(
      'firestore.googleapis.com',
      '/v1/projects/$projectId/databases/(default)/documents/users/$uid',
      {
        'key': apiKey,
      },
    );

    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $idToken',
      },
    );

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      if (responseData.containsKey('fields') &&
          responseData['fields'].containsKey('role')) {
        return responseData['fields']['role']['stringValue'];
      } else {
        print('Không tìm thấy trường role.');
        return null;
      }
    } else {
      print('Lỗi khi lấy vai trò: ${response.statusCode}');
      print('Chi tiết lỗi: ${response.body}');
      return null;
    }
  }

  // Cập nhật vai trò của người dùng trong Firestore (Không cần thiết, bỏ)
  // Bạn có thể loại bỏ hàm này nếu không cần thiết
}
