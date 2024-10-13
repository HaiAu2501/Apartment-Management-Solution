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
  List<dynamic> residentsList = [];
  List<dynamic> filteredResidents = [];
  bool isLoadingResidents = false;

  // Biến trạng thái cho sắp xếp và lọc
  String? sortCriteria;
  String? filterCriteria;
  String filterValue = '';

  @override
  void initState() {
    super.initState();
    fetchResidents();
  }

  @override
  void dispose() {
    // Nếu bạn có các Stream hoặc các đối tượng khác cần hủy bỏ, hãy thực hiện ở đây.
    super.dispose();
  }

  // Hàm lấy danh sách cư dân
  Future<void> fetchResidents() async {
    setState(() {
      isLoadingResidents = true;
    });

    try {
      List<dynamic> fetchedResidents = await widget.adminRepository.fetchResidents(widget.idToken);
      if (!mounted) return; // Kiểm tra nếu widget vẫn còn mount
      setState(() {
        residentsList = fetchedResidents;
        filteredResidents = residentsList;
        isLoadingResidents = false;
      });
    } catch (e) {
      if (!mounted) return; // Kiểm tra nếu widget vẫn còn mount
      setState(() {
        // Xử lý lỗi nếu cần
        isLoadingResidents = false;
      });
      print('Lỗi khi tải residents: $e');
    }
  }

  // Hàm định dạng ngày sinh
  String formatDob(String dobString) {
    try {
      // Giả sử dobString có định dạng DD/MM/YYYY
      DateFormat inputFormat = DateFormat('dd/MM/yyyy');
      DateFormat outputFormat = DateFormat('dd/MM/yyyy');
      DateTime date = inputFormat.parse(dobString);
      return outputFormat.format(date);
    } catch (e) {
      return dobString; // Nếu không thể định dạng, trả về nguyên bản
    }
  }

  // Hàm xử lý sắp xếp
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

  // Hàm xử lý lọc
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

      // Nếu đã có sắp xếp, áp dụng lại
      if (sortCriteria != null) {
        sortResidents(sortCriteria!);
      }
    });
  }

  // Hàm hiển thị dialog sắp xếp
  void showSortDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Sắp xếp theo'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('Tầng'),
                onTap: () {
                  sortResidents('floor');
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                title: const Text('Số căn hộ'),
                onTap: () {
                  sortResidents('apartmentNumber');
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                title: const Text('Tên'),
                onTap: () {
                  sortResidents('fullName');
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // Hàm hiển thị dialog lọc
  void showFilterDialog() {
    String selectedCriteria = 'floor';
    String inputValue = '';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Lọc theo tiêu chí'),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButton<String>(
                    value: selectedCriteria,
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          selectedCriteria = newValue;
                        });
                      }
                    },
                    items: <String>['floor', 'apartmentNumber', 'fullName'].map<DropdownMenuItem<String>>((String value) {
                      String displayValue;
                      switch (value) {
                        case 'floor':
                          displayValue = 'Tầng';
                          break;
                        case 'apartmentNumber':
                          displayValue = 'Số căn hộ';
                          break;
                        case 'fullName':
                          displayValue = 'Họ và Tên';
                          break;
                        default:
                          displayValue = value;
                      }
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(displayValue),
                      );
                    }).toList(),
                  ),
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Giá trị',
                    ),
                    onChanged: (value) {
                      inputValue = value;
                    },
                  ),
                ],
              );
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
                  filterResidents(selectedCriteria, inputValue);
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Áp dụng'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoadingResidents) {
      return const Center(child: CircularProgressIndicator());
    }

    if (residentsList.isEmpty) {
      return const Center(child: Text('Không có cư dân nào.'));
    }

    return Column(
      children: [
        // Nút Sắp xếp và Lọc
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              ElevatedButton.icon(
                onPressed: showSortDialog,
                icon: const Icon(Icons.sort),
                label: const Text('Sắp xếp'),
              ),
              const SizedBox(width: 10),
              ElevatedButton.icon(
                onPressed: showFilterDialog,
                icon: const Icon(Icons.filter_list),
                label: const Text('Lọc'),
              ),
              const Spacer(),
              // Nút Đặt lại bộ lọc nếu cần
              if (filterCriteria != null || sortCriteria != null)
                IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    setState(() {
                      filterCriteria = null;
                      sortCriteria = null;
                      filteredResidents = residentsList;
                    });
                  },
                ),
            ],
          ),
        ),
        Expanded(
          child: filteredResidents.isEmpty
              ? const Center(child: Text('Không có kết quả phù hợp với tiêu chí lọc.'))
              : ListView.builder(
                  itemCount: filteredResidents.length,
                  itemBuilder: (context, index) {
                    final doc = filteredResidents[index];
                    final fields = doc['fields'];
                    return Card(
                      child: ListTile(
                        title: Text(fields['fullName']['stringValue']),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Giới tính: ${fields['gender']['stringValue']}'),
                            Text('Ngày sinh: ${formatDob(fields['dob']['stringValue'])}'),
                            Text('Số điện thoại: ${fields['phone']['stringValue']}'),
                            Text('Số ID: ${fields['id']['stringValue']}'),
                            Text('Email: ${fields['email']['stringValue']}'),
                            Text('Tầng: ${fields['floor']['integerValue']}'),
                            Text('Căn hộ số: ${fields['apartmentNumber']['integerValue']}'),
                            Text('Trạng thái: ${fields['status']['stringValue']}'),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
