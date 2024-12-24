// lib/resident/presentation/profile_page.dart

import 'package:flutter/material.dart';
import '../data/resident_repository.dart';

/// Lớp mô tả một phương tiện
class Vehicle {
  String type;
  String number;

  Vehicle({required this.type, required this.number});

  /// Tạo một phương tiện từ một Map
  factory Vehicle.fromMap(Map<String, dynamic> map) {
    return Vehicle(
      type: map['type'] ?? '',
      number: map['number'] ?? '',
    );
  }

  /// Chuyển đổi phương tiện thành Map<String, String>
  Map<String, String> toMap() {
    return {
      'type': type,
      'number': number,
    };
  }
}

/// Lớp mô tả một thành viên
class Member {
  String relationship;
  String name;

  Member({required this.relationship, required this.name});

  /// Tạo một thành viên từ một Map
  factory Member.fromMap(Map<String, dynamic> map) {
    return Member(
      relationship: map['relationship'] ?? '',
      name: map['name'] ?? '',
    );
  }

  /// Chuyển đổi thành viên thành Map<String, String>
  Map<String, String> toMap() {
    return {
      'relationship': relationship,
      'name': name,
    };
  }
}

class ProfilePage extends StatefulWidget {
  final String uid; // UID của người dùng
  final String idToken;
  final ResidentRepository residentRepository;

  const ProfilePage({
    Key? key,
    required this.uid,
    required this.idToken,
    required this.residentRepository,
  }) : super(key: key);

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // Trạng thái chỉnh sửa
  bool isEditing = false;

  // Trạng thái tải dữ liệu
  bool isLoading = true;
  String? errorMessage;

  // Các controller cho các TextField từ collection 'residents'
  final TextEditingController idController = TextEditingController();
  final TextEditingController apartmentNumberController = TextEditingController();
  final TextEditingController dobController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController floorController = TextEditingController();
  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController genderController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController statusController = TextEditingController();

  // Các controller cho các TextField từ collection 'profiles'
  final TextEditingController emergencyContactsController = TextEditingController();
  final TextEditingController householdHeadController = TextEditingController();
  final TextEditingController moveInDateController = TextEditingController();
  final TextEditingController moveOutDateController = TextEditingController();
  final TextEditingController occupationController = TextEditingController();
  final TextEditingController utilitiesController = TextEditingController();
  final TextEditingController vehiclesController = TextEditingController();

  String? profileId; // Biến lưu trữ profileId

  // Danh sách các tiện ích có sẵn
  final List<String> availableUtilities = [
    'Điện',
    'Nước',
    'Internet',
    'Gas',
    'Vệ sinh',
    'An ninh',
  ];

  // Trạng thái các tiện ích được chọn
  Map<String, bool> selectedUtilities = {};

  // Danh sách phương tiện
  List<Vehicle> vehicles = [];

  // Danh sách thành viên
  List<Member> members = [];

  @override
  void initState() {
    super.initState();
    // Khởi tạo trạng thái các tiện ích
    for (var utility in availableUtilities) {
      selectedUtilities[utility] = false;
    }
    // Fetch dữ liệu từ 'residents' và 'profiles'
    fetchResidentAndProfileData();
  }

