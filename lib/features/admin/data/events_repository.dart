// lib/features/events/data/events_repository.dart

import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../.authentication/data/auth_service.dart';

class EventsRepository {
  final String apiKey;
  final String projectId;

  EventsRepository({required this.apiKey, required this.projectId});

  /// Tạo đường dẫn tài liệu Firestore cho một sự kiện cụ thể
  String getDocumentPath(String documentId) {
    return 'projects/$projectId/databases/(default)/documents/events/$documentId';
  }

  /// Lấy tất cả các sự kiện với phân trang
  Future<List<dynamic>> fetchAllEvents(String idToken) async {
    List<dynamic> allDocuments = [];
    String? nextPageToken;
    const int pageSize = 100; // Firestore REST API có giới hạn pageSize là 100

    do {
      // Tạo URL với phân trang và sắp xếp theo ngày
      String url = 'https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents/events?key=$apiKey&pageSize=$pageSize&orderBy=date';

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
          throw Exception('Error fetching events: ${response.statusCode} ${response.body}');
        }
      } catch (e) {
        print('Exception in fetchAllEvents: $e');
        rethrow;
      }
    } while (nextPageToken != null);

    return allDocuments;
  }

  /// Lấy một sự kiện cụ thể bằng tên tài liệu
  Future<Map<String, dynamic>> fetchEventByName(String documentName, String idToken) async {
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
        throw Exception('Error fetching event: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      print('Exception in fetchEventByName: $e');
      rethrow;
    }
  }

  /// Thêm một sự kiện mới
  Future<void> addEvent(Map<String, dynamic> eventData, String idToken) async {
    final url = 'https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents/events?key=$apiKey';

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $idToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'fields': eventData.map((key, value) => MapEntry(key, _encodeField(value))),
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('Event added successfully.');
      } else {
        throw Exception('Error adding event: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      print('Exception in addEvent: $e');
      rethrow;
    }
  }

  /// Cập nhật một sự kiện hiện có
  Future<void> updateEvent(String documentPath, Map<String, dynamic> updatedData, String idToken) async {
    // Tạo updateMask.fieldPaths
    List<String> fieldPaths = updatedData.keys.toList();
    String updateMask = fieldPaths.map((field) => 'updateMask.fieldPaths=$field').join('&');

    final url = 'https://firestore.googleapis.com/v1/$documentPath?key=$apiKey&$updateMask';

    try {
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

      if (response.statusCode == 200) {
        print('Event updated successfully.');
      } else {
        throw Exception('Error updating event: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      print('Exception in updateEvent: $e');
      rethrow;
    }
  }

  /// Xóa một sự kiện
  Future<void> deleteEvent(String documentPath, String idToken) async {
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
        print('Event deleted successfully.');
      } else {
        throw Exception('Error deleting event: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      print('Exception in deleteEvent: $e');
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
