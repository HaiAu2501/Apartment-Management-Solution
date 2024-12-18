import '../domain/r_complaints.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ComplaintsRepository {
  final String apiKey;
  final String projectId;

  ComplaintsRepository({required this.apiKey, required this.projectId});

  /// Tạo đường dẫn tài liệu Firestore cho một complaint cụ thể
  String getDocumentPath(String documentId) {
    return 'projects/$projectId/databases/(default)/documents/complaints/$documentId';
  }

  /// Lấy tất cả complaints với phân trang
  Future<List<dynamic>> fetchAllComplaints(String idToken) async {
    List<dynamic> allDocuments = [];
    String? nextPageToken;
    const int pageSize = 100; // Firestore REST API có giới hạn pageSize là 100

    do {
      // Tạo URL với phân trang và sắp xếp theo ngày
      String url =
          'https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents/complaints?key=$apiKey&pageSize=$pageSize&orderBy=date';

      if (nextPageToken != null && nextPageToken.isNotEmpty) {
        url += '&pageToken=$nextPageToken';
      }

      try {
       
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
          throw Exception(
              'Error fetching complaints: ${response.statusCode} ${response.body}');
        }
      } catch (e) {
        print('Exception in fetchAllComplaints: $e');
        rethrow;
      }
    } while (nextPageToken != null);

    return allDocuments;
  }

  /// Lấy một complaint cụ thể bằng tên tài liệu
  Future<Map<String, dynamic>> fetchComplaintByName(
      String documentName, String idToken) async {
    final url = 'https://firestore.googleapis.com/v1/$documentName?key=$apiKey';

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $idToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        throw Exception(
            'Error fetching complaint: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      print('Exception in fetchComplaintByName: $e');
      rethrow;
    }
  }

  // lay ten user
    Future<Map<String,dynamic>> getUserData(
      String documentId, String idToken) async {
    final url = 'https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents/residents/$documentId?key=$apiKey';

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $idToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        throw Exception(
            'Error fetching complaint: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      print('Exception in getUserName: $e');
     
      rethrow;
    }
  }
  /// Thêm một complaint mới
  Future<void> addComplaint(Map<String, dynamic> complaintData, String idToken,
      Complaint newComplaint) async {
    final url =
        'https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents/complaints?key=$apiKey';

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $idToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'fields': complaintData
              .map((key, value) => MapEntry(key, _encodeField(value))),
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        final documentId = responseData['name'].split('/').last;

        print('Complaint added successfully. Document ID: $documentId');
        newComplaint.id='projects/apartment-management-solution/databases/(default)/documents/complaints/$documentId';
      } else {
        throw Exception(
            'Error adding complaint: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      print('Exception in addComplaint: $e');
      rethrow;
    }
  }

Future<void> updateComplaint(String documentId, Map<String, dynamic> updatedData, String idToken) async {
 
  String updateMask = updatedData.keys.map((field) => 'updateMask.fieldPaths=$field').join('&');

  final url = 'https://firestore.googleapis.com/v1/$documentId?key=$apiKey&$updateMask';

  try {
    print('Sending PATCH request to $url with data: ');
    final response = await http.patch(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $idToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'fields': updatedData.map((key, value) => MapEntry(key, value)),
      }),
    );

    if (response.statusCode == 200) {
      print('Complaint updated successfully.');
    } else {
      print('Failed to update complaint with status code: ${response.statusCode} and body: ${response.body}');
      throw Exception('Error updating complaint: ${response.statusCode} ${response.body}');
    }
  } catch (e) {
    print('Exception in updateComplaint: $e');
    rethrow;
  }
}





  /// Xóa một complaint
  Future<void> deleteComplaint(String documentPath, String idToken) async {
    final url = 'https://firestore.googleapis.com/v1/$documentPath?key=$apiKey';

    try {
      final response = await http.delete(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $idToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        print('Complaint deleted successfully.');
      } else {
        throw Exception(
            'Error deleting complaint: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      print('Exception in deleteComplaint: $e');
      rethrow;
    }
  }

  /// Helper function để mã hóa trường dữ liệu cho Firestore
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
    } else if (value is DateTime) {
      return {
        'timestampValue': value.toUtc().toIso8601String(),
      };
    } else {
      return {};
    }
  }
}
