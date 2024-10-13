// lib/features/admin/presentation/tabs/queue_tab.dart
import 'package:flutter/material.dart';
import '../../../.authentication/data/auth_service.dart';
import '../../data/admin_repository.dart';
import '../widgets/edit_user_form.dart';
import 'package:intl/intl.dart';

class QueueTab extends StatefulWidget {
  final AdminRepository adminRepository;
  final String idToken;
  final AuthenticationService authService;
  final Function(String?) onMessage; // Cho phép nhận String? (có thể là null)

  const QueueTab({
    super.key,
    required this.adminRepository,
    required this.idToken,
    required this.authService,
    required this.onMessage,
  });

  @override
  _QueueTabState createState() => _QueueTabState();
}

class _QueueTabState extends State<QueueTab> {
  List<dynamic> queueList = []; // Toàn bộ tài khoản trong queue
  List<dynamic> filteredQueueList = []; // Sau khi lọc và sắp xếp
  bool isLoadingQueue = false;

  // Biến trạng thái cho sắp xếp và lọc
  String? sortCriteria;
  String? filterCriteria;
  String filterValue = '';

  // Biến thống kê
  int totalPending = 0;
  int totalResidentsPending = 0;
  int totalGuestsPending = 0;

  // Phân trang
  int currentPage = 1;
  int totalPages = 1;
  static const int itemsPerPage = 10;

  // Biến quản lý mở rộng dòng
  Map<String, bool> expandedRows = {};

  @override
  void initState() {
    super.initState();
    fetchQueue();
  }

  @override
  void dispose() {
    // Nếu bạn có các Stream hoặc các đối tượng khác cần hủy bỏ, hãy thực hiện ở đây.
    super.dispose();
  }

  // Hàm lấy tất cả danh sách chờ duyệt
  Future<void> fetchQueue() async {
    setState(() {
      isLoadingQueue = true;
    });

    try {
      List<dynamic> fetchedQueue = await widget.adminRepository.fetchAllQueue(widget.idToken);
      if (!mounted) return; // Kiểm tra nếu widget vẫn còn mount
      setState(() {
        queueList = fetchedQueue;
        applyFilterAndSort(); // Áp dụng lọc và sắp xếp sau khi lấy dữ liệu
        isLoadingQueue = false;
      });
    } catch (e) {
      if (!mounted) return; // Kiểm tra nếu widget vẫn còn mount
      widget.onMessage('Lỗi khi tải danh sách chờ duyệt.');
      print('Lỗi khi tải queue: $e');
      setState(() {
        isLoadingQueue = false;
      });
    }
  }

  // Hàm tính toán thống kê dựa trên toàn bộ queueList
  void calculateStatistics() {
    totalPending = queueList.length;
    totalResidentsPending = queueList.where((user) => user['fields']['role']['stringValue'] == 'Cư dân').length;
    totalGuestsPending = queueList.where((user) => user['fields']['role']['stringValue'] == 'Khách').length;
  }

  // Hàm phê duyệt người dùng từ queue
  Future<void> approveUser(String queueDocName, Map<String, dynamic> queueData) async {
    widget.onMessage(null); // Bỏ thông báo hiện tại

    try {
      await widget.adminRepository.approveUser(queueDocName, queueData, widget.idToken, widget.authService);
      if (!mounted) return; // Kiểm tra nếu widget vẫn còn mount
      widget.onMessage('Phê duyệt thành công.');
      // Reset danh sách và fetch lại từ đầu
      setState(() {
        currentPage = 1;
      });
      fetchQueue();
    } catch (e) {
      if (!mounted) return; // Kiểm tra nếu widget vẫn còn mount
      widget.onMessage(e.toString());
      print('Lỗi khi phê duyệt user: $e');
    }
  }

  // Hàm từ chối người dùng
  Future<void> rejectUser(String queueDocName) async {
    widget.onMessage(null); // Bỏ thông báo hiện tại

    try {
      await widget.adminRepository.rejectUser(queueDocName, widget.idToken, widget.authService);
      if (!mounted) return; // Kiểm tra nếu widget vẫn còn mount
      widget.onMessage('Đã từ chối người dùng.');
      // Reset danh sách và fetch lại từ đầu
      setState(() {
        currentPage = 1;
      });
      fetchQueue();
    } catch (e) {
      if (!mounted) return; // Kiểm tra nếu widget vẫn còn mount
      widget.onMessage(e.toString());
      print('Lỗi khi từ chối user: $e');
    }
  }

  // Hàm chỉnh sửa người dùng
  Future<void> editUser(String queueDocName, Map<String, dynamic> updatedData) async {
    widget.onMessage(null); // Bỏ thông báo hiện tại

    try {
      await widget.adminRepository.updateQueueDocument(queueDocName, updatedData, widget.idToken);
      if (!mounted) return; // Kiểm tra nếu widget vẫn còn mount
      widget.onMessage('Đã cập nhật thông tin người dùng.');
      // Reset danh sách và fetch lại từ đầu
      setState(() {
        currentPage = 1;
      });
      fetchQueue();
    } catch (e) {
      if (!mounted) return; // Kiểm tra nếu widget vẫn còn mount
      widget.onMessage('Lỗi khi cập nhật thông tin.');
      print('Lỗi khi cập nhật user: $e');
    }
  }

