// lib/resident/presentation/profile_page.dart

import 'package:flutter/material.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class Member {
  String relation;
  String name;
  final TextEditingController relationController;
  final TextEditingController nameController;

  Member({this.relation = '', this.name = ''})
      : relationController = TextEditingController(text: relation),
        nameController = TextEditingController(text: name);

  void dispose() {
    relationController.dispose();
    nameController.dispose();
  }
}

class Vehicle {
  String type;
  String name;
  final TextEditingController nameController;

  Vehicle({this.type = 'Ô tô', this.name = ''}) : nameController = TextEditingController(text: name);

  void dispose() {
    nameController.dispose();
  }
}

class _ProfilePageState extends State<ProfilePage> {
  // Trạng thái chỉnh sửa
  bool isEditing = false;

  // Các controller cho các TextField
  final TextEditingController householdHeadController = TextEditingController(text: "Nguyễn Văn A"); // householdHead
  final TextEditingController dobController = TextEditingController(text: "01/01/1980"); // dob
  final TextEditingController occupationController = TextEditingController(text: "Kỹ sư phần mềm"); // occupation
  final TextEditingController emailController = TextEditingController(text: "nguyenvana@example.com"); // email
  final TextEditingController apartmentNumberController = TextEditingController(text: "A-101"); // apartmentNumber
  final TextEditingController floorController = TextEditingController(text: "10"); // floor

  // Danh sách thành viên
  List<Member> members = [
    Member(relation: "Vợ", name: "Nguyễn Văn B"),
    Member(relation: "Con trai", name: "Nguyễn Văn C"),
    Member(relation: "Con gái", name: "Nguyễn Văn D"),
  ];

  // Danh sách liên hệ khẩn cấp
  List<TextEditingController> emergencyContactControllers = [
    TextEditingController(text: "0123456789"),
    TextEditingController(text: "0987654321"),
  ];

  // Danh sách phương tiện
  List<Vehicle> vehicles = [
    Vehicle(type: "Ô tô", name: "ABC-123"),
    Vehicle(type: "Xe máy", name: "XYZ-789"),
  ];

  // Danh sách tiện ích từ danh sách có sẵn
  final List<String> predefinedUtilities = [
    "Điện",
    "Nước",
    "Internet",
    "Đỗ xe",
    "An ninh",
    "Gym",
    "Hồ bơi",
    "Sân chơi trẻ em",
    "Phòng sinh hoạt cộng đồng",
    "Cửa hàng tiện lợi",
    "Khu BBQ",
    "Phòng giặt ủi",
    "Điều hòa chung",
    "Thang máy",
    "Khu vườn xanh",
  ];
  List<String> selectedUtilities = ["Điện", "Nước", "Internet"];

  final TextEditingController phoneNumberController = TextEditingController(text: "0987654321"); // phoneNumber

  final TextEditingController idController = TextEditingController(text: "123456789"); // id
  final TextEditingController moveInDateController = TextEditingController(text: "01/01/2020"); // moveInDate
  final TextEditingController moveOutDateController = TextEditingController(text: ""); // moveOutDate
  final TextEditingController statusController = TextEditingController(text: "Đang cư trú"); // status

  @override
  void dispose() {
    // Giải phóng các controller khi widget bị hủy
    householdHeadController.dispose();
    dobController.dispose();
    occupationController.dispose();
    emailController.dispose();
    apartmentNumberController.dispose();
    floorController.dispose();
    // Giải phóng các controller của liên hệ khẩn cấp
    for (var controller in emergencyContactControllers) {
      controller.dispose();
    }
    // Giải phóng các controller của thành viên
    for (var member in members) {
      member.dispose();
    }
    // Giải phóng các controller của phương tiện
    for (var vehicle in vehicles) {
      vehicle.dispose();
    }
    // Giải phóng các controller khác
    idController.dispose();
    moveInDateController.dispose();
    moveOutDateController.dispose();
    statusController.dispose();
    phoneNumberController.dispose();
    super.dispose();
  }

