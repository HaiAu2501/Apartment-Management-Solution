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
  List<dynamic> queueList = [];
  bool isLoadingQueue = false;
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

  // Hàm lấy danh sách chờ duyệt
  Future<void> fetchQueue() async {
    setState(() {
      isLoadingQueue = true;
    });

    try {
      List<dynamic> fetchedQueue = await widget.adminRepository.fetchQueue(widget.idToken);
      if (!mounted) return; // Kiểm tra nếu widget vẫn còn mount
      setState(() {
        queueList = fetchedQueue;
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

  // Hàm phê duyệt người dùng từ queue
  Future<void> approveUser(String queueDocName, Map<String, dynamic> queueData) async {
    widget.onMessage(null); // Bỏ thông báo hiện tại

    try {
      await widget.adminRepository.approveUser(queueDocName, queueData, widget.idToken, widget.authService);
      if (!mounted) return; // Kiểm tra nếu widget vẫn còn mount
      widget.onMessage('Phê duyệt thành công.');
      fetchQueue();
      String role = queueData['role']['stringValue'];
      if (role == 'Cư dân') {
        // Cập nhật danh sách cư dân nếu cần
      } else {
        // Cập nhật danh sách khách nếu cần
      }
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

  @override
  Widget build(BuildContext context) {
    if (isLoadingQueue) {
      return const Center(child: CircularProgressIndicator());
    }

    if (queueList.isEmpty) {
      return const Center(child: Text('Không có yêu cầu nào đang chờ duyệt.'));
    }

    return ListView.builder(
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
    );
  }
}
