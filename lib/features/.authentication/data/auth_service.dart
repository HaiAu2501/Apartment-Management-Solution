// lib/features/authentication/data/auth_service.dart

import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:uuid/uuid.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthenticationService {
  final String apiKey;
  final String projectId;
  final FlutterSecureStorage secureStorage = const FlutterSecureStorage();

  AuthenticationService({required this.apiKey, required this.projectId});

  // Đăng ký người dùng mới
  Future<String?> signUp(String email, String password) async {
    final url = 'https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=$apiKey';
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
      String idToken = responseData['idToken'];
      await setIdToken(idToken); // Lưu idToken vào Secure Storage
      return idToken;
    } else {
      print('Lỗi khi đăng ký: ${response.statusCode}');
      print('Chi tiết lỗi: ${response.body}');
      return null;
    }
  }

  // Đăng nhập người dùng
  Future<Map<String, dynamic>?> signIn(String email, String password) async {
    final url = 'https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=$apiKey';
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
      String idToken = responseData['idToken'];
      String uid = responseData['localId'];
      String email = responseData['email'];
      await setIdToken(idToken);
      return {'idToken': idToken, 'uid': uid, 'email': email};
    } else {
      print('Lỗi khi đăng nhập: ${response.statusCode}');
      print('Chi tiết lỗi: ${response.body}');
      return null;
    }
  }

  // Lấy UID từ idToken
  Future<String?> getUserUid(String idToken) async {
    final url = 'https://identitytoolkit.googleapis.com/v1/accounts:lookup?key=$apiKey';
    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'idToken': idToken}),
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

  // Lấy email người dùng từ Firestore dựa trên uid
  Future<String?> getEmail(String idToken, String uid) async {
    final url = 'https://firestore.googleapis.com/v1/projects/$projectId/databases/-default-/data/~2Fadmin~$uid?key=$apiKey';

    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $idToken',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      if (responseData['fields'] != null && responseData['fields']['email'] != null && responseData['fields']['email']['stringValue'] != null) {
        return responseData['fields']['email']['stringValue'];
      } else {
        print('Email không được tìm thấy cho người dùng này.');
        return null;
      }
    } else {
      print('Lỗi khi truy xuất tài liệu người dùng: ${response.statusCode}');
      print('Chi tiết lỗi: ${response.body}');
      return null;
    }
  }

  // Tạo tài liệu trong collection 'queue' với documentID tự tạo
  Future<bool> createQueueDocument(Map<String, dynamic> queueData) async {
    String collectionPath = 'queue';
    String documentId = Uuid().v4(); // Tạo một UUID duy nhất làm documentID

    final url = 'https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents/$collectionPath/$documentId?key=$apiKey';

    final response = await http.patch(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'fields': queueData.map((key, value) => MapEntry(key, encodeField(value))),
      }),
    );

    if (response.statusCode == 200) {
      print('Document đã được tạo với ID: $documentId');
      return true;
    } else {
      print('Lỗi khi tạo document trong queue: ${response.statusCode}');
      print('Chi tiết lỗi: ${response.body}');
      return false;
    }
  }

  // Tạo tài liệu trong collection 'residents' hoặc 'guests'
  Future<bool> createUserDocument(String idToken, String uid, Map<String, dynamic> userData, String collection) async {
    final url = 'https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents/$collection/$uid?key=$apiKey';

    final response = await http.patch(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $idToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'fields': userData.map((key, value) => MapEntry(key, encodeField(value))),
      }),
    );

    if (response.statusCode == 200) {
      return true;
    } else {
      print('Lỗi khi tạo document trong $collection: ${response.statusCode}');
      print('Chi tiết lỗi: ${response.body}');
      return false;
    }
  }

  // Xóa tài liệu từ collection 'queue'
  Future<bool> deleteQueueDocument(String documentName, String idToken) async {
    final url = 'https://firestore.googleapis.com/v1/$documentName?key=$apiKey';

    final response = await http.delete(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $idToken',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return true;
    } else {
      print('Lỗi khi xóa document từ queue: ${response.statusCode}');
      print('Chi tiết lỗi: ${response.body}');
      return false;
    }
  }

  // Cập nhật tài liệu trong collection 'queue'
  Future<bool> updateQueueDocument(String documentName, Map<String, dynamic> updatedData, String idToken, List<String> fieldPaths) async {
    // Xây dựng updateMask.fieldPaths từ danh sách fieldPaths
    final updateMask = {
      'fieldPaths': fieldPaths,
    };

    final url = 'https://firestore.googleapis.com/v1/$documentName?key=$apiKey';

    final response = await http.patch(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $idToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'fields': updatedData.map((key, value) => MapEntry(key, encodeField(value))),
        'updateMask': updateMask, // Thêm updateMask vào body
      }),
    );

    if (response.statusCode == 200) {
      return true;
    } else {
      print('Lỗi khi cập nhật document trong queue: ${response.statusCode}');
      print('Chi tiết lỗi: ${response.body}');
      return false;
    }
  }

  // Helper function để mã hóa trường dữ liệu
  Map<String, dynamic> encodeField(dynamic value) {
    if (value is String) {
      return {'stringValue': value};
    } else if (value is int) {
      return {'integerValue': value.toString()};
    } else if (value is double) {
      return {'doubleValue': value};
    } else if (value is bool) {
      return {'booleanValue': value};
    } else if (value is List) {
      return {
        'arrayValue': {
          'values': value.map((item) => encodeField(item)).toList(),
        }
      };
    } else if (value is Map) {
      return {
        'mapValue': {
          'fields': value.map((k, v) => MapEntry(k, encodeField(v))),
        }
      };
    } else if (value is DateTime) {
      return {'timestampValue': value.toIso8601String()};
    } else {
      return {};
    }
  }

  // *** Các Hàm Mới Được Thêm Vào ***

  /// Lưu trữ ID Token vào Secure Storage
  Future<void> setIdToken(String token) async {
    await secureStorage.write(key: 'idToken', value: token);
  }

  /// Lấy ID Token từ Secure Storage
  Future<String?> getIdToken() async {
    return await secureStorage.read(key: 'idToken');
  }

  /// Xóa ID Token khỏi Secure Storage
  Future<void> clearIdToken() async {
    await secureStorage.delete(key: 'idToken');
  }
}
