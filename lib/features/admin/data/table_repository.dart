import 'dart:convert';
import 'dart:io'; // <-- cần cho File() trên desktop
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

/// Model class for each room
class RoomData {
  final int roomNumber;
  final int paidAmount;
  final String paymentDate;
  final String payer;

  RoomData({
    required this.roomNumber,
    required this.paidAmount,
    required this.paymentDate,
    required this.payer,
  });
}

class TableRepository {
  final String apiKey;
  final String projectId;

  TableRepository({
    required this.apiKey,
    required this.projectId,
  });

  // ---------------------------------------------------------------------
  // 1) Lấy danh sách tên phí
  // ---------------------------------------------------------------------
  Future<List<String>> getFeeNames(String collection, String idToken) async {
    final url = 'https://firestore.googleapis.com/v1/projects/$projectId'
        '/databases/(default)/documents/$collection?key=$apiKey';

    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $idToken',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final docs = data['documents'] ?? [];
      return docs.map<String>((doc) => doc['fields']['name']['stringValue'] as String).toList();
    } else {
      throw Exception('Failed to fetch fee names: '
          '${response.statusCode} ${response.body}');
    }
  }

  // ---------------------------------------------------------------------
  // 2) Lấy dữ liệu phòng cho 1 tầng
  // ---------------------------------------------------------------------
  Future<List<RoomData>> getFloorData(
    String collection,
    String feeName,
    int floorNumber,
    String idToken,
  ) async {
    final floorName = 'Tầng ${floorNumber.toString().padLeft(2, '0')}';
    final floorPath = '`$floorName`'; // backtick

    // Query document
    final queryUrl = 'https://firestore.googleapis.com/v1/projects/$projectId'
        '/databases/(default)/documents:runQuery?key=$apiKey';

    final queryBody = {
      "structuredQuery": {
        "from": [
          {"collectionId": collection}
        ],
        "where": {
          "fieldFilter": {
            "field": {"fieldPath": "name"},
            "op": "EQUAL",
            "value": {"stringValue": feeName}
          }
        },
        "select": {
          // chỉ lấy fieldPath = `Tầng xx`
          "fields": [
            {"fieldPath": floorPath}
          ]
        }
      }
    };

    final res = await http.post(
      Uri.parse(queryUrl),
      headers: {
        'Authorization': 'Bearer $idToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(queryBody),
    );

    if (res.statusCode != 200) {
      throw Exception('Failed to fetch floor data: '
          '${res.statusCode} ${res.body}');
    }

    final results = jsonDecode(res.body);
    if (results is List && results.isNotEmpty && results[0]['document'] != null) {
      final doc = results[0]['document'];
      final fields = doc['fields'] ?? {};
      final floorData = fields[floorName]?['arrayValue']?['values'] ?? [];

      // Tạo 20 phòng
      return List<RoomData>.generate(20, (i) {
        final idx = i + 1;
        final room = (idx < floorData.length) ? floorData[idx] : null;
        final rf = room?['mapValue']?['fields'] ?? {};

        return RoomData(
          roomNumber: i + 1,
          paidAmount: int.tryParse(rf['Số tiền đóng']?['integerValue'] ?? '0') ?? 0,
          paymentDate: rf['Ngày đóng']?['timestampValue'] != null ? _formatDate(DateTime.parse(rf['Ngày đóng']['timestampValue'])) : 'Chưa đóng',
          payer: rf['Người đóng']?['stringValue'] ?? 'Không có',
        );
      });
    } else {
      // doc rỗng => trả 20 phòng default
      return List<RoomData>.generate(20, (i) {
        return RoomData(
          roomNumber: i + 1,
          paidAmount: 0,
          paymentDate: 'Chưa đóng',
          payer: 'Không có',
        );
      });
    }
  }

  // ---------------------------------------------------------------------
  // 3) Update 1 phòng
  // ---------------------------------------------------------------------
  Future<void> updateRoomData(
    String collection,
    String feeName,
    int floorNumber,
    int roomNumber,
    int paidAmount,
    DateTime? paymentDate,
    String? payer,
    String idToken,
  ) async {
    final floorName = 'Tầng ${floorNumber.toString().padLeft(2, '0')}';
    final floorPath = '`$floorName`';

    // 1) Tìm doc
    final queryUrl = 'https://firestore.googleapis.com/v1/projects/$projectId'
        '/databases/(default)/documents:runQuery?key=$apiKey';

    final queryBody = {
      "structuredQuery": {
        "from": [
          {"collectionId": collection}
        ],
        "where": {
          "fieldFilter": {
            "field": {"fieldPath": "name"},
            "op": "EQUAL",
            "value": {"stringValue": feeName}
          }
        }
      }
    };

    final queryRes = await http.post(
      Uri.parse(queryUrl),
      headers: {
        'Authorization': 'Bearer $idToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(queryBody),
    );

    if (queryRes.statusCode != 200) {
      throw Exception('Failed to run query: '
          '${queryRes.statusCode} ${queryRes.body}');
    }

    final queryJson = jsonDecode(queryRes.body);
    if (queryJson is List && queryJson.isNotEmpty && queryJson[0]['document'] != null) {
      final docPath = queryJson[0]['document']['name'];

      // 2) Lấy doc cũ
      final getUrl = 'https://firestore.googleapis.com/v1/$docPath?key=$apiKey';
      final getRes = await http.get(
        Uri.parse(getUrl),
        headers: {
          'Authorization': 'Bearer $idToken',
          'Content-Type': 'application/json',
        },
      );
      if (getRes.statusCode != 200) {
        throw Exception('Failed to fetch document: '
            '${getRes.statusCode} ${getRes.body}');
      }

      final docJson = jsonDecode(getRes.body);
      final fields = docJson['fields'] ?? {};
      final floorArray = (fields[floorName]?['arrayValue']?['values'] ?? []).cast<dynamic>();

      // 3) Update
      if (floorArray.length > roomNumber && floorArray[roomNumber] != null) {
        final rf = floorArray[roomNumber]['mapValue']['fields'];
        rf['Số tiền đóng'] = {'integerValue': paidAmount.toString()};
        rf['Ngày đóng'] = (paymentDate != null) ? {'timestampValue': paymentDate.toUtc().toIso8601String()} : {'nullValue': null};
        rf['Người đóng'] = (payer != null) ? {'stringValue': payer} : {'nullValue': null};
      } else {
        // thêm
        while (floorArray.length <= roomNumber) {
          floorArray.add(null);
        }
        floorArray[roomNumber] = {
          'mapValue': {
            'fields': {
              'Số tiền đóng': {'integerValue': paidAmount.toString()},
              'Ngày đóng': (paymentDate != null) ? {'timestampValue': paymentDate.toUtc().toIso8601String()} : {'nullValue': null},
              'Người đóng': (payer != null) ? {'stringValue': payer} : {'nullValue': null},
            }
          }
        };
      }

      // 4) PATCH (updateMask qua query param)
      final encodedPath = Uri.encodeQueryComponent(floorPath);
      final patchUrl = 'https://firestore.googleapis.com/v1/$docPath'
          '?updateMask.fieldPaths=$encodedPath'
          '&key=$apiKey';

      final patchBody = jsonEncode({
        "fields": {
          floorName: {
            "arrayValue": {"values": floorArray}
          }
        }
      });

      final patchRes = await http.patch(
        Uri.parse(patchUrl),
        headers: {
          'Authorization': 'Bearer $idToken',
          'Content-Type': 'application/json',
        },
        body: patchBody,
      );

      if (patchRes.statusCode != 200) {
        throw Exception('Failed to update room data: ${patchRes.body}');
      }
    } else {
      throw Exception("Document with name=$feeName not found.");
    }
  }

  // ---------------------------------------------------------------------
  // 4) Update nhiều phòng (CSV, ...)
  // ---------------------------------------------------------------------
  Future<void> updateRoomsData(
    String collection,
    String feeName,
    int floorNumber,
    List<RoomData> roomList,
    String idToken,
  ) async {
    final floorName = 'Tầng ${floorNumber.toString().padLeft(2, '0')}';
    final floorPath = '`$floorName`';

    // 1) Tìm doc
    final queryUrl = 'https://firestore.googleapis.com/v1/projects/$projectId'
        '/databases/(default)/documents:runQuery?key=$apiKey';

    final queryBody = {
      "structuredQuery": {
        "from": [
          {"collectionId": collection}
        ],
        "where": {
          "fieldFilter": {
            "field": {"fieldPath": "name"},
            "op": "EQUAL",
            "value": {"stringValue": feeName}
          }
        }
      }
    };

    final queryRes = await http.post(
      Uri.parse(queryUrl),
      headers: {
        'Authorization': 'Bearer $idToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(queryBody),
    );
    if (queryRes.statusCode != 200) {
      throw Exception('Failed to run query: '
          '${queryRes.statusCode} ${queryRes.body}');
    }

    final queryJson = jsonDecode(queryRes.body);
    if (queryJson is List && queryJson.isNotEmpty && queryJson[0]['document'] != null) {
      final docPath = queryJson[0]['document']['name'];

      // 2) Lấy doc cũ
      final getUrl = 'https://firestore.googleapis.com/v1/$docPath?key=$apiKey';
      final getRes = await http.get(
        Uri.parse(getUrl),
        headers: {
          'Authorization': 'Bearer $idToken',
          'Content-Type': 'application/json',
        },
      );
      if (getRes.statusCode != 200) {
        throw Exception('Failed to fetch document: '
            '${getRes.statusCode} ${getRes.body}');
      }

      final docJson = jsonDecode(getRes.body);
      final fields = docJson['fields'] ?? {};
      final floorArray = (fields[floorName]?['arrayValue']?['values'] ?? []).cast<dynamic>();

      // 3) Tạo mảng 21 phần tử
      final newFloorArray = List<dynamic>.generate(21, (_) => null);
      for (int i = 0; i < floorArray.length; i++) {
        if (i < newFloorArray.length) {
          newFloorArray[i] = floorArray[i];
        }
      }

      // Duyệt roomList, ghép vào newFloorArray
      for (final rd in roomList) {
        if (rd.roomNumber < 1 || rd.roomNumber >= newFloorArray.length) {
          continue;
        }
        var isoStamp = '';
        if (rd.paymentDate != 'Chưa đóng') {
          isoStamp = _parseAndToIso(rd.paymentDate);
        }
        newFloorArray[rd.roomNumber] = {
          'mapValue': {
            'fields': {
              'Số tiền đóng': {'integerValue': rd.paidAmount.toString()},
              'Ngày đóng': isoStamp.isNotEmpty ? {'timestampValue': isoStamp} : {'nullValue': null},
              'Người đóng': (rd.payer != 'Không có') ? {'stringValue': rd.payer} : {'nullValue': null},
            }
          }
        };
      }

      // 4) PATCH (updateMask qua query param)
      final encodedPath = Uri.encodeQueryComponent(floorPath);
      final patchUrl = 'https://firestore.googleapis.com/v1/$docPath'
          '?updateMask.fieldPaths=$encodedPath'
          '&key=$apiKey';

      final patchBody = jsonEncode({
        "fields": {
          floorName: {
            "arrayValue": {"values": newFloorArray}
          }
        }
      });

      final patchRes = await http.patch(
        Uri.parse(patchUrl),
        headers: {
          'Authorization': 'Bearer $idToken',
          'Content-Type': 'application/json',
        },
        body: patchBody,
      );

      if (patchRes.statusCode != 200) {
        throw Exception('Failed to bulk update: ${patchRes.body}');
      }
    } else {
      throw Exception("Document with name=$feeName not found.");
    }
  }

  // ---------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------
  /// Format DateTime => dd/MM/yyyy
  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  /// Parse "dd/MM/yy" hoặc "dd/MM/yyyy" => DateTime => ISO8601
  String _parseAndToIso(String dateStr) {
    try {
      final parts = dateStr.split('/');
      if (parts.length == 3) {
        final day = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        var year = int.parse(parts[2]);
        // Nếu year < 100 => +2000
        if (year < 100) {
          year += 2000;
        }
        final dt = DateTime(year, month, day);
        return dt.toUtc().toIso8601String();
      }
    } catch (_) {
      // ignore
    }
    // fallback
    return DateTime.now().toUtc().toIso8601String();
  }
}
