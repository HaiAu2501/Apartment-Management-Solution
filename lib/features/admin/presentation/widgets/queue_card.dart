// lib/features/admin/presentation/widgets/queue_card.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../widgets/edit_user_form.dart';
import '../../data/admin_repository.dart';
import '../../../.authentication/data/auth_service.dart';

class QueueCard extends StatefulWidget {
  final Map<String, dynamic> userData; // Đây là 'fields' từ Firestore
  final String docName;
  final AdminRepository adminRepository;
  final String idToken;
  final AuthenticationService authService;
  final Function(String?) onMessage;

  const QueueCard({
    Key? key,
    required this.userData,
    required this.docName,
    required this.adminRepository,
    required this.idToken,
    required this.authService,
    required this.onMessage,
  }) : super(key: key);

  @override
  _QueueCardState createState() => _QueueCardState();
}

class _QueueCardState extends State<QueueCard> {
  bool isExpanded = false;

  // Hàm phê duyệt người dùng
  Future<void> approveUser() async {
    widget.onMessage(null); // Bỏ thông báo hiện tại

    try {
      await widget.adminRepository.approveUser(
        widget.docName,
        widget.userData,
        widget.idToken,
        widget.authService,
      );
      if (!mounted) return;
      widget.onMessage('Phê duyệt thành công.');
      // Có thể thêm callback để cập nhật danh sách từ cha nếu cần
    } catch (e) {
      if (!mounted) return;
      widget.onMessage('Lỗi khi phê duyệt người dùng.');
      print('Lỗi khi phê duyệt user: $e');
    }
  }

  // Hàm từ chối người dùng
  Future<void> rejectUser() async {
    widget.onMessage(null); // Bỏ thông báo hiện tại

    try {
      await widget.adminRepository.rejectUser(
        widget.docName,
        widget.idToken,
        widget.authService,
      );
      if (!mounted) return;
      widget.onMessage('Đã từ chối người dùng.');
      // Có thể thêm callback để cập nhật danh sách từ cha nếu cần
    } catch (e) {
      if (!mounted) return;
      widget.onMessage('Lỗi khi từ chối người dùng.');
      print('Lỗi khi từ chối user: $e');
    }
  }

  // Hàm chỉnh sửa người dùng
  Future<void> editUser(Map<String, dynamic> updatedData) async {
    widget.onMessage(null); // Bỏ thông báo hiện tại

    try {
      await widget.adminRepository.updateQueueDocument(
        widget.docName,
        updatedData,
        widget.idToken,
      );
      if (!mounted) return;
      widget.onMessage('Đã cập nhật thông tin người dùng.');
      setState(() {
        isExpanded = false;
      });
      // Có thể thêm callback để cập nhật danh sách từ cha nếu cần
    } catch (e) {
      if (!mounted) return;
      widget.onMessage('Lỗi khi cập nhật thông tin.');
      print('Lỗi khi cập nhật user: $e');
    }
  }

  // Hàm định dạng ngày sinh
  String formatDob(String dobString) {
    try {
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
    final fields = widget.userData;
    final fullName = fields['fullName']?['stringValue'] ?? 'Không xác định';
    final email = fields['email']?['stringValue'] ?? 'Không xác định';
    final role = fields['role']?['stringValue'] ?? 'Không xác định';
    final phone = fields['phone']?['stringValue'] ?? 'Không xác định';
    final dob = fields['dob']?['stringValue'] ?? 'Không xác định';
    final id = fields['id']?['stringValue'] ?? 'Không xác định';
    final jobTitle = fields['jobTitle']?['stringValue'] ?? '';
    final floor = fields['floor']?['integerValue']?.toString() ?? '';
    final apartmentNumber = fields['apartmentNumber']?['integerValue']?.toString() ?? '';
    final status = fields['status']?['stringValue'] ?? 'Không xác định';

    return Column(
      children: [
        // Nội dung chính của QueueCard
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          child: Row(
            children: [
              // Họ và tên (Căn lề trái)
              Expanded(
                flex: 3,
                child: Text(
                  fullName,
                  style: const TextStyle(fontSize: 16),
                  textAlign: TextAlign.left, // Căn lề trái
                ),
              ),
              // Email (Căn lề trái)
              Expanded(
                flex: 4,
                child: Text(
                  email,
                  style: const TextStyle(fontSize: 16),
                  textAlign: TextAlign.left, // Căn lề trái
                ),
              ),
              // Vai trò (Căn lề trái)
              Expanded(
                flex: 2,
                child: Text(
                  role,
                  style: const TextStyle(fontSize: 16),
                  textAlign: TextAlign.center, // Căn lề trái
                ),
              ),
              // Số điện thoại (Căn lề trái)
              Expanded(
                flex: 3,
                child: Text(
                  phone,
                  style: const TextStyle(fontSize: 16),
                  textAlign: TextAlign.center, // Căn lề trái
                ),
              ),
              // Thao tác (Căn giữa các icon)
              Expanded(
                flex: 2,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center, // Căn giữa các icon
                  children: [
                    IconButton(
                      icon: const Icon(Icons.check, color: Colors.green),
                      tooltip: 'Phê duyệt',
                      onPressed: approveUser,
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.red),
                      tooltip: 'Từ chối',
                      onPressed: rejectUser,
                    ),
                    IconButton(
                      icon: const Icon(Icons.visibility, color: Colors.blue),
                      tooltip: 'Xem thêm',
                      onPressed: () {
                        setState(() {
                          isExpanded = !isExpanded;
                        });
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.orange),
                      tooltip: 'Chỉnh sửa',
                      onPressed: () {
                        setState(() {
                          isExpanded = !isExpanded;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Dòng mở rộng khi xem thêm hoặc chỉnh sửa
        if (isExpanded)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Ngày sinh: ${formatDob(dob)}'),
                Text('Số ID: $id'),
                if (role == 'Khách') Text('Chức vụ: $jobTitle'),
                if (role == 'Cư dân') ...[
                  Text('Tầng: $floor'),
                  Text('Căn hộ số: $apartmentNumber'),
                ],
                Text('Trạng thái: $status'),
                const SizedBox(height: 10),
                // Biểu mẫu chỉnh sửa
                EditUserForm(
                  initialData: fields,
                  onSave: (updatedData) {
                    editUser(updatedData);
                  },
                ),
                const Divider(),
              ],
            ),
          ),
      ],
    );
  }
}
