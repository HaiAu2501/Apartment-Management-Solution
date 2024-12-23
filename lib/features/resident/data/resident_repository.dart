// lib/resident/data/resident_repository.dart

import 'package:http/http.dart' as http;
import 'dart:convert';

class ResidentRepository {
  final String apiKey;
  final String projectId;

  ResidentRepository({required this.apiKey, required this.projectId});

  /// Fetches the resident document for the authenticated user.
  Future<Map<String, dynamic>> fetchResident(String uid, String idToken) async {
    final url = 'https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents/residents/$uid?key=$apiKey';

    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $idToken', // Include the ID token for authentication
        'Content-Type': 'application/json',
      },
    );

    print('fetchResident response status: ${response.statusCode}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      print('Fetched Resident Document: $data');
      return _decodeDocument(data);
    } else {
      // Extract error message from response
      String errorMessage = 'Unknown error';
      try {
        final errorData = jsonDecode(response.body);
        if (errorData['error'] != null && errorData['error']['message'] != null) {
          errorMessage = errorData['error']['message'];
        }
      } catch (e) {
        // Parsing failed
      }
      print('Error fetching resident data: $errorMessage');
      throw Exception('Error fetching resident data: $errorMessage');
    }
  }

  /// Fetches the profile document based on profileId.
  Future<Map<String, dynamic>> fetchProfile(String profileId, String idToken) async {
    final url = 'https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents/profiles/$profileId?key=$apiKey';

    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $idToken',
        'Content-Type': 'application/json',
      },
    );

    print('fetchProfile response status: ${response.statusCode}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      print('Fetched Profile Document: $data');
      return _decodeDocument(data);
    } else {
      // Extract error message from response
      String errorMessage = 'Unknown error';
      try {
        final errorData = jsonDecode(response.body);
        if (errorData['error'] != null && errorData['error']['message'] != null) {
          errorMessage = errorData['error']['message'];
        }
      } catch (e) {
        // Parsing failed
      }
      print('Error fetching profile data: $errorMessage');
      throw Exception('Error fetching profile data: $errorMessage');
    }
  }

  /// Creates a new profile document and updates the resident document with profileId.
  Future<void> createProfile(String uid, Map<String, dynamic> profileData, String idToken) async {
    // Step 1: Create a new profile document with auto-generated ID
    String createProfileUrl = 'https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents/profiles?key=$apiKey';

    final createResponse = await http.post(
      Uri.parse(createProfileUrl),
      headers: {
        'Authorization': 'Bearer $idToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'fields': _encodeFields(profileData),
      }),
    );

    print('createProfile response status: ${createResponse.statusCode}');
    print('createProfile response body: ${createResponse.body}');

    if (createResponse.statusCode == 200) {
      final data = jsonDecode(createResponse.body);
      String newProfileId = data['name'].split('/').last;
      print('Created Profile with ID: $newProfileId');

      // Step 2: Update resident document with new profileId
      String updateResidentUrl = 'https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents/residents/$uid?key=$apiKey&updateMask.fieldPaths=profileId';

      final updateResponse = await http.patch(
        Uri.parse(updateResidentUrl),
        headers: {
          'Authorization': 'Bearer $idToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'fields': {
            'profileId': {
              'stringValue': newProfileId,
            },
          },
        }),
      );

      print('updateResident response status: ${updateResponse.statusCode}');
      print('updateResident response body: ${updateResponse.body}');

      if (updateResponse.statusCode == 200) {
        print('Resident document updated with profileId: $newProfileId');
      } else {
        // Extract error message from response
        String errorMessage = 'Unknown error';
        try {
          final errorData = jsonDecode(updateResponse.body);
          if (errorData['error'] != null && errorData['error']['message'] != null) {
            errorMessage = errorData['error']['message'];
          }
        } catch (e) {
          // Parsing failed
        }
        print('Error updating resident with profileId: $errorMessage');
        throw Exception('Error updating resident with profileId: $errorMessage');
      }
    } else {
      // Extract error message from response
      String errorMessage = 'Unknown error';
      try {
        final errorData = jsonDecode(createResponse.body);
        if (errorData['error'] != null && errorData['error']['message'] != null) {
          errorMessage = errorData['error']['message'];
        }
      } catch (e) {
        // Parsing failed
      }
      print('Error creating profile: $errorMessage');
      throw Exception('Error creating profile: $errorMessage');
    }
  }

  /// Updates the profile document with the given profileId using the provided updatedData.
  Future<void> updateProfile(String profileId, Map<String, dynamic> updatedData, String idToken) async {
    // Prepare the fields to update
    Map<String, dynamic> fields = _encodeFields(updatedData);

    // Construct the Firestore REST API URL for updating the document with query parameters
    String updateProfileUrl = 'https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents/profiles/$profileId?key=$apiKey&updateMask.fieldPaths=emergencyContacts&updateMask.fieldPaths=householdHead&updateMask.fieldPaths=members&updateMask.fieldPaths=moveInDate&updateMask.fieldPaths=moveOutDate&updateMask.fieldPaths=occupation&updateMask.fieldPaths=utilities&updateMask.fieldPaths=vehicles';

    print('Update Profile URL: $updateProfileUrl'); // Debug print
    print('Update Fields: $fields'); // Debug print

    // Send the PATCH request to Firestore with only 'fields' in body
    final response = await http.patch(
      Uri.parse(updateProfileUrl),
      headers: {
        'Authorization': 'Bearer $idToken', // Include the ID token for authentication
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'fields': fields, // Only include 'fields' in the body
      }),
    );

    print('updateProfile response status: ${response.statusCode}');
    print('updateProfile response body: ${response.body}'); // Debug print

    if (response.statusCode == 200) {
      // Update successful
      print('Profile updated successfully.');
      return;
    } else {
      // Extract error message from response
      String errorMessage = 'Unknown error';
      try {
        final errorData = jsonDecode(response.body);
        if (errorData['error'] != null && errorData['error']['message'] != null) {
          errorMessage = errorData['error']['message'];
        }
      } catch (e) {
        // Parsing failed
      }
      print('Error updating profile: $errorMessage');
      throw Exception('Error updating profile: $errorMessage');
    }
  }

  /// Updates the resident document with the given uid using the provided updatedData.
  Future<void> updateResident(String uid, Map<String, dynamic> updatedData, String idToken) async {
    // Prepare the fields to update
    Map<String, dynamic> fields = _encodeFields(updatedData);

    // Construct the Firestore REST API URL for updating the document with query parameters
    String updateResidentUrl = 'https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents/residents/$uid?key=$apiKey&updateMask.fieldPaths=apartmentNumber&updateMask.fieldPaths=dob&updateMask.fieldPaths=email&updateMask.fieldPaths=floor&updateMask.fieldPaths=fullName&updateMask.fieldPaths=gender&updateMask.fieldPaths=phone&updateMask.fieldPaths=status';

    print('Update Resident URL: $updateResidentUrl'); // Debug print
    print('Update Resident Fields: $fields'); // Debug print

    // Send the PATCH request to Firestore with only 'fields' in body
    final response = await http.patch(
      Uri.parse(updateResidentUrl),
      headers: {
        'Authorization': 'Bearer $idToken', // Include the ID token for authentication
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'fields': fields, // Only include 'fields' in the body
      }),
    );

    print('updateResident response status: ${response.statusCode}');
    print('updateResident response body: ${response.body}'); // Debug print

    if (response.statusCode == 200) {
      // Update successful
      print('Resident updated successfully.');
      return;
    } else {
      // Extract error message from response
      String errorMessage = 'Unknown error';
      try {
        final errorData = jsonDecode(response.body);
        if (errorData['error'] != null && errorData['error']['message'] != null) {
          errorMessage = errorData['error']['message'];
        }
      } catch (e) {
        // Parsing failed
      }
      print('Error updating resident: $errorMessage');
      throw Exception('Error updating resident: $errorMessage');
    }
  }

  /// Encodes Dart types to Firestore field types.
  Map<String, dynamic> _encodeFields(Map<String, dynamic> data) {
    return data.map((key, value) => MapEntry(key, _encodeField(value)));
  }

  /// Helper function to encode individual fields.
  dynamic _encodeField(dynamic value) {
    if (value is String) {
      return {'stringValue': value};
    } else if (value is int) {
      return {'integerValue': value.toString()};
    } else if (value is double) {
      return {'doubleValue': value};
    } else if (value is bool) {
      return {'booleanValue': value};
    } else if (value is List) {
      if (value.isEmpty) {
        return {
          'arrayValue': {'values': []}
        };
      }
      // Determine the type of the first element
      var first = value.first;
      if (first is Map<String, dynamic>) {
        return {
          'arrayValue': {
            'values': value
                .map((item) => {
                      'mapValue': {'fields': _encodeFields(item)}
                    })
                .toList(),
          }
        };
      } else {
        return {
          'arrayValue': {
            'values': value.map((item) => _encodeField(item)).toList(),
          }
        };
      }
    } else if (value is Map<String, dynamic>) {
      return {
        'mapValue': {
          'fields': _encodeFields(value),
        }
      };
    } else {
      // Handle other data types as needed
      return {};
    }
  }

  /// Decodes Firestore document data to a Dart map.
  Map<String, dynamic> _decodeDocument(Map<String, dynamic> data) {
    Map<String, dynamic> decoded = {};

    if (data.containsKey('fields')) {
      data['fields'].forEach((key, value) {
        decoded[key] = _decodeField(value);
      });
    }

    return decoded;
  }

  /// Helper function to decode individual Firestore fields.
  dynamic _decodeField(dynamic value) {
    if (value.containsKey('stringValue')) {
      return value['stringValue'];
    } else if (value.containsKey('integerValue')) {
      return int.tryParse(value['integerValue']) ?? 0;
    } else if (value.containsKey('doubleValue')) {
      return value['doubleValue'];
    } else if (value.containsKey('booleanValue')) {
      return value['booleanValue'];
    } else if (value.containsKey('arrayValue')) {
      List<dynamic> list = [];
      if (value['arrayValue']['values'] != null) {
        list = value['arrayValue']['values'].map((item) => _decodeField(item)).toList();
      }
      return list;
    } else if (value.containsKey('mapValue')) {
      Map<String, dynamic> map = {};
      if (value['mapValue']['fields'] != null) {
        value['mapValue']['fields'].forEach((k, v) {
          map[k] = _decodeField(v);
        });
      }
      return map;
    } else {
      return null;
    }
  }
}
