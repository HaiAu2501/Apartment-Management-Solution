// lib/features/admin/presentation/tabs/residents_tab.dart
import 'package:flutter/material.dart';
import '../../data/admin_repository.dart';
import 'package:intl/intl.dart';

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
  List<Map<String, dynamic>> residentsList = [];
  List<Map<String, dynamic>> filteredResidents = [];
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

  // Variables for profile information
  Map<String, dynamic>? selectedProfileInfo;
  bool isLoadingProfile = false;

  // Variables for additional information table
  bool isAdditionalInfoVisible = false;
  List<Map<String, dynamic>> additionalInfoList = [];

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
      print('Fetched Residents: $fetchedResidents'); // Debug

      // Ensure fetchedResidents is a list of maps with 'name' and 'fields'
      List<Map<String, dynamic>> parsedResidents = fetchedResidents.whereType<Map<String, dynamic>>().toList();
      print('Parsed Residents: $parsedResidents'); // Debug

      if (!mounted) return;

      setState(() {
        residentsList = parsedResidents;
        filteredResidents = residentsList;
        isLoadingResidents = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isLoadingResidents = false;
      });
      print('Error fetching residents: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi tải danh sách cư dân: $e')),
      );
    }
  }

  // Format date of birth
  String formatDob(String dobString) {
    try {
      DateFormat inputFormat = DateFormat('dd/MM/yyyy');
      DateTime date = inputFormat.parse(dobString);
      return DateFormat('dd/MM/yyyy').format(date);
    } catch (e) {
      print('Error formatting DOB: $e');
      return dobString;
    }
  }

  // Sort residents based on criteria
  void sortResidents(String criteria) {
    setState(() {
      sortCriteria = criteria;
      filteredResidents.sort((a, b) {
        final aFields = a['fields'] ?? {};
        final bFields = b['fields'] ?? {};

        switch (criteria) {
          case 'floor':
            return _getIntegerValue(aFields, 'floor').compareTo(_getIntegerValue(bFields, 'floor'));
          case 'apartmentNumber':
            return _getIntegerValue(aFields, 'apartmentNumber').compareTo(_getIntegerValue(bFields, 'apartmentNumber'));
          case 'fullName':
            return _getStringValue(aFields, 'fullName').compareTo(_getStringValue(bFields, 'fullName'));
          default:
            return 0;
        }
      });
    });
  }

  // Helper to safely get integer values
  int _getIntegerValue(Map<String, dynamic> fields, String key) {
    try {
      if (fields.containsKey(key) && fields[key].containsKey('integerValue')) {
        return int.parse(fields[key]['integerValue'].toString());
      } else {
        print('Missing integerValue for key: $key');
        return 0;
      }
    } catch (e) {
      print('Error parsing integerValue for key: $key, error: $e');
      return 0;
    }
  }

  // Helper to safely get string values
  String _getStringValue(Map<String, dynamic> fields, String key) {
    try {
      if (fields.containsKey(key) && fields[key].containsKey('stringValue')) {
        return fields[key]['stringValue'];
      } else {
        print('Missing stringValue for key: $key');
        return '';
      }
    } catch (e) {
      print('Error parsing stringValue for key: $key, error: $e');
      return '';
    }
  }

  // Filter residents based on criteria and value
  void filterResidents(String criteria, String value) {
    setState(() {
      filterCriteria = criteria;
      filterValue = value.toLowerCase();

      filteredResidents = residentsList.where((resident) {
        final fields = resident['fields'] ?? {};

        switch (criteria) {
          case 'floor':
            int? floorValue = int.tryParse(value);
            return floorValue != null && _getIntegerValue(fields, 'floor') == floorValue;
          case 'apartmentNumber':
            int? aptValue = int.tryParse(value);
            return aptValue != null && _getIntegerValue(fields, 'apartmentNumber') == aptValue;
          case 'fullName':
            return _getStringValue(fields, 'fullName').toLowerCase().contains(value);
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

  // Build sort popup menu with icon and text
  Widget buildSortPopupMenu() {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.sort),
      onSelected: (String value) {
        sortResidents(value);
      },
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        const PopupMenuItem<String>(
          value: 'floor',
          child: Text('Tầng'),
        ),
        const PopupMenuItem<String>(
          value: 'apartmentNumber',
          child: Text('Số căn hộ'),
        ),
        const PopupMenuItem<String>(
          value: 'fullName',
          child: Text('Tên'),
        ),
      ],
      tooltip: 'Sắp xếp',
    );
  }

  // Build filter popup menu with icon and text
  Widget buildFilterPopupMenu() {
    return Row(
      children: [
        PopupMenuButton<String>(
          icon: const Icon(Icons.filter_list),
          onSelected: (String criteria) {
            _showFilterValueInput(criteria);
          },
          itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
            const PopupMenuItem<String>(
              value: 'floor',
              child: Text('Tầng'),
            ),
            const PopupMenuItem<String>(
              value: 'apartmentNumber',
              child: Text('Số căn hộ'),
            ),
            const PopupMenuItem<String>(
              value: 'fullName',
              child: Text('Họ và Tên'),
            ),
          ],
          tooltip: 'Lọc',
        ),
        if (filterCriteria != null && filterValue.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: Text(
              getFilterDisplayText(filterCriteria!, filterValue) ?? '',
              style: const TextStyle(fontStyle: FontStyle.italic),
            ),
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
                  filterResidents(criteria, inputValue);
                } else {
                  // Optionally, show a warning if input is empty
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Giá trị không được để trống.')),
                  );
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

  // Build floor selection popup menu with icon, text, and display selected floor
  Widget buildFloorPopupMenu() {
    return Row(
      children: [
        PopupMenuButton<int>(
          icon: const Icon(Icons.layers),
          onSelected: (int floor) {
            setState(() {
              selectedFloor = floor;
              // Reset selected room info and profile info when floor changes
              selectedRoomInfo = null;
              selectedProfileInfo = null;
              isAdditionalInfoVisible = false;
            });
          },
          itemBuilder: (BuildContext context) => List<PopupMenuEntry<int>>.generate(
            totalFloors,
            (index) => PopupMenuItem<int>(
              value: index + 1,
              child: Text('Tầng ${index + 1}'),
            ),
          ),
          tooltip: 'Chọn tầng',
        ),
        const SizedBox(width: 8),
        Text(
          'Tầng $selectedFloor',
          style: const TextStyle(fontSize: 16),
        ),
      ],
    );
  }

  // Display floor selection and room squares
  Widget buildRoomSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Floor selection popup menu with text
        buildFloorPopupMenu(),
        const SizedBox(height: 10),
        // Room squares
        Expanded(
          flex: 3,
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 10, // Adjusted for better UI
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1, // Square cells
            ),
            itemCount: roomsPerFloor,
            itemBuilder: (context, index) {
              int roomNumber = index + 1;
              String roomNumberStr = roomNumber < 10 ? '0$roomNumber' : '$roomNumber';
              bool isOccupied = residentsList.any((resident) {
                final fields = resident['fields'] ?? {};
                return _getIntegerValue(fields, 'floor') == selectedFloor && _getIntegerValue(fields, 'apartmentNumber') == roomNumber;
              });

              return GestureDetector(
                onTap: () {
                  _showResidentInfo(roomNumber);
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: isOccupied ? Colors.greenAccent : Colors.blueAccent,
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
        // Display selected room info
        if (selectedRoomInfo != null || selectedProfileInfo != null)
          Flexible(
            flex: 10,
            child: SingleChildScrollView(
              child: buildResidentInfoCard(),
            ),
          ),
      ],
    );
  }

  // Show resident information (updates the state to display below the grid)
  Future<void> _showResidentInfo(int roomNumber) async {
    print('Selected Floor: $selectedFloor, Room Number: $roomNumber');
    Map<String, dynamic>? resident;
    try {
      resident = residentsList.firstWhere((resident) {
        final fields = resident['fields'] ?? {};
        int residentFloor = _getIntegerValue(fields, 'floor');
        int residentRoom = _getIntegerValue(fields, 'apartmentNumber');
        print('Checking Resident - Floor: $residentFloor, Room: $residentRoom');
        return residentFloor == selectedFloor && residentRoom == roomNumber;
      });
    } catch (e) {
      resident = null;
    }

    if (resident != null) {
      final fields = resident['fields'];
      if (fields != null) {
        String profileId = _getStringValue(fields, 'profileId');
        setState(() {
          selectedRoomInfo = Map<String, dynamic>.from(fields);
          isAdditionalInfoVisible = false; // Reset additional info visibility
        });
        if (profileId.isNotEmpty) {
          await fetchProfile(profileId);
        } else {
          setState(() {
            selectedProfileInfo = null;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Không tìm thấy profileId.')),
          );
        }
      } else {
        setState(() {
          selectedRoomInfo = null;
          selectedProfileInfo = null;
          isAdditionalInfoVisible = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không tìm thấy dữ liệu cư dân.')),
        );
      }
    } else {
      // Handle when no resident is found in the room
      setState(() {
        selectedRoomInfo = null;
        selectedProfileInfo = null;
        isAdditionalInfoVisible = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không tìm thấy cư dân trong căn hộ này.')),
      );
    }
  }

  // Build resident info card with "Thêm thông tin" button
  Widget buildResidentInfoCard() {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: "Thông tin gia đình" and "Thêm thông tin" button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Thông tin gia đình',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[800],
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (!isAdditionalInfoVisible) {
                      // Show additional info
                      setState(() {
                        isAdditionalInfoVisible = true;
                        additionalInfoList = residentsList.where((resident) {
                          final fields = resident['fields'] ?? {};
                          return _getIntegerValue(fields, 'floor') == _getIntegerValue(selectedRoomInfo!, 'floor') && _getIntegerValue(fields, 'apartmentNumber') == _getIntegerValue(selectedRoomInfo!, 'apartmentNumber');
                        }).toList();
                      });
                    } else {
                      // Hide additional info
                      setState(() {
                        isAdditionalInfoVisible = false;
                        additionalInfoList = [];
                      });
                    }
                  },
                  child: Text(isAdditionalInfoVisible ? 'Ẩn thông tin' : 'Thêm thông tin'),
                ),
              ],
            ),
            const Divider(),
            // Display Family Information
            selectedProfileInfo != null ? buildFamilyInfo(selectedProfileInfo!) : const Text('Đang tìm thông tin...'),
            const SizedBox(height: 10),
            // Display Additional Information Table
            if (isAdditionalInfoVisible) buildAdditionalInfoTable(),
          ],
        ),
      ),
    );
  }

  // Build family information section with improved layout
  Widget buildFamilyInfo(Map<String, dynamic> profileInfo) {
    // Decode profileInfo theo các kiểu dữ liệu của Firestore
    String householdHead = _getStringValue(profileInfo, 'householdHead');
    String occupation = _getStringValue(profileInfo, 'occupation');
    List<String> emergencyContacts = _getArrayStringValue(profileInfo, 'emergencyContacts');
    List<Map<String, dynamic>> members = _getArrayMapValue(profileInfo, 'members');
    String moveInDate = _getStringValue(profileInfo, 'moveInDate');
    String moveOutDate = _getStringValue(profileInfo, 'moveOutDate');
    List<String> utilities = _getArrayStringValue(profileInfo, 'utilities');
    List<Map<String, dynamic>> vehicles = _getArrayMapValue(profileInfo, 'vehicles');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Row for "Chủ nhà" and "Nghề nghiệp"
        Row(
          children: [
            Expanded(
              child: Text(
                'Chủ nhà: $householdHead',
                style: const TextStyle(fontSize: 16),
              ),
            ),
            Expanded(
              child: Text(
                'Nghề nghiệp: $occupation',
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        Text('Liên lạc khẩn cấp:'),
        ...emergencyContacts.map((contact) => Text('- $contact')).toList(),
        const SizedBox(height: 5),
        Text('Thành viên:'),
        ...members.map((member) {
          String name = _getStringValue(member, 'name');
          String relationship = _getStringValue(member, 'relationship');
          return Text('- $name ($relationship)');
        }).toList(),
        const SizedBox(height: 5),
        // Row for "Ngày vào" and "Ngày ra"
        Row(
          children: [
            Expanded(
              child: Text(
                'Ngày vào: ${moveInDate.isNotEmpty ? formatDob(moveInDate) : ''}',
                style: const TextStyle(fontSize: 16),
              ),
            ),
            Expanded(
              child: Text(
                'Ngày ra: ${moveOutDate.isNotEmpty ? formatDob(moveOutDate) : ''}',
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        // Row for "Tiện ích" and "Phương tiện"
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Tiện ích:'),
                  ...utilities.map((utility) => Text('- $utility')).toList(),
                ],
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Phương tiện:'),
                  ...vehicles.map((vehicle) {
                    String type = _getStringValue(vehicle, 'type');
                    String number = _getStringValue(vehicle, 'number');
                    return Text('- $type: $number');
                  }).toList(),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Build additional information table
  Widget buildAdditionalInfoTable() {
    return Padding(
      padding: const EdgeInsets.all(0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const [
            DataColumn(
              label: Text(
                'Họ và Tên',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'Email',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'Số điện thoại',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
          rows: additionalInfoList.map((resident) {
            final fields = resident['fields'] ?? {};
            String fullName = _getStringValue(fields, 'fullName');
            String email = _getStringValue(fields, 'email');
            String phone = _getStringValue(fields, 'phone');
            return DataRow(cells: [
              DataCell(Text(fullName)),
              DataCell(Text(email)),
              DataCell(Text(phone)),
            ]);
          }).toList(),
        ),
      ),
    );
  }

  // Fetch profile information from Firestore
  Future<void> fetchProfile(String profileId) async {
    setState(() {
      isLoadingProfile = true;
    });

    try {
      final profile = await widget.adminRepository.fetchProfile(profileId, widget.idToken);
      if (!mounted) return;
      setState(() {
        selectedProfileInfo = profile;
        isLoadingProfile = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isLoadingProfile = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi tải thông tin gia đình: $e')),
      );
    }
  }

  // Build residents list with edit and delete functionality
  Widget buildResidentsList() {
    return Column(
      // Set mainAxisSize to min to allow Column to size itself based on children
      mainAxisSize: MainAxisSize.min,
      children: [
        // Display total number of residents
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 2.0),
          child: Text(
            'Tổng số cư dân: ${residentsList.length}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        // Header Card
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.zero, // No rounded corners
          ),
          color: Colors.grey[300],
          child: Container(
            width: double.infinity, // Ensure Row expands full width
            padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 4.0),
            child: Row(
              children: const [
                Expanded(
                  flex: 2, // Adjusted flex
                  child: Text(
                    'Tên cư dân',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  flex: 2, // Adjusted flex
                  child: Text(
                    'Số tầng',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  flex: 2, // Adjusted flex
                  child: Text(
                    'Số căn hộ',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  flex: 1, // For icons
                  child: Text(
                    '',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                // Additional column for edit/delete icons
              ],
            ),
          ),
        ),
        // Expanded ListView
        Expanded(
          child: filteredResidents.isEmpty
              ? const Center(
                  child: Text('Không có cư dân nào được tìm thấy.'),
                )
              : ListView.builder(
                  itemCount: filteredResidents.length,
                  itemBuilder: (context, index) {
                    final doc = filteredResidents[index];
                    final name = doc['name']; // Firestore document name
                    final fields = doc['fields'] ?? {};

                    return ResidentListItem(
                      documentName: name, // Pass the document name
                      resident: fields,
                      onUpdate: ({
                        required int apartmentNumber,
                        required String dob,
                        required String email,
                        required int floor,
                        required String fullName,
                        required String gender,
                        required String id,
                        required String phone,
                      }) async {
                        try {
                          await widget.adminRepository.updateResident(
                            documentName: name,
                            apartmentNumber: apartmentNumber,
                            dob: dob,
                            email: email,
                            floor: floor,
                            fullName: fullName,
                            gender: gender,
                            id: id,
                            phone: phone,
                            idToken: widget.idToken,
                          );

                          setState(() {
                            // Update the local residentsList
                            int originalIndex = residentsList.indexWhere((resident) => resident['name'] == name);
                            if (originalIndex != -1) {
                              residentsList[originalIndex]['fields'] = {
                                'apartmentNumber': {'integerValue': apartmentNumber},
                                'dob': {'stringValue': dob},
                                'email': {'stringValue': email},
                                'floor': {'integerValue': floor},
                                'fullName': {'stringValue': fullName},
                                'gender': {'stringValue': gender},
                                'id': {'stringValue': id},
                                'phone': {'stringValue': phone},
                                'status': {'stringValue': 'Đã duyệt'},
                              };
                            }

                            // Reapply filter and sort if necessary
                            if (filterCriteria != null && filterValue.isNotEmpty) {
                              filterResidents(filterCriteria!, filterValue);
                            }
                            if (sortCriteria != null) {
                              sortResidents(sortCriteria!);
                            }
                          });

                          // Show success message
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Cập nhật cư dân thành công.')),
                          );
                        } catch (e) {
                          // Show error message
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Lỗi khi cập nhật cư dân: $e')),
                          );
                        }
                      },
                      onDelete: () async {
                        // Confirm deletion and delete resident from Firestore
                        bool confirm = await _showDeleteConfirmationDialog();
                        if (confirm) {
                          try {
                            await widget.adminRepository.deleteResident(
                              documentName: name,
                              idToken: widget.idToken,
                            );
                            setState(() {
                              residentsList.remove(doc);
                              // Reapply filter and sort if necessary
                              if (filterCriteria != null && filterValue.isNotEmpty) {
                                filterResidents(filterCriteria!, filterValue);
                              }
                              if (sortCriteria != null) {
                                sortResidents(sortCriteria!);
                              }

                              // If the deleted resident was selected, reset selection
                              if (selectedRoomInfo != null && _getStringValue(selectedRoomInfo!, 'profileId') == _getStringValue(fields, 'profileId')) {
                                selectedRoomInfo = null;
                                selectedProfileInfo = null;
                                isAdditionalInfoVisible = false;
                              }
                            });

                            // Show success message
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Xóa cư dân thành công.')),
                            );
                          } catch (e) {
                            // Show error message
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Lỗi khi xóa cư dân: $e')),
                            );
                          }
                        }
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }

  // Show delete confirmation dialog
  Future<bool> _showDeleteConfirmationDialog() async {
    bool confirm = false;
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Xác nhận xóa'),
          content: const Text('Bạn có chắc chắn muốn xóa cư dân này?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                confirm = false;
              },
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                confirm = true;
              },
              child: const Text('Xóa'),
            ),
          ],
        );
      },
    );
    return confirm;
  }

  @override
  Widget build(BuildContext context) {
    // Use LayoutBuilder to adjust layout based on screen size
    return isLoadingResidents
        ? const Center(child: CircularProgressIndicator())
        : LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 800; // Define breakpoint
              return isWide
                  ? Row(
                      children: [
                        // Left Column: Residents List
                        Flexible(
                          flex: 1,
                          child: Container(
                            padding: const EdgeInsets.all(4.0),
                            child: Column(
                              // Set mainAxisSize to max to fill the available space
                              mainAxisSize: MainAxisSize.max,
                              children: [
                                // Sort and Filter Popup Menus with labels
                                Row(
                                  children: [
                                    // Sort Menu with Icon and Text
                                    Row(
                                      children: [
                                        buildSortPopupMenu(),
                                        const SizedBox(width: 6),
                                      ],
                                    ),
                                    const SizedBox(width: 10),
                                    // Filter Menu with Icon and Text
                                    Row(
                                      children: [
                                        buildFilterPopupMenu(),
                                        const SizedBox(width: 4),
                                      ],
                                    ),
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
                        const VerticalDivider(
                          width: 1,
                          thickness: 1,
                          color: Colors.grey,
                        ),
                        // Right Column: Room Selection and Resident Info
                        Flexible(
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
                    )
                  : Column(
                      children: [
                        // Sort and Filter Popup Menus with labels
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            children: [
                              // Sort Menu with Icon and Text
                              Row(
                                children: [
                                  buildSortPopupMenu(),
                                  const SizedBox(width: 4),
                                  const Text(
                                    'Sắp xếp',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 10),
                              // Filter Menu with Icon and Text
                              Row(
                                children: [
                                  buildFilterPopupMenu(),
                                  const SizedBox(width: 4),
                                  const Text(
                                    'Lọc',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                ],
                              ),
                              // Reset Filters and Sorting Button
                              if (filterCriteria != null || sortCriteria != null)
                                IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: resetFiltersAndSorting,
                                  tooltip: 'Đặt lại bộ lọc và sắp xếp',
                                ),
                            ],
                          ),
                        ),
                        // Residents List
                        Expanded(
                          flex: 1,
                          child: buildResidentsList(),
                        ),
                        // Room Selection
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

  // Helper to decode array of strings from Firestore
  List<String> _getArrayStringValue(Map<String, dynamic> fields, String key) {
    List<String> list = [];
    if (fields.containsKey(key) && fields[key]['arrayValue'] != null && fields[key]['arrayValue']['values'] != null) {
      for (var item in fields[key]['arrayValue']['values']) {
        if (item.containsKey('stringValue')) {
          list.add(item['stringValue']);
        }
      }
    }
    return list;
  }

  // Helper to decode array of maps from Firestore
  List<Map<String, dynamic>> _getArrayMapValue(Map<String, dynamic> fields, String key) {
    List<Map<String, dynamic>> list = [];
    if (fields.containsKey(key) && fields[key]['arrayValue'] != null && fields[key]['arrayValue']['values'] != null) {
      for (var item in fields[key]['arrayValue']['values']) {
        if (item.containsKey('mapValue') && item['mapValue']['fields'] != null) {
          list.add(Map<String, dynamic>.from(item['mapValue']['fields']));
        }
      }
    }
    return list;
  }
}

// Widget for individual resident list item with edit and delete functionality
class ResidentListItem extends StatefulWidget {
  final String documentName; // Firestore document name
  final Map<String, dynamic> resident;
  final Function({
    required int apartmentNumber,
    required String dob,
    required String email,
    required int floor,
    required String fullName,
    required String gender,
    required String id,
    required String phone,
  }) onUpdate;
  final Function onDelete;

  const ResidentListItem({
    Key? key,
    required this.documentName,
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
    // Initialize controllers with existing values or empty strings
    fullNameController = TextEditingController(
      text: widget.resident['fullName']?['stringValue'] ?? '',
    );
    genderController = TextEditingController(
      text: widget.resident['gender']?['stringValue'] ?? '',
    );
    dobController = TextEditingController(
      text: widget.resident['dob']?['stringValue'] ?? '',
    );
    phoneController = TextEditingController(
      text: widget.resident['phone']?['stringValue'] ?? '',
    );
    idController = TextEditingController(
      text: widget.resident['id']?['stringValue'] ?? '',
    );
    emailController = TextEditingController(
      text: widget.resident['email']?['stringValue'] ?? '',
    );
    floorController = TextEditingController(
      text: widget.resident['floor']?['integerValue']?.toString() ?? '',
    );
    apartmentNumberController = TextEditingController(
      text: widget.resident['apartmentNumber']?['integerValue']?.toString() ?? '',
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng điền đầy đủ thông tin.')),
      );
      return;
    }

    // Validate numeric fields
    int? floor = int.tryParse(updatedFloor);
    int? apartmentNumber = int.tryParse(updatedApartmentNumber);

    if (floor == null || apartmentNumber == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tầng và số căn hộ phải là số nguyên.')),
      );
      return;
    }

    // Call the onUpdate callback with the updated data
    widget.onUpdate(
      apartmentNumber: apartmentNumber,
      dob: updatedDob,
      email: updatedEmail,
      floor: floor,
      fullName: updatedFullName,
      gender: updatedGender,
      id: updatedId,
      phone: updatedPhone,
    );

    setState(() {
      isEditing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.zero, // No rounded corners for consistency
      ),
      margin: EdgeInsets.zero, // No spacing between cards
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: isEditing
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Editable Info Fields
                  TextField(
                    controller: fullNameController,
                    decoration: const InputDecoration(
                      labelText: 'Họ và Tên',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
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
                    flex: 2, // Adjusted to match header
                    child: Text(
                      widget.resident['fullName']?['stringValue'] ?? '',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                  // Tầng
                  Expanded(
                    flex: 2, // Adjusted to match header
                    child: Text(
                      widget.resident['floor']?['integerValue']?.toString() ?? '',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                  // Số căn hộ
                  Expanded(
                    flex: 2, // Adjusted to match header
                    child: Text(
                      widget.resident['apartmentNumber']?['integerValue']?.toString() ?? '',
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
                      // Handle deletion
                      widget.onDelete();
                    },
                    tooltip: 'Xóa',
                  ),
                ],
              ),
      ),
    );
  }
}
