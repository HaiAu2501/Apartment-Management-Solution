// lib/features/admin/presentation/users_page.dart
import 'package:flutter/material.dart';
import '../../.authentication/data/auth_service.dart';
import '../data/admin_repository.dart';
import 'dart:convert';
import 'package:intl/intl.dart';

class UsersPage extends StatefulWidget {
  final AuthenticationService authService;
  final String idToken;
  final String uid;

  const UsersPage({
    super.key,
    required this.authService,
    required this.idToken,
    required this.uid,
  });

  @override
  _UsersPageState createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  late AdminRepository adminRepository;

  List<dynamic> queueList = [];
  List<dynamic> residentsList = [];
  List<dynamic> guestsList = [];
  bool isLoadingQueue = false;
  bool isLoadingResidents = false;
  bool isLoadingGuests = false;
  String? message;

  // Map để lưu trạng thái mở rộng của từng tài liệu
  Map<String, bool> expandedRows = {};

  @override
  void initState() {
    super.initState();
    adminRepository = AdminRepository(
      apiKey: widget.authService.apiKey,
      projectId: widget.authService.projectId,
    );
    // print('adminRepository initialized');
    fetchQueue();
    fetchResidents();
    fetchGuests();
  }

  @override
  void dispose() {
    super.dispose();
  }

  // Hàm lấy danh sách chờ duyệt
  Future<void> fetchQueue() async {
    setState(() {
      isLoadingQueue = true;
    });

    try {
      List<dynamic> fetchedQueue = await adminRepository.fetchQueue(widget.idToken);
      setState(() {
        queueList = fetchedQueue;
        isLoadingQueue = false;
      });
    } catch (e) {
      setState(() {
        message = 'Lỗi khi tải danh sách chờ duyệt.';
        isLoadingQueue = false;
      });
      print('Lỗi khi tải queue: $e');
    }
  }

  // Hàm lấy danh sách cư dân
  Future<void> fetchResidents() async {
    setState(() {
      isLoadingResidents = true;
    });

    try {
      List<dynamic> fetchedResidents = await adminRepository.fetchResidents(widget.idToken);
      setState(() {
        residentsList = fetchedResidents;
        isLoadingResidents = false;
      });
    } catch (e) {
      setState(() {
        message = 'Lỗi khi tải danh sách cư dân.';
        isLoadingResidents = false;
      });
      print('Lỗi khi tải residents: $e');
    }
  }

  // Hàm lấy danh sách khách
  Future<void> fetchGuests() async {
    setState(() {
      isLoadingGuests = true;
    });

    try {
      List<dynamic> fetchedGuests = await adminRepository.fetchGuests(widget.idToken);
      setState(() {
        guestsList = fetchedGuests;
        isLoadingGuests = false;
      });
    } catch (e) {
      setState(() {
        message = 'Lỗi khi tải danh sách khách.';
        isLoadingGuests = false;
      });
      print('Lỗi khi tải guests: $e');
    }
  }

  // Hàm phê duyệt người dùng từ queue
  Future<void> approveUser(String queueDocName, Map<String, dynamic> queueData) async {
    setState(() {
      message = null;
    });

    try {
      await adminRepository.approveUser(queueDocName, queueData, widget.idToken, widget.authService);
      setState(() {
        message = 'Phê duyệt thành công.';
      });
      fetchQueue();
      String role = queueData['role']['stringValue'];
      if (role == 'Cư dân') {
        fetchResidents();
      } else {
        fetchGuests();
      }
    } catch (e) {
      setState(() {
        message = e.toString();
      });
      print('Lỗi khi phê duyệt user: $e');
    }
  }

  // Hàm từ chối người dùng
  Future<void> rejectUser(String queueDocName) async {
    setState(() {
      message = null;
    });

    try {
      await adminRepository.rejectUser(queueDocName, widget.idToken, widget.authService);
      setState(() {
        message = 'Đã từ chối người dùng.';
      });
      fetchQueue();
    } catch (e) {
      setState(() {
        message = e.toString();
      });
      print('Lỗi khi từ chối user: $e');
    }
  }

  Future<void> editUser(String queueDocName, Map<String, dynamic> updatedData) async {
    setState(() {
      message = null;
    });

    try {
      await adminRepository.updateQueueDocument(queueDocName, updatedData, widget.idToken);
      setState(() {
        message = 'Đã cập nhật thông tin người dùng.';
      });
      fetchQueue();
    } catch (e) {
      setState(() {
        message = 'Lỗi khi cập nhật thông tin.';
      });
      print('Lỗi khi cập nhật user: $e');
    }
  }

