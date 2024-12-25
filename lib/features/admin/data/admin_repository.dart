// lib/features/admin/data/admin_repository.dart
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../.authentication/data/auth_service.dart';

class AdminRepository {
  final String apiKey;
  final String projectId;

  AdminRepository({required this.apiKey, required this.projectId});

  // Hàm lấy tất cả danh sách chờ duyệt với phân trang
  Future<List<dynamic>> fetchAllQueue(String idToken) async {
    List<dynamic> allDocuments = [];
    String? nextPageToken;
    const int pageSize = 100; // Firestore REST API có giới hạn tối đa pageSize là 100

    do {
      // Tạo URL với các tham số phân trang và sắp xếp
      String url = 'https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents/queue?key=$apiKey&pageSize=$pageSize&orderBy=fullName';

      if (nextPageToken != null && nextPageToken.isNotEmpty) {
        url += '&pageToken=$nextPageToken';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $idToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final documents = data['documents'] ?? [];
        allDocuments.addAll(documents);
        nextPageToken = data['nextPageToken'];
      } else {
        throw Exception('Lỗi khi tải queue: ${response.statusCode} ${response.body}');
      }
    } while (nextPageToken != null);

    return allDocuments;
  }

  // Hàm lấy danh sách cư dân
  Future<List<dynamic>> fetchResidents(String idToken) async {
    final url = 'https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents/residents?key=$apiKey';

    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $idToken',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['documents'] ?? [];
    } else {
      throw Exception('Lỗi khi tải residents: ${response.statusCode} ${response.body}');
    }
  }

  // Hàm lấy danh sách khách
  Future<List<dynamic>> fetchGuests(String idToken) async {
    final url = 'https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents/guests?key=$apiKey';

    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $idToken',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['documents'] ?? [];
    } else {
      throw Exception('Lỗi khi tải guests: ${response.statusCode} ${response.body}');
    }
  }

  // Hàm phê duyệt người dùng từ queue
  Future<void> approveUser(String queueDocName, Map<String, dynamic> queueData, String idToken, AuthenticationService authService) async {
    String role = queueData['role']['stringValue'];
    String email = queueData['email']['stringValue'];
    String password = queueData['password']['stringValue'];
    Map<String, dynamic> targetData = {};

    // Tạo tài khoản Firebase cho người dùng
    String? idTokenNew = await authService.signUp(email, password);
    if (idTokenNew == null) {
      throw Exception('Không thể tạo tài khoản Firebase cho người dùng.');
    }

    // Lấy UID từ idToken
    String? uid = await authService.getUserUid(idTokenNew);
    if (uid == null) {
      throw Exception('Không lấy được UID của người dùng.');
    }

    // **New Code Start**
    // Extract floor and apartmentNumber from queueData
    int floor;
    int apartmentNumber;
    try {
      floor = int.parse(queueData['floor']['integerValue']);
      apartmentNumber = int.parse(queueData['apartmentNumber']['integerValue']);
    } catch (e) {
      throw Exception('Dữ liệu floor hoặc apartmentNumber không hợp lệ.');
    }

    // Generate profileId as "{floor}-{apartmentNumber}"
    String profileId = '$floor-$apartmentNumber';
    // **New Code End**

    // Chuẩn bị dữ liệu cho collection đích và thêm profileId
    if (role == 'Cư dân') {
      targetData = {
        'fullName': queueData['fullName']['stringValue'],
        'gender': queueData['gender']['stringValue'],
        'dob': queueData['dob']['stringValue'],
        'phone': queueData['phone']['stringValue'],
        'id': queueData['id']['stringValue'],
        'floor': floor, // Already parsed as int
        'apartmentNumber': apartmentNumber, // Already parsed as int
        'email': email,
        'status': 'Đã duyệt',
        'profileId': profileId, // Sử dụng profileId mới
      };
    } else if (role == 'Khách') {
      targetData = {
        'fullName': queueData['fullName']['stringValue'],
        'gender': queueData['gender']['stringValue'],
        'dob': queueData['dob']['stringValue'],
        'phone': queueData['phone']['stringValue'],
        'id': queueData['id']['stringValue'],
        'email': email,
        'jobTitle': queueData['jobTitle']['stringValue'],
        'status': 'Đã duyệt',
        'profileId': profileId, // Sử dụng profileId mới
      };
    } else {
      throw Exception('Vai trò không hợp lệ.');
    }

    // Chọn collection đích dựa trên vai trò
    String targetCollection = role == 'Cư dân' ? 'residents' : 'guests';

    // Gọi phương thức để tạo document trong collection đích với UID làm documentID
    bool success = await authService.createUserDocument(
      idToken,
      uid,
      targetData,
      targetCollection,
    );

    if (!success) {
      throw Exception('Phê duyệt thất bại khi tạo tài liệu trong $targetCollection.');
    }

    // Tạo profile document trong collection 'profiles' với documentId = profileId ("{floor}-{apartmentNumber}")
    Map<String, dynamic> profileData = {
      'householdHead': _encodeField(''), // Initialize as empty string
      'occupation': _encodeField(''), // Initialize as empty string
      'emergencyContacts': _encodeField(<String>[]), // Empty array
      'members': _encodeField(<Map<String, dynamic>>[]), // Empty array
      'moveInDate': _encodeField(''), // Initialize as empty string
      'moveOutDate': _encodeField(''), // Initialize as empty string
      'vehicles': _encodeField(<Map<String, dynamic>>[]), // Empty array
      'utilities': _encodeField(<String>[]), // Empty array
    };

    final profileUrl = 'https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents/profiles/$profileId?key=$apiKey';

    final profileResponse = await http.patch(
      Uri.parse(profileUrl),
      headers: {
        'Authorization': 'Bearer $idToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'fields': profileData,
      }),
    );

    if (profileResponse.statusCode != 200) {
      throw Exception('Lỗi khi tạo profile: ${profileResponse.statusCode} ${profileResponse.body}');
    }

    // Xóa tài liệu từ 'queue'
    bool deleteSuccess = await authService.deleteQueueDocument(queueDocName, idToken);
    if (!deleteSuccess) {
      throw Exception('Phê duyệt thành công nhưng không thể xóa tài liệu trong queue.');
    }
  }

  // Hàm từ chối người dùng
  Future<void> rejectUser(String queueDocName, String idToken, AuthenticationService authService) async {
    bool deleteSuccess = await authService.deleteQueueDocument(queueDocName, idToken);
    if (!deleteSuccess) {
      throw Exception('Không thể xóa tài liệu trong queue.');
    }
  }

  // Hàm cập nhật tài liệu trong 'queue'
  Future<void> updateQueueDocument(String documentName, Map<String, dynamic> updatedData, String idToken) async {
    // Tạo danh sách các field paths từ updatedData
    List<String> fieldPaths = updatedData.keys.toList();

    // Tạo phần query string cho updateMask.fieldPaths
    String updateMask = fieldPaths.map((field) => 'updateMask.fieldPaths=$field').join('&');

    final url = 'https://firestore.googleapis.com/v1/$documentName?key=$apiKey&$updateMask';

    // **Debug:** In URL và payload
    // print('Update URL: $url');
    // print('Payload: ${jsonEncode({
    //       'fields': updatedData.map((key, value) => MapEntry(key, _encodeField(value))),
    //     })}');

    final response = await http.patch(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $idToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'fields': updatedData.map((key, value) => MapEntry(key, _encodeField(value))),
      }),
    );

    // **Debug:** In phản hồi từ Firestore
    // print('Response Status: ${response.statusCode}');
    // print('Response Body: ${response.body}');

    if (response.statusCode == 200) {
      // Cập nhật thành công
      return;
    } else {
      throw Exception('Lỗi khi cập nhật document trong queue: ${response.statusCode} ${response.body}');
    }
  }

  /// Fetches a profile document by profileId.
  Future<Map<String, dynamic>> fetchProfile(String profileId, String idToken) async {
    final url = 'https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents/profiles/$profileId?key=$apiKey';

    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $idToken',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['fields'] ?? {};
    } else {
      throw Exception('Lỗi khi lấy profile: ${response.statusCode} ${response.body}');
    }
  }

  // Hàm cập nhật cư dân
  Future<void> updateResident({
    required String documentName, // Full path of the document
    required int apartmentNumber,
    required String dob,
    required String email,
    required int floor,
    required String fullName,
    required String gender,
    required String id,
    required String phone,
    required String idToken,
  }) async {
    // Prepare the fields to update
    Map<String, dynamic> updatedFields = {
      'apartmentNumber': {'integerValue': apartmentNumber},
      'dob': {'stringValue': dob},
      'email': {'stringValue': email},
      'floor': {'integerValue': floor},
      'fullName': {'stringValue': fullName},
      'gender': {'stringValue': gender},
      'id': {'stringValue': id},
      'phone': {'stringValue': phone},
      'profileId': {'stringValue': '$floor-$apartmentNumber'}
      // 'status' is fixed as "Đã duyệt" and should not be updated here
    };
    String profileId = '$floor-$apartmentNumber';
    // Create the updateMask for the fields being updated
    String updateMask = updatedFields.keys.map((field) => 'updateMask.fieldPaths=$field').join('&');

    // Construct the Firestore REST API URL for updating the document
    final url = 'https://firestore.googleapis.com/v1/$documentName?key=$apiKey&$updateMask';

    // Send the PATCH request to Firestore
    final response = await http.patch(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $idToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'fields': updatedFields,
      }),
    );
    Map<String, dynamic> profileData = {
      'householdHead': _encodeField(''), // Initialize as empty string
      'occupation': _encodeField(''), // Initialize as empty string
      'emergencyContacts': _encodeField(<String>[]), // Empty array
      'members': _encodeField(<Map<String, dynamic>>[]), // Empty array
      'moveInDate': _encodeField(''), // Initialize as empty string
      'moveOutDate': _encodeField(''), // Initialize as empty string
      'vehicles': _encodeField(<Map<String, dynamic>>[]), // Empty array
      'utilities': _encodeField(<String>[]), // Empty array
    };

    final profileUrl = 'https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents/profiles/$profileId?key=$apiKey';

    final profileResponse = await http.patch(
      Uri.parse(profileUrl),
      headers: {
        'Authorization': 'Bearer $idToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'fields': profileData,
      }),
    );

    if (profileResponse.statusCode != 200) {
      throw Exception('Lỗi khi tạo profile: ${profileResponse.statusCode} ${profileResponse.body}');
    }
    if (response.statusCode == 200) {
      // Update successful
      return;
    } else {
      throw Exception('Lỗi khi cập nhật cư dân: ${response.statusCode} ${response.body}');
    }
  }

  // Hàm xóa cư dân và profile tương ứng
  Future<void> deleteResident({
    required String documentName, // Full path of the resident document
    required String idToken,
  }) async {
    // Step 1: Fetch the resident document to get profileId
    final fetchUrl = 'https://firestore.googleapis.com/v1/$documentName?key=$apiKey';

    final fetchResponse = await http.get(
      Uri.parse(fetchUrl),
      headers: {
        'Authorization': 'Bearer $idToken',
        'Content-Type': 'application/json',
      },
    );

    if (fetchResponse.statusCode != 200) {
      throw Exception('Lỗi khi lấy thông tin cư dân để xóa: ${fetchResponse.statusCode} ${fetchResponse.body}');
    }

    final fetchData = jsonDecode(fetchResponse.body);
    if (fetchData == null || !fetchData.containsKey('fields') || !fetchData['fields'].containsKey('profileId')) {
      throw Exception('Không tìm thấy profileId trong tài liệu cư dân.');
    }

    String profileId = fetchData['fields']['profileId']['stringValue'];

    // Step 2: Delete the profile document in 'profiles' collection
    final deleteProfileUrl = 'https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents/profiles/$profileId?key=$apiKey';

    final deleteProfileResponse = await http.delete(
      Uri.parse(deleteProfileUrl),
      headers: {
        'Authorization': 'Bearer $idToken',
        'Content-Type': 'application/json',
      },
    );

    if (deleteProfileResponse.statusCode != 200 && deleteProfileResponse.statusCode != 204) {
      throw Exception('Lỗi khi xóa profile: ${deleteProfileResponse.statusCode} ${deleteProfileResponse.body}');
    }

    // Step 3: Delete the resident document
    final deleteResidentUrl = 'https://firestore.googleapis.com/v1/$documentName?key=$apiKey';

    final deleteResidentResponse = await http.delete(
      Uri.parse(deleteResidentUrl),
      headers: {
        'Authorization': 'Bearer $idToken',
        'Content-Type': 'application/json',
      },
    );

    if (deleteResidentResponse.statusCode != 200 && deleteResidentResponse.statusCode != 204) {
      throw Exception('Lỗi khi xóa cư dân: ${deleteResidentResponse.statusCode} ${deleteResidentResponse.body}');
    }
  }

  // Helper function để mã hóa trường dữ liệu
  Map<String, dynamic> _encodeField(dynamic value) {
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
          'values': value.map((item) => _encodeField(item)).toList(),
        }
      };
    } else if (value is Map) {
      return {
        'mapValue': {
          'fields': value.map((k, v) => MapEntry(k, _encodeField(v))),
        }
      };
    } else {
      return {};
    }
  }
}
