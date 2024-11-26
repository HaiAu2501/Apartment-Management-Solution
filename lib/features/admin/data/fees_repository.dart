// lib/features/admin/data/fees_repository.dart

import 'dart:convert';
import 'package:http/http.dart' as http;

class FeesRepository {
  final String apiKey;
  final String projectId;

  FeesRepository({
    required this.apiKey,
    required this.projectId,
  });

  // Fetch all fees with pagination
  Future<List<dynamic>> fetchAllFees(String idToken) async {
    List<dynamic> allDocuments = [];
    String? nextPageToken;
    const int pageSize = 100; // Firestore REST API has a maximum pageSize of 100

    do {
      // Create URL with pagination parameters
      String url = 'https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents/fees?key=$apiKey&pageSize=$pageSize';

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
        throw Exception('Lỗi khi tải fees: ${response.statusCode} ${response.body}');
      }
    } while (nextPageToken != null);

    return allDocuments;
  }

  // Fetch fee by document path
  Future<Map<String, dynamic>> fetchFeeByPath(String documentPath, String idToken) async {
    final url = 'https://firestore.googleapis.com/v1/$documentPath?key=$apiKey';

    final response = await http.get(Uri.parse(url), headers: {
      'Authorization': 'Bearer $idToken',
      'Content-Type': 'application/json',
    });

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data;
    } else {
      throw Exception('Failed to fetch fee: ${response.body}');
    }
  }

  // Add a new fee
  Future<void> addFee(Map<String, dynamic> feeData, String idToken) async {
    final url = 'https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents/fees?key=$apiKey';

    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $idToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'fields': _encodeFields(feeData),
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to add fee: ${response.body}');
    }
  }

  // Update an existing fee
  Future<void> updateFee(String documentPath, Map<String, dynamic> feeData, String idToken) async {
    // Define the fields to update
    final List<String> fieldsToUpdate = ['name', 'description', 'amount', 'frequency', 'commonFee', 'dueDate'];

    // Create the query string for each fieldPath
    String updateMask = fieldsToUpdate.map((field) => 'updateMask.fieldPaths=$field').join('&');

    // Construct the full URL with individual fieldPaths
    String url = 'https://firestore.googleapis.com/v1/$documentPath?$updateMask&key=$apiKey';

    // **Debug:** Print URL and payload for verification
    print('Update URL: $url');
    print('Payload: ${jsonEncode({
          'fields': _encodeFields(feeData),
        })}');

    final response = await http.patch(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $idToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'fields': _encodeFields(feeData),
      }),
    );

    // **Debug:** Print response for verification
    print('Response Status: ${response.statusCode}');
    print('Response Body: ${response.body}');

    if (response.statusCode != 200) {
      throw Exception('Failed to update fee: ${response.body}');
    }
  }

  // Delete a fee
  Future<void> deleteFee(String documentPath, String idToken) async {
    final url = 'https://firestore.googleapis.com/v1/$documentPath?key=$apiKey';

    final response = await http.delete(Uri.parse(url), headers: {
      'Authorization': 'Bearer $idToken',
      'Content-Type': 'application/json',
    });

    if (response.statusCode != 200) {
      throw Exception('Failed to delete fee: ${response.body}');
    }
  }

  // Helper to encode fields to Firestore format
  Map<String, dynamic> _encodeFields(Map<String, dynamic> data) {
    final encoded = <String, dynamic>{};
    data.forEach((key, value) {
      if (value is String) {
        encoded[key] = {'stringValue': value};
      } else if (value is int) {
        encoded[key] = {'integerValue': value.toString()};
      } else if (value is double) {
        encoded[key] = {'doubleValue': value};
      } else if (value is bool) {
        encoded[key] = {'booleanValue': value};
      } else if (value is DateTime) {
        // Firestore expects timestampValue in RFC 3339 UTC "Zulu" format
        encoded[key] = {'timestampValue': value.toUtc().toIso8601String()};
      } else {
        // Handle other types as needed
        encoded[key] = {};
      }
    });
    return encoded;
  }
}