  /// Hàm xử lý khi nhấn nút "Chỉnh sửa" hoặc "Hoàn tất"
  void toggleEdit() {
    if (isEditing) {
      // Kiểm tra dữ liệu trước khi lưu (nếu cần)
      if (householdHeadController.text.trim().isEmpty ||
          dobController.text.trim().isEmpty ||
          occupationController.text.trim().isEmpty ||
          emailController.text.trim().isEmpty ||
          apartmentNumberController.text.trim().isEmpty ||
          floorController.text.trim().isEmpty ||
          idController.text.trim().isEmpty ||
          moveInDateController.text.trim().isEmpty ||
          statusController.text.trim().isEmpty ||
          selectedUtilities.isEmpty || // Kiểm tra tiện ích
          phoneNumberController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vui lòng điền đầy đủ thông tin.')),
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

      // Kiểm tra định dạng số điện thoại chính
      if (!_isValidPhoneNumber(phoneNumberController.text.trim())) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Số điện thoại không hợp lệ. Vui lòng nhập lại.')),
        );
        return;
      }

      // Kiểm tra định dạng số điện thoại trong liên hệ khẩn cấp
      for (var controller in emergencyContactControllers) {
        if (!_isValidPhoneNumber(controller.text.trim())) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Số điện thoại khẩn cấp "${controller.text.trim()}" không hợp lệ. Vui lòng kiểm tra lại.')),
          );
          return;
        }
      }

      // Kiểm tra các thành viên
      for (var member in members) {
        if (member.relation.trim().isEmpty || member.name.trim().isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Vui lòng điền đầy đủ thông tin thành viên.')),
          );
          return;
        }
      }

      // Kiểm tra các phương tiện
      for (var vehicle in vehicles) {
        if (vehicle.type.trim().isEmpty || vehicle.name.trim().isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Vui lòng điền đầy đủ thông tin phương tiện.')),
          );
          return;
        }
      }

      setState(() {
        isEditing = false;
      });

      // Show AlertDialog instead of Snackbar
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
    } else {
      setState(() {
        isEditing = true;
      });
    }
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

  @override
  Widget build(BuildContext context) {
    // Tính toán chiều rộng tối đa của TextField để tránh việc nhãn và dữ liệu bị ngắt dòng
    double screenWidth = MediaQuery.of(context).size.width;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Hồ sơ nhân khẩu',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          // Hàng 1: Chủ hộ và Nghề nghiệp
          Row(
            children: [
              Expanded(
                flex: 2,
                child: _buildInfoField('Chủ hộ:', householdHeadController, 'householdHead'),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: _buildInfoField('Nghề nghiệp:', occupationController, 'occupation'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Hàng 2: Ngày sinh, Email, ID
          Row(
            children: [
              Expanded(
                flex: 2,
                child: _buildInfoField('Ngày sinh:', dobController, 'dob'),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 3,
                child: _buildInfoField('Email:', emailController, 'email'),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 3,
                child: _buildInfoField('ID (CCCD/Passport):', idController, 'id'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // New Row 3: Số điện thoại
          Row(
            children: [
              Expanded(
                flex: 3,
                child: _buildInfoField('Số điện thoại:', phoneNumberController, 'phoneNumber'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Hàng 4: Tầng, Số căn hộ, Trạng thái
          Row(
            children: [
              Expanded(
                flex: 2,
                child: _buildInfoField('Tầng:', floorController, 'floor'),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: _buildInfoField('Số căn hộ:', apartmentNumberController, 'apartmentNumber'),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 4,
                child: _buildInfoField('Trạng thái:', statusController, 'status'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Hàng 5: Ngày vào và Ngày ra dự kiến
          Row(
            children: [
              Expanded(
                flex: 2,
                child: _buildInfoField('Ngày vào:', moveInDateController, 'moveInDate'),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: _buildInfoField('Ngày ra dự kiến:', moveOutDateController, 'moveOutDate'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Hàng 6: Thành viên
          _buildMembersSection(),
          const SizedBox(height: 10),
          // Hàng 7: Liên hệ khẩn cấp
          _buildEmergencyContactsSection(),
          const SizedBox(height: 10),
          // Hàng 8: Phương tiện
          _buildVehiclesSection(),
          const SizedBox(height: 10),
          // Hàng 9: Tiện ích (chuyển đổi thành bảng 3x5 selection)
          _buildUtilitiesSection(),
          const SizedBox(height: 10),
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
    );
  }

  /// Xây dựng phần tiện ích dưới dạng bảng 3x5 với Checkbox và Text
  Widget _buildUtilitiesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Nhãn thông tin
        const Text(
          'Tiện ích:',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        // Bảng 3x5 của các tiện ích
        GridView.count(
          crossAxisCount: 5, // 5 columns
          mainAxisSpacing: 4.0,
          crossAxisSpacing: 4.0,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 3, // Adjusted for better appearance
          children: predefinedUtilities.map((utility) {
            final bool isSelected = selectedUtilities.contains(utility);
            return Row(
              children: [
                // Checkbox on the left
                Checkbox(
                  value: isSelected,
                  onChanged: isEditing
                      ? (bool? selected) {
                          setState(() {
                            if (selected == true) {
                              selectedUtilities.add(utility);
                            } else {
                              selectedUtilities.remove(utility);
                            }
                          });
                        }
                      : null,
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                // Text label
                Expanded(
                  child: Text(
                    utility,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 12,
                    ),
                    overflow: TextOverflow.ellipsis, // Prevent overflow
                  ),
                ),
              ],
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
        // Nếu không có tiện ích, hiển thị thông báo
        if (selectedUtilities.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              'Chưa có tiện ích nào được chọn.',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
      ],
    );
  }

  /// Xây dựng một trường thông tin với nhãn và TextField hoặc các widget khác
  Widget _buildInfoField(String label, TextEditingController controller, String fieldName) {
    // Định nghĩa màu border dựa trên trạng thái chỉnh sửa
    Color borderColor = isEditing ? Colors.black : Colors.grey;

    // Kiểm tra nếu trường là 'status' thì sử dụng DropdownButtonFormField
    if (fieldName == 'status') {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Nhãn thông tin
          Container(
            width: 160, // Độ rộng tăng lên để không bị ngắt dòng
            padding: const EdgeInsets.only(top: 12.0),
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ),
          // DropdownButton dữ liệu
          Flexible(
            fit: FlexFit.loose,
            child: DropdownButtonFormField<String>(
              value: statusController.text.trim(),
              items: const [
                DropdownMenuItem(
                  value: 'Đang cư trú',
                  child: Text('Đang cư trú'),
                ),
                DropdownMenuItem(
                  value: 'Tạm vắng',
                  child: Text('Tạm vắng'),
                ),
                DropdownMenuItem(
                  value: 'Đã chuyển đi',
                  child: Text('Đã chuyển đi'),
                ),
              ],
              onChanged: isEditing
                  ? (value) {
                      setState(() {
                        statusController.text = value ?? 'Đang cư trú';
                      });
                    }
                  : null,
              decoration: InputDecoration(
                labelText: 'Trạng thái',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: isEditing ? Colors.black : Colors.grey),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: isEditing ? Colors.black : Colors.grey),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: isEditing ? Colors.black : Colors.grey, width: 2),
                ),
                // Add disabledBorder to ensure gray border when not editing
                disabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.grey),
                ),
              ),
            ),
          ),
        ],
      );
    }

    // Kiểm tra nếu trường là ngày, sử dụng DatePicker
    if (fieldName == 'dob' || fieldName == 'moveInDate' || fieldName == 'moveOutDate') {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Nhãn thông tin
          Container(
            width: 160, // Độ rộng tăng lên để không bị ngắt dòng
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
              onTap: isEditing
                  ? () async {
                      DateTime initialDate = _isValidDate(controller.text.trim()) ? _convertStringToDate(controller.text.trim()) : DateTime.now();
                      DateTime? pickedDate = await showDatePicker(
                        context: context,
                        initialDate: initialDate,
                        firstDate: DateTime(1900),
                        lastDate: DateTime.now(),
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
                    color: isEditing ? Colors.black : Colors.grey, // Màu chữ thay đổi theo trạng thái
                  ),
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: borderColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: borderColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: borderColor, width: 2),
                    ),
                    isDense: true, // Giảm kích thước của TextField
                    contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                    suffixIcon: isEditing ? const Icon(Icons.calendar_today) : null, // Hiển thị biểu tượng lịch nếu đang chỉnh sửa
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
          width: 160, // Độ rộng tăng lên để không bị ngắt dòng
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
            readOnly: !isEditing, // Vô hiệu hóa khi không chỉnh sửa
            style: TextStyle(
              color: isEditing ? Colors.black : Colors.grey, // Màu chữ thay đổi theo trạng thái
            ),
            maxLines: fieldName == 'utilities' || fieldName == 'phoneNumber' ? null : 1, // Cho phép nhiều dòng cho các trường phức tạp
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: borderColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: borderColor, width: 2),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Xây dựng phần thành viên
  Widget _buildMembersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Thành viên:',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        const SizedBox(height: 8),
        Column(
          children: members
              .asMap()
              .entries
              .map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: members[entry.key].relationController,
                          enabled: isEditing,
                          decoration: InputDecoration(
                            labelText: 'Quan hệ',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: isEditing ? Colors.black : Colors.grey),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: isEditing ? Colors.black : Colors.grey),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: isEditing ? Colors.black : Colors.grey, width: 2),
                            ),
                          ),
                          onChanged: (value) {
                            members[entry.key].relation = value;
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 3,
                        child: TextField(
                          controller: members[entry.key].nameController,
                          enabled: isEditing,
                          decoration: InputDecoration(
                            labelText: 'Tên',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: isEditing ? Colors.black : Colors.grey),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: isEditing ? Colors.black : Colors.grey),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: isEditing ? Colors.black : Colors.grey, width: 2),
                            ),
                          ),
                          onChanged: (value) {
                            members[entry.key].name = value;
                          },
                        ),
                      ),
                      if (isEditing)
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            setState(() {
                              members[entry.key].dispose();
                              members.removeAt(entry.key);
                            });
                          },
                        ),
                    ],
                  ),
                ),
              )
              .toList(),
        ),
        if (isEditing)
          TextButton.icon(
            onPressed: () {
              setState(() {
                members.add(Member());
              });
            },
            icon: const Icon(Icons.add),
            label: const Text('Thêm thành viên'),
          ),
      ],
    );
  }

  /// Xây dựng phần liên hệ khẩn cấp
  Widget _buildEmergencyContactsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Liên hệ khẩn cấp:',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        const SizedBox(height: 8),
        Column(
          children: emergencyContactControllers
              .asMap()
              .entries
              .map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: emergencyContactControllers[entry.key],
                          enabled: isEditing,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: isEditing ? Colors.black : Colors.grey),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: isEditing ? Colors.black : Colors.grey),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: isEditing ? Colors.black : Colors.grey, width: 2),
                            ),
                          ),
                        ),
                      ),
                      if (isEditing)
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            setState(() {
                              emergencyContactControllers[entry.key].dispose();
                              emergencyContactControllers.removeAt(entry.key);
                            });
                          },
                        ),
                    ],
                  ),
                ),
              )
              .toList(),
        ),
        if (isEditing)
          TextButton.icon(
            onPressed: () {
              setState(() {
                emergencyContactControllers.add(TextEditingController());
              });
            },
            icon: const Icon(Icons.add),
            label: const Text('Thêm liên hệ khẩn cấp'),
          ),
      ],
    );
  }

  /// Xây dựng phần phương tiện
  Widget _buildVehiclesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Phương tiện:',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        const SizedBox(height: 8),
        Column(
          children: vehicles
              .asMap()
              .entries
              .map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: DropdownButtonFormField<String>(
                          value: vehicles[entry.key].type,
                          items: const [
                            DropdownMenuItem(
                              value: 'Ô tô',
                              child: Text('Ô tô'),
                            ),
                            DropdownMenuItem(
                              value: 'Xe máy',
                              child: Text('Xe máy'),
                            ),
                            DropdownMenuItem(
                              value: 'Xe đạp',
                              child: Text('Xe đạp'),
                            ),
                            DropdownMenuItem(
                              value: 'Xe máy điện',
                              child: Text('Xe máy điện'),
                            ),
                            DropdownMenuItem(
                              value: 'Xe đạp điện',
                              child: Text('Xe đạp điện'),
                            ),
                            DropdownMenuItem(
                              value: 'Ngựa',
                              child: Text('Ngựa'),
                            ),
                            // Thêm các loại phương tiện khác nếu cần
                          ],
                          onChanged: isEditing
                              ? (value) {
                                  setState(() {
                                    vehicles[entry.key].type = value ?? 'Ô tô';
                                  });
                                }
                              : null,
                          decoration: InputDecoration(
                            labelText: 'Loại phương tiện',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: isEditing ? Colors.black : Colors.grey),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: isEditing ? Colors.black : Colors.grey),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: isEditing ? Colors.black : Colors.grey, width: 2),
                            ),
                            // Add disabledBorder to ensure gray border when not editing
                            disabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Colors.grey),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 3,
                        child: TextField(
                          controller: vehicles[entry.key].nameController,
                          enabled: isEditing,
                          decoration: InputDecoration(
                            labelText: 'Tên',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: isEditing ? Colors.black : Colors.grey),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: isEditing ? Colors.black : Colors.grey),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: isEditing ? Colors.black : Colors.grey, width: 2),
                            ),
                          ),
                          onChanged: (value) {
                            vehicles[entry.key].name = value;
                          },
                        ),
                      ),
                      if (isEditing)
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            setState(() {
                              vehicles[entry.key].dispose();
                              vehicles.removeAt(entry.key);
                            });
                          },
                        ),
                    ],
                  ),
                ),
              )
              .toList(),
        ),
        if (isEditing)
          TextButton.icon(
            onPressed: () {
              setState(() {
                vehicles.add(Vehicle());
              });
            },
            icon: const Icon(Icons.add),
            label: const Text('Thêm phương tiện'),
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
}
