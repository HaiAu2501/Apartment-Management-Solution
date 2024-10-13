// lib/features/admin/presentation/widgets/edit_user_form.dart
import 'package:flutter/material.dart';

class EditUserForm extends StatefulWidget {
  final Map<String, dynamic> initialData;
  final Function(Map<String, dynamic>) onSave;

  const EditUserForm({
    super.key,
    required this.initialData,
    required this.onSave,
  });

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
