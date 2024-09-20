// lib/features/authentication/data/authentication_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;

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

  // Tạo tài liệu người dùng trong Firestore chỉ dành cho Admin
  Future<bool> createUserDocument(
      String idToken, String uid, Map<String, dynamic> userData) async {
    final uri = Uri.https(
      'firestore.googleapis.com',
      '/v1/projects/$projectId/databases/(default)/documents/users/$uid',
      {
        'key': apiKey,
      },
    );

    final firestoreData = {
      'fields': {
        'email': {'stringValue': userData['email']},
        'full_name': {'stringValue': userData['full_name']},
        'gender': {'stringValue': userData['gender']},
        'dob': {'timestampValue': userData['dob']},
        'cccd': {'stringValue': userData['cccd']},
        'apartment_name': {'stringValue': userData['apartment_name']},
        'building_name': {'stringValue': userData['building_name']},
        'floor_number': {'integerValue': userData['floor_number'].toString()},
        'apartment_number': {
          'integerValue': userData['apartment_number'].toString()
        },
        'status': {'stringValue': 'approval'},
        'role': {'stringValue': userData['role']},
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

  // Xóa tài liệu trong 'queue'
  Future<bool> deleteQueueDocument(String queueDocName, String idToken) async {
    final uri = Uri.https(
      'firestore.googleapis.com',
      '/v1/projects/$projectId/databases/(default)/documents/queue/$queueDocName',
      {
        'key': apiKey,
      },
    );

    final response = await http.delete(
      uri,
      headers: {
        'Authorization': 'Bearer $idToken',
      },
    );

    if (response.statusCode == 200) {
      print('Tài liệu queue đã bị xóa thành công.');
      return true;
    } else {
      print('Lỗi khi xóa tài liệu queue: ${response.statusCode}');
      print('Chi tiết lỗi: ${response.body}');
      return false;
    }
  }

  // Tạo tài liệu trong 'queue'
  Future<bool> createQueueDocument(
      String idToken, Map<String, dynamic> queueData) async {
    final uri = Uri.https(
      'firestore.googleapis.com',
      '/v1/projects/$projectId/databases/(default)/documents/queue',
      {
        'key': apiKey,
      },
    );

    final firestoreData = {
      'fields': {
        'uid': {'stringValue': queueData['uid']},
        'full_name': {'stringValue': queueData['full_name']},
        'gender': {'stringValue': queueData['gender']},
        'dob': {'timestampValue': queueData['dob']},
        'cccd': {'stringValue': queueData['cccd']},
        'apartment_name': {'stringValue': queueData['apartment_name']},
        'building_name': {'stringValue': queueData['building_name']},
        'floor_number': {'integerValue': queueData['floor_number'].toString()},
        'apartment_number': {
          'integerValue': queueData['apartment_number'].toString()
        },
        'status': {'stringValue': 'pending'},
        'role': {'stringValue': queueData['role']}, // Thêm trường role nếu cần
      },
    };

    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $idToken',
      },
      body: jsonEncode(firestoreData),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      print('Tài liệu queue đã được tạo thành công.');
      return true;
    } else {
      print('Lỗi khi tạo queue: ${response.statusCode}');
      print('Chi tiết lỗi: ${response.body}');
      return false;
    }
  }
}