  Future<void> fetchResidentAndProfileData() async {
    try {
      // Bước 1: Fetch dữ liệu từ collection 'residents'
      final residentData = await widget.residentRepository.fetchResident(widget.uid, widget.idToken);

      print('Fetched resident data: $residentData'); // Debug print

      setState(() {
        // Gán giá trị từ 'residents' vào các controller
        idController.text = residentData['id']?.toString() ?? widget.uid;
        apartmentNumberController.text = residentData['apartmentNumber']?.toString() ?? '';
        dobController.text = residentData['dob'] ?? '';
        emailController.text = residentData['email'] ?? '';
        floorController.text = residentData['floor']?.toString() ?? '';
        fullNameController.text = residentData['fullName'] ?? '';
        genderController.text = residentData['gender'] ?? '';
        phoneController.text = residentData['phone'] ?? '';
        statusController.text = residentData['status'] ?? 'Đang cư trú';

        // Kiểm tra sự tồn tại của profileId
        if (residentData.containsKey('profileId')) {
          profileId = residentData['profileId'];
        } else {
          profileId = null;
        }

        if (profileId == null) {
          // Nếu không có profileId, đặt các trường liên quan đến profiles thành trống
          emergencyContactsController.text = '';
          householdHeadController.text = '';
          moveInDateController.text = '';
          moveOutDateController.text = '';
          occupationController.text = '';
          utilitiesController.text = '';

          // Đặt lại trạng thái các tiện ích
          for (var utility in availableUtilities) {
            selectedUtilities[utility] = false;
          }

          // Đặt lại danh sách phương tiện và thành viên
          vehicles = [];
          members = [];
        }
      });

      if (profileId != null) {
        // Bước 2: Nếu profileId tồn tại, fetch dữ liệu từ collection 'profiles'
        final profileData = await widget.residentRepository.fetchProfile(profileId!, widget.idToken);
        print('Fetched profile data: $profileData'); // Debug print

        setState(() {
          // Gán giá trị từ 'profiles' vào các controller
          emergencyContactsController.text = _convertToStringList(profileData['emergencyContacts']);
          householdHeadController.text = profileData['householdHead'] ?? '';
          moveInDateController.text = profileData['moveInDate'] ?? '';
          moveOutDateController.text = profileData['moveOutDate'] ?? '';
          occupationController.text = profileData['occupation'] ?? '';
          utilitiesController.text = _convertToStringList(profileData['utilities']);

          // Cập nhật trạng thái các tiện ích được chọn
          List<dynamic> utilitiesList = _convertToList(profileData['utilities']);
          for (var utility in utilitiesList) {
            if (selectedUtilities.containsKey(utility)) {
              selectedUtilities[utility] = true;
            }
          }

          // Cập nhật danh sách phương tiện
          List<dynamic> vehiclesList = _convertToList(profileData['vehicles']);
          vehicles = vehiclesList.map((v) {
            if (v is Map<String, dynamic>) {
              return Vehicle.fromMap(v);
            } else {
              return Vehicle(type: '', number: '');
            }
          }).toList();

          // Cập nhật danh sách thành viên
          List<dynamic> membersList = _convertToList(profileData['members']);
          members = membersList.map((m) {
            if (m is Map<String, dynamic>) {
              return Member.fromMap(m);
            } else {
              return Member(relationship: '', name: '');
            }
          }).toList();
        });
      }

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
      print('Error fetching resident or profile data: $e'); // Debug print
    }
  }

  /// Hàm chuyển đổi dữ liệu thành chuỗi, hỗ trợ cả List và Map
  String _convertToStringList(dynamic data) {
    if (data is List) {
      return data.join(', ');
    } else if (data is Map<String, dynamic>) {
      return data.values.join(', ');
    }
    return '';
  }

  /// Hàm chuyển đổi dữ liệu thành List<dynamic>, hỗ trợ cả List và Map
  List<dynamic> _convertToList(dynamic data) {
    if (data is List) {
      return data;
    } else if (data is Map<String, dynamic>) {
      return data.values.toList();
    }
    return [];
  }

  @override
  void dispose() {
    // Dispose các controller khi widget bị hủy
    idController.dispose();
    apartmentNumberController.dispose();
    dobController.dispose();
    emailController.dispose();
    floorController.dispose();
    fullNameController.dispose();
    genderController.dispose();
    phoneController.dispose();
    statusController.dispose();
    emergencyContactsController.dispose();
    householdHeadController.dispose();
    moveInDateController.dispose();
    moveOutDateController.dispose();
    occupationController.dispose();
    utilitiesController.dispose();
    vehiclesController.dispose();
    super.dispose();
  }

