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
    // Encode fields correctly
    final encodedFeeData = _encodeFields(feeData);

    // Build the URL for 'fees' collection
    final feesUri = Uri.https(
      'firestore.googleapis.com',
      '/v1/projects/$projectId/databases/(default)/documents/fees',
      {'key': apiKey},
    );

    // Create a new document in 'fees' collection
    final feesResponse = await http.post(
      feesUri,
      headers: {
        'Authorization': 'Bearer $idToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'fields': encodedFeeData,
      }),
    );

    if (feesResponse.statusCode != 200) {
      throw Exception('Failed to add fee: ${feesResponse.body}');
    }

    // Parse the response to get the 'fees' document path
    final feesData = jsonDecode(feesResponse.body);
    final String feesDocumentPath = feesData['name'];

    // Sau khi thêm khoản phí vào collection 'fees', tạo thêm tài liệu trong 'fees-table' hoặc 'donations-table'
    final feeName = feeData['name'] as String? ?? 'UnknownFeeName';
    final bool commonFee = feeData['commonFee'] as bool? ?? false;

    // Xác định collection đích
    final String targetCollection = commonFee ? 'fees-table' : 'donations-table';

    // Khởi tạo dữ liệu cho collection đích
    final Map<String, dynamic> targetData = {
      'name': feeName,
      ..._initializeFloors(), // Thêm các trường "Tầng 01" đến "Tầng 50"
    };

    // Encode fields cho collection đích
    final encodedTargetData = _encodeFields(targetData);

    // Tạo URL cho collection đích để Firestore tự sinh documentId
    final targetUri = Uri.https(
      'firestore.googleapis.com',
      '/v1/projects/$projectId/databases/(default)/documents/$targetCollection',
      {'key': apiKey},
    );

    // Thêm tài liệu vào collection đích với documentId tự sinh
    final targetResponse = await http.post(
      targetUri,
      headers: {
        'Authorization': 'Bearer $idToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'fields': encodedTargetData,
      }),
    );

    if (targetResponse.statusCode != 200) {
      throw Exception('Failed to create document in $targetCollection: ${targetResponse.body}');
    }

    // Parse the response to get the table document path
    final targetDataResponse = jsonDecode(targetResponse.body);
    final String tableDocumentPath = targetDataResponse['name'];

    // Extract documentId from tableDocumentPath
    // Document path format: projects/{projectId}/databases/(default)/documents/{collection}/{documentId}
    final tableDocumentId = tableDocumentPath.split('/').last;

    // Now, update the 'fees' document with 'tableId' without affecting other fields
    // **Important:** Use 'updateMask.fieldPaths=tableId' as a query parameter
    final updateUri = Uri.https(
      'firestore.googleapis.com',
      '/v1/$feesDocumentPath',
      {
        'key': apiKey,
        'updateMask.fieldPaths': 'tableId',
      },
    );

    // Prepare the body for update: set 'tableId' field
    final updateBody = jsonEncode({
      'fields': {
        'tableId': {'stringValue': tableDocumentId},
      },
    });

    final updateResponse = await http.patch(
      updateUri,
      headers: {
        'Authorization': 'Bearer $idToken',
        'Content-Type': 'application/json',
      },
      body: updateBody,
    );

    if (updateResponse.statusCode != 200) {
      throw Exception('Failed to update fee with tableId: ${updateResponse.body}');
    }
  }

  // Update an existing fee
  Future<void> updateFee(String documentPath, Map<String, dynamic> feeData, String idToken) async {
    // Define the fields to update
    final List<String> fieldsToUpdate = ['name', 'description', 'amount', 'frequency', 'commonFee', 'dueDate'];

    // Encode fields correctly
    final encodedFeeData = _encodeFields(feeData);

    // Manually build the query string with multiple updateMask.fieldPaths
    // Firestore REST API expects multiple 'updateMask.fieldPaths' parameters
    // Example: updateMask.fieldPaths=name&updateMask.fieldPaths=description&...
    final Uri baseUri = Uri.https(
      'firestore.googleapis.com',
      '/v1/$documentPath',
      {
        'key': apiKey,
      },
    );

    // Build the final URI with multiple 'updateMask.fieldPaths'
    String queryParameters = fieldsToUpdate.map((field) => 'updateMask.fieldPaths=$field').join('&');
    final String finalUriString = '${baseUri.toString()}&$queryParameters';
    final Uri finalUri = Uri.parse(finalUriString);

    // Send the PATCH request to update the 'fees' document
    final response = await http.patch(
      finalUri,
      headers: {
        'Authorization': 'Bearer $idToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'fields': encodedFeeData,
      }),
    );

    // **Debug:** Print response for verification
    print('Update Response Status: ${response.statusCode}');
    print('Update Response Body: ${response.body}');

    if (response.statusCode != 200) {
      throw Exception('Failed to update fee: ${response.body}');
    }

    // Sau khi cập nhật 'fees' document, cần cập nhật trường 'name' trong tài liệu tương ứng ở 'fees-table' hoặc 'donations-table'
    // Để làm được điều này, chúng ta cần:
    // 1. Fetch 'tableId' từ 'fees' document
    // 2. Xác định collection đích dựa trên 'commonFee'
    // 3. Update trường 'name' trong tài liệu đích

    // Fetch the updated 'fees' document to get 'tableId' and 'commonFee'
    final updatedFee = await fetchFeeByPath(documentPath, idToken);

    if (!updatedFee.containsKey('fields')) {
      throw Exception('Updated fee data is invalid.');
    }

    final fields = updatedFee['fields'];

    final String? tableId = fields['tableId']?['stringValue'];
    final bool commonFee = fields['commonFee']?['booleanValue'] ?? false;

    if (tableId == null || tableId.isEmpty) {
      throw Exception('tableId is missing in the updated fee document.');
    }

    // Determine the target collection
    final String targetCollection = commonFee ? 'fees-table' : 'donations-table';

    // Build the table document path
    final String tableDocumentPath = 'projects/$projectId/databases/(default)/documents/$targetCollection/$tableId';

    // Prepare the update for 'name' field in table document
    // **Important:** Use 'updateMask.fieldPaths=name' as a query parameter
    final Uri tableUpdateUri = Uri.https(
      'firestore.googleapis.com',
      '/v1/$tableDocumentPath',
      {
        'key': apiKey,
        'updateMask.fieldPaths': 'name',
      },
    );

    final String newName = feeData['name'] as String? ?? 'UnknownFeeName';

    final String updateTableBody = jsonEncode({
      'fields': {
        'name': {'stringValue': newName},
      },
    });

    // Update the 'name' field in table document
    final tableUpdateResponse = await http.patch(
      tableUpdateUri,
      headers: {
        'Authorization': 'Bearer $idToken',
        'Content-Type': 'application/json',
      },
      body: updateTableBody,
    );

    if (tableUpdateResponse.statusCode != 200) {
      throw Exception('Failed to update name in $targetCollection: ${tableUpdateResponse.body}');
    }
  }

  // Delete a fee
  Future<void> deleteFee(String documentPath, String idToken) async {
    // Fetch the fee document to get 'tableId' and 'commonFee'
    final fee = await fetchFeeByPath(documentPath, idToken);

    if (!fee.containsKey('fields')) {
      throw Exception('Fee data is invalid.');
    }

    final fields = fee['fields'];
    final String? tableId = fields['tableId']?['stringValue'];
    final bool commonFee = fields['commonFee']?['booleanValue'] ?? false;

    // Delete the fee document
    final uri = Uri.https(
      'firestore.googleapis.com',
      '/v1/$documentPath',
      {'key': apiKey},
    );

    final response = await http.delete(
      uri,
      headers: {
        'Authorization': 'Bearer $idToken',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete fee: ${response.body}');
    }

    // Delete the corresponding table document
    if (tableId != null && tableId.isNotEmpty) {
      final String targetCollection = commonFee ? 'fees-table' : 'donations-table';
      final String tableDocumentPath = 'projects/$projectId/databases/(default)/documents/$targetCollection/$tableId';

      final Uri tableDeleteUri = Uri.https(
        'firestore.googleapis.com',
        '/v1/$tableDocumentPath',
        {'key': apiKey},
      );

      final tableDeleteResponse = await http.delete(
        tableDeleteUri,
        headers: {
          'Authorization': 'Bearer $idToken',
          'Content-Type': 'application/json',
        },
      );

      if (tableDeleteResponse.statusCode != 200) {
        throw Exception('Failed to delete document in $targetCollection: ${tableDeleteResponse.body}');
      }
    }
  }

  // Helper to encode fields to Firestore format
  Map<String, dynamic> _encodeFields(Map<String, dynamic> data) {
    final encoded = <String, dynamic>{};
    data.forEach((key, value) {
      encoded[key] = _encodeFieldValue(value);
    });
    return encoded;
  }

  dynamic _encodeFieldValue(dynamic value) {
    if (value is Map<String, dynamic>) {
      final encodedMap = <String, dynamic>{};
      value.forEach((k, v) {
        encodedMap[k] = _encodeFieldValue(v);
      });
      return {
        'mapValue': {'fields': encodedMap}
      };
    } else if (value is List) {
      final encodedList = value.map((item) => _encodeFieldValue(item)).toList();
      return {
        'arrayValue': {'values': encodedList}
      };
    } else if (value is String) {
      return {'stringValue': value};
    } else if (value is int) {
      return {'integerValue': value.toString()};
    } else if (value is double) {
      return {'doubleValue': value};
    } else if (value is bool) {
      return {'booleanValue': value};
    } else if (value is DateTime) {
      // Firestore expects timestampValue in RFC 3339 UTC "Zulu" format
      return {'timestampValue': value.toUtc().toIso8601String()};
    } else if (value == null) {
      return {'nullValue': null};
    } else {
      throw Exception('Unsupported data type: ${value.runtimeType}');
    }
  }

  // Helper to initialize floors with 50 maps, each map has 21 elements:
  // - Phần tử đầu tiên là null
  // - Các phần tử từ 1 đến 20 là maps với 'Số tiền đóng' và 'Ngày đóng'
  Map<String, dynamic> _initializeFloors() {
    Map<String, dynamic> floors = {};
    for (int i = 1; i <= 50; i++) {
      String floorName = 'Tầng ${i.toString().padLeft(2, '0')}'; // Đổi tên thành 'Tầng 01', 'Tầng 02', ...
      List<dynamic> rooms = [];
      rooms.add(null); // Phần tử đầu tiên là null
      for (int j = 1; j <= 20; j++) {
        rooms.add({
          'Số tiền đóng': 0, // Khởi tạo giá trị là 0
          'Ngày đóng': null, // Khởi tạo giá trị là null
          'Người đóng': null, // Khởi tạo giá trị là null
        });
      }
      floors[floorName] = rooms;
    }
    return floors;
  }

  // **Bổ Sung Các Hàm Mới Cho Thống Kê**

  /// Lấy số lượng khoản phí theo tần suất
  Future<Map<String, int>> getFeeFrequencies(String idToken) async {
    List<dynamic> fees = await fetchAllFees(idToken);
    Map<String, int> frequencies = {
      'Hàng tuần': 0,
      'Hàng tháng': 0,
      'Hàng quý': 0,
      'Hàng năm': 0,
      'Một lần': 0,
      'Không bắt buộc': 0,
      'Khác': 0,
    };

    for (var fee in fees) {
      var fields = fee['fields'] ?? {};
      String frequency = fields['frequency']?['stringValue']?.toString() ?? 'Khác';

      if (frequencies.containsKey(frequency)) {
        frequencies[frequency] = frequencies[frequency]! + 1;
      } else {
        frequencies['Khác'] = frequencies['Khác']! + 1;
      }
    }

    return frequencies;
  }

  /// Lấy số ngày còn lại đến hạn khoản phí gần nhất
  Future<int> getNearestFeeDueDays(String idToken) async {
    List<dynamic> fees = await fetchAllFees(idToken);
    DateTime now = DateTime.now();
    DateTime? nearestDueDate;

    for (var fee in fees) {
      var fields = fee['fields'] ?? {};
      String dueDateStr = fields['dueDate']?['timestampValue']?.toString() ?? '';

      if (dueDateStr.isEmpty) continue;

      DateTime dueDate;
      try {
        dueDate = DateTime.parse(dueDateStr);
      } catch (e) {
        // Nếu định dạng ngày không hợp lệ, bỏ qua
        continue;
      }

      if (dueDate.isAfter(now)) {
        if (nearestDueDate == null || dueDate.isBefore(nearestDueDate)) {
          nearestDueDate = dueDate;
        }
      }
    }

    if (nearestDueDate != null) {
      return nearestDueDate.difference(now).inDays;
    } else {
      return -1; // -1 nghĩa là không có khoản phí nào sắp đến hạn
    }
  }
}
