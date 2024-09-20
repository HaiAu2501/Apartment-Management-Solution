// lib/features/authentication/presentation/user_info_page.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../authentication/data/authentication_service.dart';
import 'login_page.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:ams/core/utils/extensions.dart';

class UserInfoPage extends StatefulWidget {
  final AuthenticationService authService;
  final String idToken;
  final String uid;
  final String role;

  UserInfoPage({
    required this.authService,
    required this.idToken,
    required this.uid,
    required this.role,
  });

  @override
  _UserInfoPageState createState() => _UserInfoPageState();
}

class _UserInfoPageState extends State<UserInfoPage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final TextEditingController fullNameController = TextEditingController();
  String gender = 'Male';
  DateTime? dob;
  final TextEditingController cccdController = TextEditingController();

  String? selectedApartment;
  String? selectedBuilding;
  int? selectedFloor;
  int? selectedApartmentNumber;

  // Data from metadata
  List<String> apartments = [];
  List<String> buildings = [];
  int numberOfFloors = 0;
  int apartmentsPerFloor = 0;

  bool isLoading = false;
  String? message;

  @override
  void initState() {
    super.initState();
    fetchMetadata();
  }

  Future<void> fetchMetadata() async {
    try {
      // Giả sử bạn có một document duy nhất trong metadata collection
      // Document ID: apartment_example
      final response = await http.get(
        Uri.https(
          'firestore.googleapis.com',
          '/v1/projects/${widget.authService.projectId}/databases/(default)/documents/metadata/EXAMPLE',
          {
            'key': widget.authService.apiKey,
          },
        ),
        headers: {
          'Authorization': 'Bearer ${widget.idToken}',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          apartments = [data['fields']['apartment_name']['stringValue']];
          buildings = List<String>.from(data['fields']['buildings']
                  ['arrayValue']['values']
              .map((e) => e['stringValue']));
          numberOfFloors = data['fields']['number_of_floors']['integerValue'] !=
                  null
              ? int.parse(data['fields']['number_of_floors']['integerValue'])
              : 0;
          apartmentsPerFloor =
              data['fields']['apartments_per_floor']['integerValue'] != null
                  ? int.parse(
                      data['fields']['apartments_per_floor']['integerValue'])
                  : 0;
        });
      } else {
        print('Lỗi khi lấy metadata: ${response.statusCode}');
        print('Chi tiết lỗi: ${response.body}');
        setState(() {
          message = 'Không thể tải thông tin chung cư. Vui lòng thử lại sau.';
        });
      }
    } catch (e) {
      print('Lỗi khi lấy metadata: $e');
      setState(() {
        message = 'Lỗi khi tải thông tin chung cư.';
      });
    }
  }

  Future<void> submitInfo() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (selectedApartment == null ||
        selectedBuilding == null ||
        selectedFloor == null ||
        selectedApartmentNumber == null) {
      setState(() {
        message = 'Vui lòng chọn đầy đủ thông tin về chung cư.';
      });
      return;
    }

    setState(() {
      isLoading = true;
      message = null;
    });

    try {
      // Tạo dữ liệu để gửi lên 'queue'
      Map<String, dynamic> queueData = {
        'uid': widget.uid,
        'full_name': fullNameController.text.trim(),
        'gender': gender,
        'dob': dob!.toUtc().toIso8601String(),
        'cccd': cccdController.text.trim(),
        'apartment_name': selectedApartment!,
        'building_name': selectedBuilding!,
        'floor_number': selectedFloor!,
        'apartment_number': selectedApartmentNumber!,
        'role': widget.role, // Nếu cần thiết
      };

      // Gửi dữ liệu lên collection 'queue'
      bool success = await widget.authService
          .createQueueDocument(widget.idToken, queueData);

      if (success) {
        setState(() {
          message = 'Thông tin đã được gửi thành công và đang chờ phê duyệt.';
          isLoading = false;
        });
        // Chuyển hướng về trang đăng nhập hoặc hiển thị thông báo thành công
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => LoginPage(authService: widget.authService),
          ),
        );
      } else {
        setState(() {
          message = 'Gửi thông tin thất bại. Vui lòng thử lại.';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        message = 'Lỗi: $e';
        isLoading = false;
      });
      print('Lỗi khi gửi queue: $e');
    }
  }

  Future<void> selectDOB() async {
    DateTime initialDate = DateTime.now().subtract(Duration(days: 365 * 18));
    DateTime firstDate = DateTime(1900);
    DateTime lastDate = DateTime.now();

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );

    if (picked != null && picked != dob) {
      setState(() {
        dob = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Nhập Thông Tin Cá Nhân'),
        ),
        body: Padding(
          padding: EdgeInsets.all(16.0),
          child: SingleChildScrollView(
              child: Form(
            key: _formKey,
            child: Column(
              children: [
                // Họ và tên
                TextFormField(
                  controller: fullNameController,
                  decoration: InputDecoration(labelText: 'Họ và Tên'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng nhập họ và tên.';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 10),
                // Giới tính
                DropdownButtonFormField<String>(
                  value: gender,
                  decoration: InputDecoration(labelText: 'Giới Tính'),
                  items:
                      <String>['Male', 'Female', 'Other'].map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value.capitalize()),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      gender = newValue!;
                    });
                  },
                ),
                SizedBox(height: 10),
                // Ngày tháng năm sinh
                GestureDetector(
                  onTap: selectDOB,
                  child: AbsorbPointer(
                    child: TextFormField(
                      decoration:
                          InputDecoration(labelText: 'Ngày Tháng Năm Sinh'),
                      validator: (value) {
                        if (dob == null) {
                          return 'Vui lòng chọn ngày sinh.';
                        }
                        return null;
                      },
                      controller: TextEditingController(
                        text: dob == null
                            ? ''
                            : DateFormat('dd/MM/yyyy').format(dob!),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 10),
                // Số CCCD
                TextFormField(
                  controller: cccdController,
                  decoration: InputDecoration(labelText: 'Số CCCD'),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng nhập số CCCD.';
                    }
                    if (!RegExp(r'^\d+$').hasMatch(value)) {
                      return 'Số CCCD chỉ chứa chữ số.';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 20),
                // Tên chung cư
                DropdownButtonFormField<String>(
                  value: selectedApartment,
                  decoration: InputDecoration(labelText: 'Tên Chung Cư'),
                  items: apartments.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedApartment = newValue!;
                      // Reset các trường liên quan
                      selectedBuilding = null;
                      selectedFloor = null;
                      selectedApartmentNumber = null;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng chọn tên chung cư.';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 10),
                // Tên tòa nhà
                DropdownButtonFormField<String>(
                  value: selectedBuilding,
                  decoration: InputDecoration(labelText: 'Tên Tòa Nhà'),
                  items: selectedApartment != null
                      ? buildings.map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList()
                      : [],
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedBuilding = newValue!;
                      // Reset các trường liên quan
                      selectedFloor = null;
                      selectedApartmentNumber = null;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng chọn tên tòa nhà.';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 10),
                // Tầng số
                DropdownButtonFormField<int>(
                  value: selectedFloor,
                  decoration: InputDecoration(labelText: 'Tầng Số'),
                  items: selectedApartment != null
                      ? List.generate(numberOfFloors, (index) => index + 1)
                          .map((int value) {
                          return DropdownMenuItem<int>(
                            value: value,
                            child: Text(value.toString()),
                          );
                        }).toList()
                      : [],
                  onChanged: (int? newValue) {
                    setState(() {
                      selectedFloor = newValue!;
                      // Reset căn hộ số
                      selectedApartmentNumber = null;
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Vui lòng chọn tầng số.';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 10),
                // Căn hộ số
                DropdownButtonFormField<int>(
                  value: selectedApartmentNumber,
                  decoration: InputDecoration(labelText: 'Căn Hộ Số'),
                  items: selectedFloor != null
                      ? List.generate(apartmentsPerFloor, (index) => index + 1)
                          .map((int value) {
                          return DropdownMenuItem<int>(
                            value: value,
                            child: Text(value.toString()),
                          );
                        }).toList()
                      : [],
                  onChanged: (int? newValue) {
                    setState(() {
                      selectedApartmentNumber = newValue!;
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Vui lòng chọn căn hộ số.';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 20),
                // Hiển thị thông báo
                if (message != null)
                  Text(
                    message!,
                    style: TextStyle(
                        color: message!.contains('thành công')
                            ? Colors.green
                            : Colors.red),
                  ),
                SizedBox(height: 20),
                // Nút Submit
                isLoading
                    ? CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: submitInfo,
                        child: Text('Gửi Thông Tin'),
                      ),
              ],
            ),
          )),
        ));
  }
}