  /// Hàm xử lý khi nhấn nút "Chỉnh sửa" hoặc "Hoàn tất"
  void toggleEdit() async {
    if (isEditing) {
      // Kiểm tra dữ liệu từ 'residents'
      if (idController.text.trim().isEmpty || apartmentNumberController.text.trim().isEmpty || dobController.text.trim().isEmpty || emailController.text.trim().isEmpty || floorController.text.trim().isEmpty || fullNameController.text.trim().isEmpty || genderController.text.trim().isEmpty || phoneController.text.trim().isEmpty || statusController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vui lòng điền đầy đủ thông tin từ người dùng.')),
        );
        return;
      }

      // Kiểm tra định dạng email
      if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(emailController.text.trim())) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Email không hợp lệ. Vui lòng nhập lại.')),
        );
        return;
      }

      // Kiểm tra định dạng ngày sinh
      if (!_isValidDate(dobController.text.trim())) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ngày sinh không hợp lệ. Vui lòng nhập lại.')),
        );
        return;
      }

      // Kiểm tra định dạng số điện thoại
      if (!_isValidPhoneNumber(phoneController.text.trim())) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Số điện thoại không hợp lệ. Vui lòng nhập lại.')),
        );
        return;
      }

      // Kiểm tra định dạng ngày moveInDate và moveOutDate nếu đang chỉnh sửa profile
      if (profileId != null) {
        if (moveInDateController.text.trim().isNotEmpty && !_isValidDate(moveInDateController.text.trim())) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ngày nhập không hợp lệ. Vui lòng nhập lại.')),
          );
          return;
        }
        if (moveOutDateController.text.trim().isNotEmpty && !_isValidDate(moveOutDateController.text.trim())) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ngày xuất không hợp lệ. Vui lòng nhập lại.')),
          );
          return;
        }
      }

      // Prepare dữ liệu từ 'residents' để cập nhật
      Map<String, dynamic> residentData = {
        'id': idController.text.trim(),
        'apartmentNumber': int.tryParse(apartmentNumberController.text.trim()) ?? 0,
        'dob': dobController.text.trim(),
        'email': emailController.text.trim(),
        'floor': int.tryParse(floorController.text.trim()) ?? 0,
        'fullName': fullNameController.text.trim(),
        'gender': genderController.text.trim(),
        'phone': phoneController.text.trim(),
        'status': statusController.text.trim(),
      };

      // Prepare dữ liệu từ 'profiles' để cập nhật nếu có
      Map<String, dynamic>? profileData;
      if (profileId != null) {
        profileData = {
          'emergencyContacts': emergencyContactsController.text.trim().isNotEmpty ? emergencyContactsController.text.trim().split(',').map((e) => e.trim()).toList() : [],
          'householdHead': householdHeadController.text.trim(),
          'members': _parseMembers(members),
          'moveInDate': moveInDateController.text.trim(),
          'moveOutDate': moveOutDateController.text.trim(),
          'occupation': occupationController.text.trim(),
          'utilities': selectedUtilities.entries.where((entry) => entry.value).map((entry) => entry.key).toList(),
          'vehicles': _parseVehicles(vehicles),
        };
      }

      setState(() {
        isEditing = false;
        isLoading = true;
      });

      try {
        // Bước 1: Cập nhật dữ liệu từ 'residents'
        await widget.residentRepository.updateResident(widget.uid, residentData, widget.idToken);

        // Bước 2: Cập nhật hoặc tạo mới dữ liệu từ 'profiles'
        if (profileId != null) {
          // Nếu profileId tồn tại, cập nhật profile
          await widget.residentRepository.updateProfile(profileId!, profileData!, widget.idToken);
        } else {
          // Nếu không có profileId, tạo mới profile và cập nhật profileId trong 'residents'
          await widget.residentRepository.createProfile(widget.uid, profileData!, widget.idToken);
        }

        // Reload dữ liệu sau khi cập nhật
        await fetchResidentAndProfileData();

        // Hiển thị thông báo thành công
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Thành công'),
              content: const Text('Cập nhật hồ sơ thành công.'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Đóng dialog
                  },
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      } catch (e) {
        setState(() {
          isLoading = false;
        });

        // Hiển thị thông báo lỗi
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Lỗi'),
              content: Text(e.toString()),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Đóng dialog
                  },
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      }
    } else {
      // Khi nhấn "Chỉnh sửa", bật chế độ chỉnh sửa
      setState(() {
        isEditing = true;
      });
    }
  }

  /// Hàm phân tích các phương tiện từ danh sách
  List<Map<String, String>> _parseVehicles(List<Vehicle> vehiclesList) {
    return vehiclesList.map((v) => v.toMap()).toList();
  }

  /// Hàm phân tích các thành viên từ danh sách
  List<Map<String, String>> _parseMembers(List<Member> membersList) {
    return membersList.map((m) => m.toMap()).toList();
  }

  /// Hàm kiểm tra định dạng ngày
  bool _isValidDate(String date) {
    try {
      final parts = date.split('/');
      if (parts.length != 3) return false;
      final day = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final year = int.parse(parts[2]);
      final parsedDate = DateTime(year, month, day);
      return parsedDate.day == day && parsedDate.month == month && parsedDate.year == year;
    } catch (e) {
      return false;
    }
  }

  /// Hàm kiểm tra định dạng số điện thoại
  bool _isValidPhoneNumber(String phone) {
    final regex = RegExp(r'^\d{10}$'); // Phải gồm 10 chữ số
    return regex.hasMatch(phone);
  }

  /// Hàm thêm thành viên mới
  void _addMember() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final TextEditingController relationshipController = TextEditingController();
        final TextEditingController nameController = TextEditingController();

        return AlertDialog(
          title: const Text('Thêm Thành Viên'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: relationshipController,
                decoration: const InputDecoration(
                  labelText: 'Quan hệ',
                ),
              ),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Tên',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Đóng dialog
              },
              child: const Text('Hủy'),
            ),
            TextButton(
              onPressed: () {
                if (relationshipController.text.trim().isNotEmpty && nameController.text.trim().isNotEmpty) {
                  setState(() {
                    members.add(Member(
                      relationship: relationshipController.text.trim(),
                      name: nameController.text.trim(),
                    ));
                  });
                  Navigator.of(context).pop(); // Đóng dialog
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Vui lòng điền đầy đủ thông tin thành viên.')),
                  );
                }
              },
              child: const Text('Thêm'),
            ),
          ],
        );
      },
    );
  }

  /// Hàm thêm phương tiện mới
  void _addVehicle() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final TextEditingController typeController = TextEditingController();
        final TextEditingController numberController = TextEditingController();

        return AlertDialog(
          title: const Text('Thêm Phương Tiện'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: typeController,
                decoration: const InputDecoration(
                  labelText: 'Loại xe',
                ),
              ),
              TextField(
                controller: numberController,
                decoration: const InputDecoration(
                  labelText: 'Biển số',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Đóng dialog
              },
              child: const Text('Hủy'),
            ),
            TextButton(
              onPressed: () {
                if (typeController.text.trim().isNotEmpty && numberController.text.trim().isNotEmpty) {
                  setState(() {
                    vehicles.add(Vehicle(
                      type: typeController.text.trim(),
                      number: numberController.text.trim(),
                    ));
                  });
                  Navigator.of(context).pop(); // Đóng dialog
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Vui lòng điền đầy đủ thông tin phương tiện.')),
                  );
                }
              },
              child: const Text('Thêm'),
            ),
          ],
        );
      },
    );
  }

  /// Widget để xây dựng các trường thông tin từ 'residents' và 'id'
  Widget _buildResidentField(String label, TextEditingController controller, String fieldName, {bool readOnly = false}) {
    // Kiểm tra nếu trường là 'status', sử dụng Dropdown
    if (fieldName == 'status') {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Nhãn thông tin
          Container(
            width: 160, // Độ rộng cố định để các trường thẳng hàng
            padding: const EdgeInsets.only(top: 12.0),
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ),
          // DropdownButtonFormField
          Flexible(
            fit: FlexFit.loose,
            child: DropdownButtonFormField<String>(
              value: controller.text.trim(),
              items: const [
                DropdownMenuItem(
                  value: 'Đã duyệt',
                  child: Text('Đã duyệt'),
                ),
                DropdownMenuItem(
                  value: 'Đã rời đi',
                  child: Text('Đã rời đi'),
                ),
              ],
              onChanged: isEditing
                  ? (String? newValue) {
                      setState(() {
                        controller.text = newValue ?? 'Đã duyệt';
                      });
                    }
                  : null,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: (!isEditing) ? Colors.grey : Colors.black),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: (!isEditing) ? Colors.grey : Colors.black),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: (!isEditing) ? Colors.grey : Colors.black, width: 2),
                ),
              ),
              disabledHint: Text(
                controller.text.trim(),
                style: const TextStyle(color: Colors.grey),
              ),
            ),
          ),
        ],
      );
    }

    // Các trường thông tin khác
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Nhãn thông tin
        Container(
          width: 160, // Độ rộng cố định để các trường thẳng hàng
          padding: const EdgeInsets.only(top: 12.0),
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
        ),
        // TextField dữ liệu
        Flexible(
          fit: FlexFit.loose,
          child: TextField(
            controller: controller,
            readOnly: !isEditing || readOnly, // Vô hiệu hóa khi không chỉnh sửa hoặc nếu là readOnly
            style: TextStyle(
              color: (!isEditing || readOnly) ? Colors.grey : Colors.black, // Màu chữ thay đổi theo trạng thái
            ),
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: (!isEditing || readOnly) ? Colors.grey : Colors.black),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: (!isEditing || readOnly) ? Colors.grey : Colors.black),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: (!isEditing || readOnly) ? Colors.grey : Colors.black, width: 2),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Widget để xây dựng các trường thông tin từ 'profiles' cho thành viên
  Widget _buildMemberField(String label, TextEditingController controller, Function(String) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        TextField(
          controller: controller,
          enabled: isEditing,
          onChanged: onChanged,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }

  /// Widget để xây dựng các trường thông tin từ 'profiles'
  Widget _buildProfileField(String label, TextEditingController controller, String fieldName, {bool readOnly = false}) {
    // Kiểm tra nếu trường là ngày, sử dụng DatePicker
    if (fieldName == 'moveInDate' || fieldName == 'moveOutDate') {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Nhãn thông tin
          Container(
            width: 160,
            padding: const EdgeInsets.only(top: 12.0),
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ),
          // TextField dữ liệu với DatePicker
          Flexible(
            fit: FlexFit.loose,
            child: GestureDetector(
              onTap: isEditing && !readOnly
                  ? () async {
                      DateTime initialDate = _isValidDate(controller.text.trim()) ? _convertStringToDate(controller.text.trim()) : DateTime.now();

                      // Define firstDate and lastDate based on fieldName
                      DateTime firstDate;
                      DateTime lastDate;

                      if (fieldName == 'moveInDate') {
                        // moveInDate: Cannot select dates after today
                        firstDate = DateTime(1900);
                        lastDate = DateTime.now();
                      } else {
                        // moveOutDate: Cannot select dates before today
                        firstDate = DateTime.now();
                        lastDate = DateTime(DateTime.now().year + 10);
                      }

                      DateTime? pickedDate = await showDatePicker(
                        context: context,
                        initialDate: initialDate,
                        firstDate: firstDate,
                        lastDate: lastDate,
                      );
                      if (pickedDate != null) {
                        setState(() {
                          controller.text = "${pickedDate.day.toString().padLeft(2, '0')}/${pickedDate.month.toString().padLeft(2, '0')}/${pickedDate.year}";
                        });
                      }
                    }
                  : null,
              child: AbsorbPointer(
                child: TextField(
                  controller: controller,
                  readOnly: true, // Vô hiệu hóa khi không chỉnh sửa
                  style: TextStyle(
                    color: isEditing && !readOnly ? Colors.black : Colors.grey, // Màu chữ thay đổi theo trạng thái
                  ),
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: isEditing && !readOnly ? Colors.black : Colors.grey),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: isEditing && !readOnly ? Colors.black : Colors.grey),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: isEditing && !readOnly ? Colors.black : Colors.grey, width: 2),
                    ),
                    isDense: true, // Giảm kích thước của TextField
                    contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                    suffixIcon: isEditing && !readOnly ? const Icon(Icons.calendar_today) : null, // Hiển thị biểu tượng lịch nếu đang chỉnh sửa
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }

    // Các trường thông tin khác
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Nhãn thông tin
        Container(
          width: 160, // Độ rộng cố định để các trường thẳng hàng
          padding: const EdgeInsets.only(top: 12.0),
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
        ),
        // TextField dữ liệu
        Flexible(
          fit: FlexFit.loose,
          child: TextField(
            controller: controller,
            readOnly: !isEditing || readOnly, // Vô hiệu hóa khi không chỉnh sửa hoặc nếu là readOnly
            style: TextStyle(
              color: (!isEditing || readOnly) ? Colors.grey : Colors.black, // Màu chữ thay đổi theo trạng thái
            ),
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: (!isEditing || readOnly) ? Colors.grey : Colors.black),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: (!isEditing || readOnly) ? Colors.grey : Colors.black),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: (!isEditing || readOnly) ? Colors.grey : Colors.black, width: 2),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Hàm chuyển đổi chuỗi thành định dạng DateTime
  DateTime _convertStringToDate(String date) {
    try {
      final parts = date.split('/');
      if (parts.length != 3) return DateTime.now();
      final day = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final year = int.parse(parts[2]);
      final parsedDate = DateTime(year, month, day);
      return parsedDate;
    } catch (e) {
      return DateTime.now();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Hiển thị loading hoặc error nếu cần
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (errorMessage != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Hồ Sơ Nhân Khẩu'),
        ),
        body: Center(
          child: Text(
            errorMessage!,
            style: const TextStyle(color: Colors.red),
          ),
        ),
      );
    }

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Phần "Thông tin người dùng"
            const Text(
              'Thông Tin Người Dùng',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            // Dòng ID
            _buildResidentField('ID:', idController, 'id', readOnly: true),
            const SizedBox(height: 10),
            // Hàng: Họ và tên, Ngày sinh, Giới tính
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: _buildResidentField('Họ và tên:', fullNameController, 'fullName'),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: _buildResidentField('Ngày sinh:', dobController, 'dob'),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: _buildResidentField('Giới tính:', genderController, 'gender'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Hàng: Email, Số điện thoại
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: _buildResidentField('Email:', emailController, 'email'),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: _buildResidentField('Số điện thoại:', phoneController, 'phone'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Hàng: Tầng, Số căn hộ, Trạng thái
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: _buildResidentField('Tầng:', floorController, 'floor'),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: _buildResidentField('Số căn hộ:', apartmentNumberController, 'apartmentNumber'),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 3,
                  child: _buildResidentField('Trạng thái:', statusController, 'status'),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Phần "Thông tin chi tiết" luôn được hiển thị
            const Text(
              'Thông Tin Chi Tiết',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            // Liên hệ khẩn cấp
            _buildProfileField('Liên hệ khẩn cấp:', emergencyContactsController, 'emergencyContacts'),
            const SizedBox(height: 10),
            // Chủ hộ
            _buildProfileField('Chủ hộ:', householdHeadController, 'householdHead'),
            const SizedBox(height: 10),
            // Thành viên
            const Text(
              'Thành viên:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            ...members.map((member) {
              // Tạo controller cho mỗi thành viên để quản lý thay đổi
              final relationshipController = TextEditingController(text: member.relationship);
              final nameController = TextEditingController(text: member.name);

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  children: [
                    // Quan hệ
                    Expanded(
                      flex: 2,
                      child: _buildMemberField(
                        'Quan hệ:',
                        relationshipController,
                        (value) {
                          member.relationship = value;
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Tên
                    Expanded(
                      flex: 3,
                      child: _buildMemberField(
                        'Tên:',
                        nameController,
                        (value) {
                          member.name = value;
                        },
                      ),
                    ),
                    if (isEditing)
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          setState(() {
                            members.remove(member);
                          });
                        },
                      ),
                  ],
                ),
              );
            }).toList(),
            if (isEditing)
              ElevatedButton.icon(
                onPressed: () {
                  _addMember();
                },
                icon: const Icon(Icons.add),
                label: const Text('Thêm Thành Viên'),
              ),
            const SizedBox(height: 10),
            // Ngày nhập, Ngày xuất
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: _buildProfileField('Ngày nhập:', moveInDateController, 'moveInDate'),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 3,
                  child: _buildProfileField('Ngày xuất:', moveOutDateController, 'moveOutDate'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Nghề nghiệp
            _buildProfileField('Nghề nghiệp:', occupationController, 'occupation'),
            const SizedBox(height: 10),
            // Tiện ích dưới dạng checkbox
            const Text(
              'Tiện ích:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            Wrap(
              spacing: 10.0,
              children: availableUtilities.map((utility) {
                return FilterChip(
                  label: Text(utility),
                  selected: selectedUtilities[utility] ?? false,
                  onSelected: isEditing
                      ? (bool selected) {
                          setState(() {
                            selectedUtilities[utility] = selected;
                          });
                        }
                      : null,
                );
              }).toList(),
            ),
            const SizedBox(height: 10),
            // Phương tiện
            const Text(
              'Phương tiện:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            ...vehicles.map((vehicle) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  children: [
                    // Loại xe
                    Expanded(
                      flex: 2,
                      child: _buildProfileField(
                        'Loại xe:',
                        TextEditingController(text: vehicle.type),
                        'vehicleType',
                        readOnly: true,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Biển số
                    Expanded(
                      flex: 3,
                      child: _buildProfileField(
                        'Biển số:',
                        TextEditingController(text: vehicle.number),
                        'vehicleNumber',
                        readOnly: true,
                      ),
                    ),
                    if (isEditing)
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          setState(() {
                            vehicles.remove(vehicle);
                          });
                        },
                      ),
                  ],
                ),
              );
            }).toList(),
            if (isEditing)
              ElevatedButton.icon(
                onPressed: () {
                  _addVehicle();
                },
                icon: const Icon(Icons.add),
                label: const Text('Thêm Phương Tiện'),
              ),
            const SizedBox(height: 20),

            // Nút Chỉnh Sửa/Hoàn Tất
            Center(
              child: ElevatedButton.icon(
                onPressed: toggleEdit,
                icon: Icon(isEditing ? Icons.check : Icons.edit),
                label: Text(isEditing ? 'Hoàn tất' : 'Chỉnh sửa'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  textStyle: const TextStyle(fontSize: 16),
                  backgroundColor: isEditing ? Colors.green : Colors.blueAccent, // Màu nút thay đổi theo trạng thái
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