  // Hàm chuyển đổi trạng thái mở rộng của dòng
  void toggleExpanded(String docName) {
    setState(() {
      expandedRows[docName] = !(expandedRows[docName] ?? false);
    });
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
  void sortQueue(String criteria) {
    setState(() {
      sortCriteria = criteria;
      applyFilterAndSort();
      currentPage = 1; // Đặt lại trang hiện tại về 1 khi sắp xếp
    });
  }

  // Hàm xử lý lọc
  void filterQueue(String criteria, String value) {
    setState(() {
      filterCriteria = criteria;
      filterValue = value.toLowerCase();
      applyFilterAndSort();
      currentPage = 1; // Đặt lại trang hiện tại về 1 khi lọc
    });
  }

  // Hàm áp dụng lọc và sắp xếp
  void applyFilterAndSort() {
    // Bước 1: Lọc
    if (filterCriteria != null && filterValue.isNotEmpty) {
      filteredQueueList = queueList.where((user) {
        final fields = user['fields'];
        switch (filterCriteria) {
          case 'role':
            return fields['role']['stringValue'].toLowerCase() == filterValue;
          default:
            return true;
        }
      }).toList();
    } else {
      filteredQueueList = List.from(queueList);
    }

    // Bước 2: Sắp xếp
    if (sortCriteria != null) {
      filteredQueueList.sort((a, b) {
        final aFields = a['fields'];
        final bFields = b['fields'];
        switch (sortCriteria) {
          case 'fullName':
            return aFields['fullName']['stringValue'].compareTo(bFields['fullName']['stringValue']);
          case 'floor':
            // Chỉ sắp xếp nếu cả hai đều là Cư dân
            if (aFields['role']['stringValue'] == 'Cư dân' && bFields['role']['stringValue'] == 'Cư dân') {
              return int.parse(aFields['floor']['integerValue']).compareTo(int.parse(bFields['floor']['integerValue']));
            }
            return 0;
          case 'apartmentNumber':
            // Chỉ sắp xếp nếu cả hai đều là Cư dân
            if (aFields['role']['stringValue'] == 'Cư dân' && bFields['role']['stringValue'] == 'Cư dân') {
              return int.parse(aFields['apartmentNumber']['integerValue']).compareTo(int.parse(bFields['apartmentNumber']['integerValue']));
            }
            return 0;
          default:
            return 0;
        }
      });
    }

    // Bước 3: Tính toán tổng số trang
    totalPages = (filteredQueueList.length / itemsPerPage).ceil();

    // Bước 4: Tính toán thống kê dựa trên toàn bộ queueList
    calculateStatistics();
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
                title: const Text('Họ tên'),
                onTap: () {
                  sortQueue('fullName');
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                title: const Text('Số tầng'),
                onTap: () {
                  sortQueue('floor');
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                title: const Text('Số căn hộ'),
                onTap: () {
                  sortQueue('apartmentNumber');
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
    String selectedCriteria = 'role';
    String inputValue = 'Cư dân'; // Mặc định là "Cư dân"

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
                          // Reset giá trị khi thay đổi tiêu chí
                          inputValue = newValue == 'role' ? 'Cư dân' : '';
                        });
                      }
                    },
                    items: <String>['role'].map<DropdownMenuItem<String>>((String value) {
                      String displayValue;
                      switch (value) {
                        case 'role':
                          displayValue = 'Vai trò';
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
                  if (selectedCriteria == 'role')
                    DropdownButton<String>(
                      value: inputValue,
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            inputValue = newValue;
                          });
                        }
                      },
                      items: <String>['Cư dân', 'Khách'].map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                    ),
                  // Bạn có thể thêm các tiêu chí lọc khác ở đây nếu cần
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
                filterQueue(selectedCriteria, inputValue);
                Navigator.of(context).pop();
              },
              child: const Text('Áp dụng'),
            ),
          ],
        );
      },
    );
  }

  // Hàm chuyển trang
  void goToPage(int page) {
    setState(() {
      currentPage = page;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoadingQueue) {
      return const Center(child: CircularProgressIndicator());
    }

    if (queueList.isEmpty) {
      return const Center(child: Text('Không có yêu cầu nào đang chờ duyệt.'));
    }

    // Tính toán danh sách người dùng hiển thị theo trang hiện tại
    int startIndex = (currentPage - 1) * itemsPerPage;
    int endIndex = startIndex + itemsPerPage;
    if (endIndex > filteredQueueList.length) {
      endIndex = filteredQueueList.length;
    }
    List<dynamic> currentPageList = filteredQueueList.sublist(startIndex, endIndex);

    return Column(
      children: [
        // Thông tin thống kê
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              // Tổng số tài khoản chờ duyệt
              Expanded(
                child: Card(
                  color: Colors.blue.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        const Icon(Icons.pending_actions, size: 40, color: Colors.blue),
                        const SizedBox(height: 10),
                        Text(
                          '$totalPending',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 5),
                        const Text(
                          'Tổng chờ duyệt',
                          style: TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Số lượng tài khoản Cư dân chờ duyệt
              Expanded(
                child: Card(
                  color: Colors.green.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        const Icon(Icons.person, size: 40, color: Colors.green),
                        const SizedBox(height: 10),
                        Text(
                          '$totalResidentsPending',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 5),
                        const Text(
                          'Cư dân chờ duyệt',
                          style: TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Số lượng tài khoản Khách chờ duyệt
              Expanded(
                child: Card(
                  color: Colors.orange.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        const Icon(Icons.person_outline, size: 40, color: Colors.orange),
                        const SizedBox(height: 10),
                        Text(
                          '$totalGuestsPending',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 5),
                        const Text(
                          'Khách chờ duyệt',
                          style: TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Nút Sắp xếp và Lọc
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
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
              // Nút Đặt lại bộ lọc và sắp xếp nếu cần
              if (filterCriteria != null || sortCriteria != null)
                IconButton(
                  icon: const Icon(Icons.clear),
                  tooltip: 'Đặt lại',
                  onPressed: () {
                    setState(() {
                      filterCriteria = null;
                      sortCriteria = null;
                      applyFilterAndSort();
                      currentPage = 1;
                    });
                  },
                ),
            ],
          ),
        ),
        // Danh sách người dùng
        Expanded(
          child: currentPageList.isEmpty
              ? const Center(child: Text('Không có kết quả phù hợp với tiêu chí lọc.'))
              : ListView.builder(
                  itemCount: currentPageList.length,
                  itemBuilder: (context, index) {
                    final doc = currentPageList[index];
                    final fields = doc['fields'];
                    final docName = doc['name'];
                    bool isExpanded = expandedRows[docName] ?? false;

                    return Card(
                      child: Column(
                        children: [
                          ListTile(
                            title: Text(fields['fullName']['stringValue']),
                            subtitle: Row(
                              children: [
                                Expanded(child: Text('Giới tính: ${fields['gender']['stringValue']}')),
                                Expanded(child: Text('Email: ${fields['email']['stringValue']}')),
                                Expanded(child: Text('Vai trò: ${fields['role']['stringValue']}')),
                                Expanded(child: Text('SĐT: ${fields['phone']['stringValue']}')),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.check, color: Colors.green),
                                  tooltip: 'Phê duyệt',
                                  onPressed: () {
                                    approveUser(docName, fields);
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close, color: Colors.red),
                                  tooltip: 'Từ chối',
                                  onPressed: () {
                                    rejectUser(docName);
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.visibility, color: Colors.blue),
                                  tooltip: 'Xem thêm',
                                  onPressed: () {
                                    toggleExpanded(docName);
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.orange),
                                  tooltip: 'Chỉnh sửa',
                                  onPressed: () {
                                    toggleExpanded(docName);
                                  },
                                ),
                              ],
                            ),
                          ),
                          // Dòng mở rộng khi xem thêm hoặc chỉnh sửa
                          if (isExpanded)
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Hiển thị chi tiết hoặc biểu mẫu chỉnh sửa
                                  Text('Ngày sinh: ${formatDob(fields['dob']['stringValue'])}'),
                                  Text('Số ID: ${fields['id']['stringValue']}'),
                                  if (fields['role']['stringValue'] == 'Khách') Text('Chức vụ: ${fields['jobTitle']['stringValue']}'),
                                  if (fields['role']['stringValue'] == 'Cư dân') ...[
                                    Text('Tầng: ${fields['floor']['integerValue']}'),
                                    Text('Căn hộ số: ${fields['apartmentNumber']['integerValue']}'),
                                  ],
                                  Text('Trạng thái: ${fields['status']['stringValue']}'),
                                  const SizedBox(height: 10),
                                  // Biểu mẫu chỉnh sửa
                                  EditUserForm(
                                    initialData: fields,
                                    onSave: (updatedData) {
                                      editUser(docName, updatedData);
                                    },
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
        ),
        // Phân trang
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Nút Trang Trước
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: currentPage > 1
                    ? () {
                        goToPage(currentPage - 1);
                      }
                    : null,
              ),
              // Hiển thị Trang Hiện Tại / Tổng Số Trang
              Text('Trang $currentPage/$totalPages'),
              // Nút Trang Sau
              IconButton(
                icon: const Icon(Icons.arrow_forward),
                onPressed: currentPage < totalPages
                    ? () {
                        goToPage(currentPage + 1);
                      }
                    : null,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