  // Hàm chuyển đổi trạng thái mở rộng của dòng
  void toggleExpanded(String docName) {
    setState(() {
      expandedRows[docName] = !(expandedRows[docName] ?? false);
    });
  }

  // Hàm hiển thị thông báo
  Widget buildMessage() {
    if (message == null) return const SizedBox.shrink();
    return Text(
      message!,
      style: TextStyle(color: message!.contains('thành công') ? Colors.green : Colors.red),
    );
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

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Hiển thị thông báo
          buildMessage(),
          const SizedBox(height: 20),
          // Tab để chuyển đổi giữa danh sách chờ và danh sách cư dân, khách
          Expanded(
            child: DefaultTabController(
              length: 3,
              child: Column(
                children: [
                  const TabBar(
                    labelColor: Colors.green,
                    indicatorColor: Colors.green,
                    tabs: [
                      Tab(text: 'Chờ duyệt'),
                      Tab(text: 'Cư dân'),
                      Tab(text: 'Khách'),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        // Tab 1: Danh Sách Chờ Duyệt
                        isLoadingQueue
                            ? const Center(child: CircularProgressIndicator())
                            : queueList.isEmpty
                                ? const Center(child: Text('Không có yêu cầu nào đang chờ duyệt.'))
                                : ListView.builder(
                                    itemCount: queueList.length,
                                    itemBuilder: (context, index) {
                                      final doc = queueList[index];
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
                                                    // Bạn có thể phân biệt giữa xem và chỉnh sửa bằng cách thêm trạng thái khác
                                                    // Dưới đây là ví dụ đơn giản chỉ hiển thị thông tin
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

                        // Tab 2: Danh Sách Cư Dân
                        isLoadingResidents
                            ? const Center(child: CircularProgressIndicator())
                            : residentsList.isEmpty
                                ? const Center(child: Text('Không có cư dân nào.'))
                                : ListView.builder(
                                    itemCount: residentsList.length,
                                    itemBuilder: (context, index) {
                                      final doc = residentsList[index];
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

                        // Tab 3: Danh Sách Khách
                        isLoadingGuests
                            ? const Center(child: CircularProgressIndicator())
                            : guestsList.isEmpty
                                ? const Center(child: Text('Không có khách nào.'))
                                : ListView.builder(
                                    itemCount: guestsList.length,
                                    itemBuilder: (context, index) {
                                      final doc = guestsList[index];
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
                                              Text('Chức vụ: ${fields['jobTitle']['stringValue']}'),
                                              Text('Trạng thái: ${fields['status']['stringValue']}'),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Biểu mẫu chỉnh sửa người dùng
class EditUserForm extends StatefulWidget {
  final Map<String, dynamic> initialData;
  final Function(Map<String, dynamic>) onSave;

  const EditUserForm({super.key, required this.initialData, required this.onSave});

  @override
  _EditUserFormState createState() => _EditUserFormState();
}

class _EditUserFormState extends State<EditUserForm> {
  late TextEditingController nameController;
  late TextEditingController emailController;
  late TextEditingController phoneController;
  // Thêm các controller khác tùy thuộc vào vai trò

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.initialData['fullName']['stringValue']);
    emailController = TextEditingController(text: widget.initialData['email']['stringValue']);
    phoneController = TextEditingController(text: widget.initialData['phone']['stringValue']);
    // Khởi tạo các controller khác
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    // Dispose các controller khác
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: 'Họ tên'),
        ),
        TextField(
          controller: emailController,
          decoration: const InputDecoration(labelText: 'Email'),
        ),
        TextField(
          controller: phoneController,
          decoration: const InputDecoration(labelText: 'Số điện thoại'),
        ),
        // Thêm các trường khác
        const SizedBox(height: 10),
        ElevatedButton(
          onPressed: () {
            // Thu thập dữ liệu đã chỉnh sửa
            Map<String, dynamic> updatedData = {
              // **Lưu ý:** Không nên bao bọc giá trị trong 'stringValue' ở đây
              'fullName': nameController.text,
              'email': emailController.text,
              'phone': phoneController.text,
              // Thêm các trường khác
            };

            // **Debug:** In dữ liệu trước khi gửi
            // print('Updated Data: $updatedData');

            widget.onSave(updatedData);
          },
          child: const Text('Lưu'),
        ),
      ],
    );
  }
}
