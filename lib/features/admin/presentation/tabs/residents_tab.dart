// lib/features/admin/presentation/tabs/residents_tab.dart
import 'package:flutter/material.dart';
import '../../data/admin_repository.dart';
import 'package:intl/intl.dart';
import 'dart:math';

class ResidentsTab extends StatefulWidget {
  final AdminRepository adminRepository;
  final String idToken;

  const ResidentsTab({
    super.key,
    required this.adminRepository,
    required this.idToken,
  });

  @override
  _ResidentsTabState createState() => _ResidentsTabState();
}

class _ResidentsTabState extends State<ResidentsTab> {
  List<dynamic> residentsList = [];
  List<dynamic> filteredResidents = [];
  bool isLoadingResidents = false;

  // State variables for sorting and filtering
  String? sortCriteria;
  String? filterCriteria;
  String filterValue = '';

  // Variables for room selection
  int selectedFloor = 1; // Default floor
  final int totalFloors = 10;
  final int roomsPerFloor = 20;

  // Selected room info
  Map<String, dynamic>? selectedRoomInfo;

  // Fake data generator (có thể bỏ nếu không cần)
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    fetchResidents();
  }

  @override
  void dispose() {
    super.dispose();
  }

  // Fetch residents from the repository
  Future<void> fetchResidents() async {
    setState(() {
      isLoadingResidents = true;
    });

    try {
      List<dynamic> fetchedResidents = await widget.adminRepository.fetchResidents(widget.idToken);
      if (!mounted) return;
      setState(() {
        residentsList = fetchedResidents;
        filteredResidents = residentsList;
        isLoadingResidents = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isLoadingResidents = false;
      });
      print('Error fetching residents: $e');
    }
  }

  // Format date of birth
  String formatDob(String dobString) {
    try {
      DateFormat inputFormat = DateFormat('dd/MM/yyyy');
      DateTime date = inputFormat.parse(dobString);
      return DateFormat('dd/MM/yyyy').format(date);
    } catch (e) {
      return dobString;
    }
  }

  // Sort residents based on criteria
  void sortResidents(String criteria) {
    setState(() {
      sortCriteria = criteria;
      filteredResidents.sort((a, b) {
        final aFields = a['fields'];
        final bFields = b['fields'];
        switch (criteria) {
          case 'floor':
            return aFields['floor']['integerValue'].compareTo(bFields['floor']['integerValue']);
          case 'apartmentNumber':
            return aFields['apartmentNumber']['integerValue'].compareTo(bFields['apartmentNumber']['integerValue']);
          case 'fullName':
            return aFields['fullName']['stringValue'].compareTo(bFields['fullName']['stringValue']);
          default:
            return 0;
        }
      });
    });
  }

  // Filter residents based on criteria and value
  void filterResidents(String criteria, String value) {
    setState(() {
      filterCriteria = criteria;
      filterValue = value.toLowerCase();

      filteredResidents = residentsList.where((resident) {
        final fields = resident['fields'];
        switch (criteria) {
          case 'floor':
            return fields['floor']['integerValue'].toString() == value;
          case 'apartmentNumber':
            return fields['apartmentNumber']['integerValue'].toString() == value;
          case 'fullName':
            return fields['fullName']['stringValue'].toLowerCase().contains(value);
          default:
            return true;
        }
      }).toList();

      // Reapply sorting if applicable
      if (sortCriteria != null) {
        sortResidents(sortCriteria!);
      }
    });
  }

  // Build sort dropdown
  Widget buildSortDropdown() {
    return DropdownButton<String>(
      hint: const Text('Sắp xếp'),
      value: sortCriteria,
      onChanged: (String? newValue) {
        setState(() {
          sortCriteria = newValue;
          if (newValue != null) {
            sortResidents(newValue);
          }
        });
      },
      items: <DropdownMenuItem<String>>[
        DropdownMenuItem(
          value: 'floor',
          child: const Text('Tầng'),
        ),
        DropdownMenuItem(
          value: 'apartmentNumber',
          child: const Text('Số căn hộ'),
        ),
        DropdownMenuItem(
          value: 'fullName',
          child: const Text('Tên'),
        ),
      ],
    );
  }

  // Build filter dropdown
  Widget buildFilterDropdown() {
    return Row(
      children: [
        DropdownButton<String>(
          hint: const Text('Lọc'),
          value: filterCriteria,
          onChanged: (String? newValue) {
            if (newValue != null) {
              _showFilterValueInput(newValue);
            }
          },
          items: <DropdownMenuItem<String>>[
            DropdownMenuItem(
              value: 'floor',
              child: const Text('Tầng'),
            ),
            DropdownMenuItem(
              value: 'apartmentNumber',
              child: const Text('Số căn hộ'),
            ),
            DropdownMenuItem(
              value: 'fullName',
              child: const Text('Họ và Tên'),
            ),
          ],
        ),
        if (filterCriteria != null && filterValue.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: Text(getFilterDisplayText(filterCriteria!, filterValue) ?? ''),
          ),
      ],
    );
  }

  // Get display text for filter
  String? getFilterDisplayText(String criteria, String value) {
    if (value.isEmpty) return null;
    switch (criteria) {
      case 'floor':
        return 'Tầng $value';
      case 'apartmentNumber':
        return 'Căn hộ $value';
      case 'fullName':
        return 'Tên "$value"';
      default:
        return null;
    }
  }

  // Show dialog to input filter value
  void _showFilterValueInput(String criteria) {
    String inputValue = '';
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Nhập giá trị lọc cho ${getCriteriaDisplayText(criteria)}'),
          content: TextField(
            decoration: const InputDecoration(
              labelText: 'Giá trị',
            ),
            onChanged: (value) {
              inputValue = value;
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () {
                if (inputValue.isNotEmpty) {
                  Navigator.of(context).pop();
                  setState(() {
                    filterCriteria = criteria;
                    filterValue = inputValue;
                    filterResidents(criteria, inputValue);
                  });
                }
              },
              child: const Text('Áp dụng'),
            ),
          ],
        );
      },
    );
  }

  // Helper to get display text for criteria
  String getCriteriaDisplayText(String criteria) {
    switch (criteria) {
      case 'floor':
        return 'Tầng';
      case 'apartmentNumber':
        return 'Số căn hộ';
      case 'fullName':
        return 'Họ và Tên';
      default:
        return '';
    }
  }

  // Reset filters and sorting
  void resetFiltersAndSorting() {
    setState(() {
      sortCriteria = null;
      filterCriteria = null;
      filterValue = '';
      filteredResidents = residentsList;
    });
  }

  // Build floor selection dropdown
  Widget buildFloorDropdown() {
    return DropdownButton<int>(
      hint: const Text('Tầng'),
      value: selectedFloor,
      onChanged: (int? newValue) {
        setState(() {
          selectedFloor = newValue!;
          // Reset selected room info when floor changes
          selectedRoomInfo = null;
        });
      },
      items: List<DropdownMenuItem<int>>.generate(
        totalFloors,
        (index) => DropdownMenuItem(
          value: index + 1,
          child: Text('Tầng ${index + 1}'),
        ),
      ),
    );
  }

  // Display floor selection and room squares
  Widget buildRoomSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Floor selection dropdown
        buildFloorDropdown(),
        const SizedBox(height: 10),
        // Room squares
        Expanded(
          flex: 3,
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 10,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1,
            ),
            itemCount: roomsPerFloor,
            itemBuilder: (context, index) {
              int roomNumber = index + 1;
              String roomNumberStr = roomNumber < 10 ? '0$roomNumber' : '$roomNumber';
              return GestureDetector(
                onTap: () {
                  _showResidentInfo(roomNumber);
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.blueAccent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      roomNumberStr,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        // Display selected room info
        if (selectedRoomInfo != null)
          Expanded(
            flex: 2,
            child: SingleChildScrollView(
              child: buildResidentInfoCard(selectedRoomInfo!),
            ),
          ),
      ],
    );
  }

  // Show resident information (updates the state to display below the grid)
  void _showResidentInfo(int roomNumber) {
    // Tìm cư dân trong danh sách dựa trên tầng và số căn hộ
    final resident = residentsList.firstWhere(
      (resident) => resident['fields']['floor']['integerValue'] == selectedFloor && resident['fields']['apartmentNumber']['integerValue'] == roomNumber,
      orElse: () => null,
    );

    if (resident != null) {
      setState(() {
        selectedRoomInfo = resident['fields'];
        print('Selected Resident Info: $selectedRoomInfo'); // Thêm dòng này để kiểm tra
      });
    } else {
      // Xử lý khi không tìm thấy cư dân trong phòng
      setState(() {
        selectedRoomInfo = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không tìm thấy cư dân trong căn hộ này.')),
      );
    }
  }

  // Build resident info card
  // Build resident info card
  Widget buildResidentInfoCard(Map<String, dynamic> info) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Thông tin căn hộ ${info['apartmentNumber'] != null && info['apartmentNumber']['integerValue'] != null ? info['apartmentNumber']['integerValue'].toString() : ''}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text('Họ và Tên: ${info['fullName'] != null && info['fullName']['stringValue'] != null ? info['fullName']['stringValue'] : ''}'),
            Text('Giới tính: ${info['gender'] != null && info['gender']['stringValue'] != null ? info['gender']['stringValue'] : ''}'),
            Text('Ngày sinh: ${info['dob'] != null && info['dob']['stringValue'] != null ? formatDob(info['dob']['stringValue']) : ''}'),
            Text('Số điện thoại: ${info['phone'] != null && info['phone']['stringValue'] != null ? info['phone']['stringValue'] : ''}'),
            Text('Số ID: ${info['id'] != null && info['id']['stringValue'] != null ? info['id']['stringValue'] : ''}'),
            Text('Email: ${info['email'] != null && info['email']['stringValue'] != null ? info['email']['stringValue'] : ''}'),
            Text('Tầng: ${info['floor'] != null && info['floor']['integerValue'] != null ? info['floor']['integerValue'].toString() : ''}'),
            Text('Căn hộ số: ${info['apartmentNumber'] != null && info['apartmentNumber']['integerValue'] != null ? info['apartmentNumber']['integerValue'].toString() : ''}'),
            Text('Trạng thái: ${info['status'] ?? ''}'),
          ],
        ),
      ),
    );
  }

  // Build residents list with edit and delete functionality
  Widget buildResidentsList() {
    return filteredResidents.isEmpty
        ? const Center(
            child: Text('Không có kết quả phù hợp với tiêu chí lọc.'),
          )
        : ListView.builder(
            itemCount: filteredResidents.length,
            itemBuilder: (context, index) {
              final doc = filteredResidents[index];
              final fields = doc['fields'];
              return ResidentListItem(
                resident: fields,
                onUpdate: (updatedFields) {
                  setState(() {
                    residentsList[index]['fields'] = updatedFields;
                    // Reapply filter and sort if necessary
                    if (filterCriteria != null && filterValue.isNotEmpty) {
                      filterResidents(filterCriteria!, filterValue);
                    }
                    if (sortCriteria != null) {
                      sortResidents(sortCriteria!);
                    }
                  });
                },
                onDelete: () {
                  setState(() {
                    residentsList.removeAt(index);
                    // Reapply filter and sort if necessary
                    if (filterCriteria != null && filterValue.isNotEmpty) {
                      filterResidents(filterCriteria!, filterValue);
                    }
                    if (sortCriteria != null) {
                      sortResidents(sortCriteria!);
                    }
                  });
                },
              );
            },
          );
  }

  @override
  Widget build(BuildContext context) {
    // Use LayoutBuilder to adjust layout based on screen size
    return LayoutBuilder(
      builder: (context, constraints) {
        bool isWideScreen = constraints.maxWidth >= 800; // Define breakpoint
        return isLoadingResidents
            ? const Center(child: CircularProgressIndicator())
            : Row(
                children: [
                  // Left Column: Residents List
                  Expanded(
                    flex: 1,
                    child: Container(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        children: [
                          // Sort and Filter Dropdowns
                          Row(
                            children: [
                              buildSortDropdown(),
                              const SizedBox(width: 10),
                              buildFilterDropdown(),
                              const Spacer(),
                              // Reset Filters and Sorting Button
                              if (filterCriteria != null || sortCriteria != null)
                                IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: resetFiltersAndSorting,
                                  tooltip: 'Đặt lại bộ lọc và sắp xếp',
                                ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          // Residents List
                          Expanded(
                            child: buildResidentsList(),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Vertical Divider
                  if (isWideScreen)
                    const VerticalDivider(
                      width: 1,
                      thickness: 1,
                      color: Colors.grey,
                    ),
                  // Right Column: Room Selection
                  Expanded(
                    flex: 1,
                    child: Container(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        children: [
                          const Text(
                            'Chọn phòng',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 10),
                          Expanded(
                            child: buildRoomSelection(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
      },
    );
  }
}

// Widget for individual resident list item with edit and delete functionality
// Widget for individual resident list item with edit and delete functionality
// Widget for individual resident list item with edit and delete functionality
class ResidentListItem extends StatefulWidget {
  final Map<String, dynamic> resident;
  final Function(Map<String, dynamic>) onUpdate;
  final Function onDelete;

  const ResidentListItem({
    Key? key,
    required this.resident,
    required this.onUpdate,
    required this.onDelete,
  }) : super(key: key);

  @override
  _ResidentListItemState createState() => _ResidentListItemState();
}

class _ResidentListItemState extends State<ResidentListItem> {
  bool isEditing = false;

  // Controllers for editable fields
  late TextEditingController fullNameController;
  late TextEditingController genderController;
  late TextEditingController dobController;
  late TextEditingController phoneController;
  late TextEditingController idController;
  late TextEditingController emailController;
  late TextEditingController floorController;
  late TextEditingController apartmentNumberController;

  @override
  void initState() {
    super.initState();
    // Kiểm tra xem 'stringValue' có tồn tại hay không trước khi truy cập
    fullNameController = TextEditingController(
      text: widget.resident['fullName'] != null && widget.resident['fullName']['stringValue'] != null ? widget.resident['fullName']['stringValue'] : '',
    );
    genderController = TextEditingController(
      text: widget.resident['gender'] != null && widget.resident['gender']['stringValue'] != null ? widget.resident['gender']['stringValue'] : '',
    );
    dobController = TextEditingController(
      text: widget.resident['dob'] != null && widget.resident['dob']['stringValue'] != null ? widget.resident['dob']['stringValue'] : '',
    );
    phoneController = TextEditingController(
      text: widget.resident['phone'] != null && widget.resident['phone']['stringValue'] != null ? widget.resident['phone']['stringValue'] : '',
    );
    idController = TextEditingController(
      text: widget.resident['id'] != null && widget.resident['id']['stringValue'] != null ? widget.resident['id']['stringValue'] : '',
    );
    emailController = TextEditingController(
      text: widget.resident['email'] != null && widget.resident['email']['stringValue'] != null ? widget.resident['email']['stringValue'] : '',
    );
    floorController = TextEditingController(
      text: widget.resident['floor'] != null && widget.resident['floor']['integerValue'] != null ? widget.resident['floor']['integerValue'].toString() : '',
    );
    apartmentNumberController = TextEditingController(
      text: widget.resident['apartmentNumber'] != null && widget.resident['apartmentNumber']['integerValue'] != null ? widget.resident['apartmentNumber']['integerValue'].toString() : '',
    );
  }

  @override
  void dispose() {
    fullNameController.dispose();
    genderController.dispose();
    dobController.dispose();
    phoneController.dispose();
    idController.dispose();
    emailController.dispose();
    floorController.dispose();
    apartmentNumberController.dispose();
    super.dispose();
  }

  // Save changes and update the resident
  void saveChanges() {
    String updatedFullName = fullNameController.text.trim();
    String updatedGender = genderController.text.trim();
    String updatedDob = dobController.text.trim();
    String updatedPhone = phoneController.text.trim();
    String updatedId = idController.text.trim();
    String updatedEmail = emailController.text.trim();
    String updatedFloor = floorController.text.trim();
    String updatedApartmentNumber = apartmentNumberController.text.trim();

    if (updatedFullName.isEmpty || updatedGender.isEmpty || updatedDob.isEmpty || updatedPhone.isEmpty || updatedId.isEmpty || updatedEmail.isEmpty || updatedFloor.isEmpty || updatedApartmentNumber.isEmpty) {
      // Show a snackbar or some feedback
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng điền đầy đủ thông tin.')),
      );
      return;
    }

    // Update resident data
    Map<String, dynamic> updatedFields = {
      'fullName': {'stringValue': updatedFullName},
      'gender': {'stringValue': updatedGender},
      'dob': {'stringValue': updatedDob},
      'phone': {'stringValue': updatedPhone},
      'id': {'stringValue': updatedId},
      'email': {'stringValue': updatedEmail},
      'floor': {'integerValue': int.parse(updatedFloor)},
      'apartmentNumber': {'integerValue': int.parse(updatedApartmentNumber)},
      // Retain other fields if necessary
      ...widget.resident..removeWhere((key, value) => ['fullName', 'gender', 'dob', 'phone', 'id', 'email', 'floor', 'apartmentNumber'].contains(key)),
    };

    widget.onUpdate(updatedFields);

    setState(() {
      isEditing = false;
    });

    // Optional: Show a success message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Lưu thay đổi thành công.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: isEditing
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Main Info: Họ và Tên, Tầng, Số căn hộ
                  Row(
                    children: [
                      // Họ và Tên
                      Expanded(
                        flex: 3,
                        child: Text(
                          widget.resident['fullName'] != null && widget.resident['fullName']['stringValue'] != null ? widget.resident['fullName']['stringValue'] : '',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                      // Tầng
                      Expanded(
                        flex: 1,
                        child: Text(
                          widget.resident['floor'] != null && widget.resident['floor']['integerValue'] != null ? widget.resident['floor']['integerValue'].toString() : '',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                      // Số căn hộ
                      Expanded(
                        flex: 1,
                        child: Text(
                          widget.resident['apartmentNumber'] != null && widget.resident['apartmentNumber']['integerValue'] != null ? widget.resident['apartmentNumber']['integerValue'].toString() : '',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                      // Edit and Delete Icons
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () {
                          // Do nothing hoặc có thể thêm logic nếu cần
                        },
                        tooltip: 'Chỉnh sửa',
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          // Confirm deletion
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: const Text('Xác nhận xóa'),
                                content: const Text('Bạn có chắc chắn muốn xóa cư dân này?'),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                    child: const Text('Hủy'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () {
                                      widget.onDelete();
                                      Navigator.of(context).pop();
                                    },
                                    child: const Text('Xóa'),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                        tooltip: 'Xóa',
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Additional Info Fields
                  TextField(
                    controller: genderController,
                    decoration: const InputDecoration(
                      labelText: 'Giới tính',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: dobController,
                    decoration: const InputDecoration(
                      labelText: 'Ngày sinh (dd/MM/yyyy)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: phoneController,
                    decoration: const InputDecoration(
                      labelText: 'Số điện thoại',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: idController,
                    decoration: const InputDecoration(
                      labelText: 'Số ID',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: floorController,
                    decoration: const InputDecoration(
                      labelText: 'Tầng',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: apartmentNumberController,
                    decoration: const InputDecoration(
                      labelText: 'Số căn hộ',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 10),
                  // Save Changes Button
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      onPressed: saveChanges,
                      child: const Text('Lưu thay đổi'),
                    ),
                  ),
                ],
              )
            : Row(
                children: [
                  // Họ và Tên
                  Expanded(
                    flex: 3,
                    child: Text(
                      widget.resident['fullName'] != null && widget.resident['fullName']['stringValue'] != null ? widget.resident['fullName']['stringValue'] : '',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                  // Tầng
                  Expanded(
                    flex: 1,
                    child: Text(
                      widget.resident['floor'] != null && widget.resident['floor']['integerValue'] != null ? widget.resident['floor']['integerValue'].toString() : '',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                  // Số căn hộ
                  Expanded(
                    flex: 1,
                    child: Text(
                      widget.resident['apartmentNumber'] != null && widget.resident['apartmentNumber']['integerValue'] != null ? widget.resident['apartmentNumber']['integerValue'].toString() : '',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                  // Edit and Delete Icons
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: () {
                      setState(() {
                        isEditing = true;
                      });
                    },
                    tooltip: 'Chỉnh sửa',
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      // Confirm deletion
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text('Xác nhận xóa'),
                            content: const Text('Bạn có chắc chắn muốn xóa cư dân này?'),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                                child: const Text('Hủy'),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  widget.onDelete();
                                  Navigator.of(context).pop();
                                },
                                child: const Text('Xóa'),
                              ),
                            ],
                          );
                        },
                      );
                    },
                    tooltip: 'Xóa',
                  ),
                ],
              ),
      ),
    );
  }
}
