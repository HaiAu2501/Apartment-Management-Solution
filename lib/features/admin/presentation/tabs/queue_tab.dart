// lib/features/admin/presentation/tabs/queue_tab.dart

import 'package:flutter/material.dart';
import '../../../.authentication/data/auth_service.dart';
import '../../data/admin_repository.dart';
import '../widgets/queue_card.dart'; // Import QueueCard
import 'package:intl/intl.dart';

class QueueTab extends StatefulWidget {
  final AdminRepository adminRepository;
  final String idToken;
  final AuthenticationService authService;
  final Function(String?) onMessage;

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
  List<dynamic> queueList = [];
  List<dynamic> filteredQueueList = [];
  bool isLoadingQueue = false;

  String? sortCriteria;
  String? filterCriteria;
  String filterValue = '';

  int totalPending = 0;
  int totalResidentsPending = 0;
  int totalGuestsPending = 0;

  int currentPage = 1;
  int totalPages = 1;
  static const int itemsPerPage = 10;

  @override
  void initState() {
    super.initState();
    fetchQueue();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> fetchQueue() async {
    setState(() {
      isLoadingQueue = true;
    });

    try {
      List<dynamic> fetchedQueue = await widget.adminRepository.fetchAllQueue(widget.idToken);
      if (!mounted) return;
      setState(() {
        queueList = fetchedQueue;
        applyFilterAndSort();
        isLoadingQueue = false;
      });
    } catch (e) {
      if (!mounted) return;
      widget.onMessage('Lỗi khi tải danh sách chờ duyệt.');
      print('Lỗi khi tải queue: $e');
      setState(() {
        isLoadingQueue = false;
      });
    }
  }

  void calculateStatistics() {
    totalPending = queueList.length;
    totalResidentsPending = queueList.where((user) => user['fields']['role']['stringValue'] == 'Cư dân').length;
    totalGuestsPending = queueList.where((user) => user['fields']['role']['stringValue'] == 'Khách').length;
  }

  void applyFilterAndSort() {
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

    if (sortCriteria != null) {
      filteredQueueList.sort((a, b) {
        final aFields = a['fields'];
        final bFields = b['fields'];
        switch (sortCriteria) {
          case 'fullName':
            return aFields['fullName']['stringValue'].compareTo(bFields['fullName']['stringValue']);
          case 'floor':
            if (aFields['role']['stringValue'] == 'Cư dân' && bFields['role']['stringValue'] == 'Cư dân') {
              return int.parse(aFields['floor']['integerValue']).compareTo(int.parse(bFields['floor']['integerValue']));
            }
            return 0;
          case 'apartmentNumber':
            if (aFields['role']['stringValue'] == 'Cư dân' && bFields['role']['stringValue'] == 'Cư dân') {
              return int.parse(aFields['apartmentNumber']['integerValue']).compareTo(int.parse(bFields['apartmentNumber']['integerValue']));
            }
            return 0;
          default:
            return 0;
        }
      });
    }

    totalPages = (filteredQueueList.length / itemsPerPage).ceil();

    calculateStatistics();
  }

  void sortQueue(String criteria) {
    setState(() {
      sortCriteria = criteria;
      applyFilterAndSort();
      currentPage = 1;
    });
  }

  void filterQueue(String criteria, String value) {
    setState(() {
      filterCriteria = criteria;
      filterValue = value.toLowerCase();
      applyFilterAndSort();
      currentPage = 1;
    });
  }

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

  void showFilterDialog() {
    String selectedCriteria = 'role';
    String inputValue = 'Cư dân';

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

  void goToPage(int page) {
    setState(() {
      currentPage = page;
    });
  }

  // Mới: Hàm để xử lý lựa chọn từ menu "Thao tác" trong tiêu đề
  void handleHeaderAction(String action) {
    switch (action) {
      case 'Sort':
        showSortDialog();
        break;
      case 'Filter':
        showFilterDialog();
        break;
      case 'Reset':
        setState(() {
          sortCriteria = null;
          filterCriteria = null;
          filterValue = '';
          applyFilterAndSort();
          currentPage = 1;
        });
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoadingQueue) {
      return const Center(child: CircularProgressIndicator());
    }

    if (queueList.isEmpty) {
      return const Center(child: Text('Không có yêu cầu nào đang chờ duyệt.'));
    }

    int startIndex = (currentPage - 1) * itemsPerPage;
    int endIndex = startIndex + itemsPerPage;
    if (endIndex > filteredQueueList.length) {
      endIndex = filteredQueueList.length;
    }
    List<dynamic> currentPageList = filteredQueueList.sublist(startIndex, endIndex);

    return Column(
      children: [
        SizedBox(height: 8),
        // Thông tin thống kê
        Padding(
          padding: const EdgeInsets.all(0),
          child: Row(
            children: [
              Expanded(
                child: Card(
                  color: Colors.blue.shade50,
                  margin: EdgeInsets.zero, // Loại bỏ margin giữa các Card
                  elevation: 0, // Loại bỏ hiệu ứng đổ bóng
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero, // Loại bỏ bo góc
                  ),
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
              Expanded(
                child: Card(
                  color: Colors.green.shade50,
                  margin: EdgeInsets.zero,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
                  ),
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
              Expanded(
                child: Card(
                  color: Colors.orange.shade50,
                  margin: EdgeInsets.zero,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
                  ),
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
        // Nút Thao tác trong tiêu đề
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          child: Row(
            children: [
              // Loại bỏ hai nút "Sắp xếp" và "Lọc"
              // Thêm Spacer hoặc các widget khác nếu cần
              const Spacer(),
              // Không cần nút "Clear" riêng
            ],
          ),
        ),
        // Thẻ tiêu đề cột với nút "Thao tác"
        Card(
          margin: EdgeInsets.zero, // Loại bỏ margin giữa các Card
          elevation: 0, // Loại bỏ hiệu ứng đổ bóng
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.zero, // Loại bỏ bo góc
          ),
          color: Colors.grey.shade200, // Màu nền cho tiêu đề
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
            child: Row(
              children: [
                // Các cột tiêu đề khác
                const Expanded(
                  flex: 3,
                  child: Text(
                    'Họ và tên',
                    textAlign: TextAlign.center, // Căn giữa
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                const Expanded(
                  flex: 4,
                  child: Text(
                    'Email',
                    textAlign: TextAlign.center, // Căn giữa
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                const Expanded(
                  flex: 2,
                  child: Text(
                    'Vai trò',
                    textAlign: TextAlign.center, // Căn giữa
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                const Expanded(
                  flex: 3,
                  child: Text(
                    'Số điện thoại',
                    textAlign: TextAlign.center, // Căn giữa
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                // Cột Thao tác với nút PopupMenuButton
                Expanded(
                  flex: 2,
                  child: PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert),
                    tooltip: 'Thao tác',
                    onSelected: handleHeaderAction,
                    itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                      const PopupMenuItem<String>(
                        value: 'Sort',
                        child: Text('Sắp xếp'),
                      ),
                      const PopupMenuItem<String>(
                        value: 'Filter',
                        child: Text('Lọc'),
                      ),
                      const PopupMenuItem<String>(
                        value: 'Reset',
                        child: Text('Đặt lại'),
                      ),
                    ],
                    // Điều chỉnh vị trí của menu
                    // Bạn có thể cần điều chỉnh giá trị Offset tùy thuộc vào thiết kế của bạn
                    offset: const Offset(0, 40), // Giảm hoặc tăng giá trị X để căn giữa
                  ),
                ),
              ],
            ),
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

                    return QueueCard(
                      userData: fields ?? {}, // Đảm bảo 'fields' không null
                      docName: docName,
                      adminRepository: widget.adminRepository,
                      idToken: widget.idToken,
                      authService: widget.authService,
                      onMessage: widget.onMessage,
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
