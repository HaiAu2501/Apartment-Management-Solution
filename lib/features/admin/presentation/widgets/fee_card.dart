// lib/features/admin/presentation/widgets/fee_card.dart

import 'package:flutter/material.dart';
import '../../data/fees_repository.dart';
import 'package:intl/intl.dart';

class FeeCard extends StatefulWidget {
  final Map<String, dynamic> fee;
  final FeesRepository feesRepository;
  final String idToken;
  final Function() onUpdate; // Callback để thông báo FeeTable cập nhật dữ liệu
  final Function() onDelete; // Callback để thông báo FeeTable cập nhật dữ liệu

  const FeeCard({
    Key? key,
    required this.fee,
    required this.feesRepository,
    required this.idToken,
    required this.onUpdate,
    required this.onDelete,
  }) : super(key: key);

  @override
  _FeeCardState createState() => _FeeCardState();
}

class _FeeCardState extends State<FeeCard> {
  bool isEditing = false;
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _amountController;
  String frequency = 'Hàng tháng';
  DateTime? dueDate;

  // Biến lưu trữ giá trị gốc để khôi phục khi hủy chỉnh sửa
  late String originalName;
  late String originalDescription;
  late String originalAmount;
  late String originalFrequency;
  late DateTime? originalDueDate;

  @override
  void initState() {
    super.initState();
    final fields = widget.fee['fields'];
    originalName = fields['name']['stringValue'] ?? '';
    originalDescription = fields['description']['stringValue'] ?? '';
    originalAmount = fields['amount']['integerValue']?.toString() ?? '0';
    originalFrequency = fields['frequency']['stringValue'] ?? 'Hàng tháng';
    originalDueDate = fields['dueDate']['timestampValue'] != null ? DateTime.parse(fields['dueDate']['timestampValue']).toLocal() : null;

    _nameController = TextEditingController(text: originalName);
    _descriptionController = TextEditingController(text: originalDescription);
    _amountController = TextEditingController(text: originalAmount);
    frequency = originalFrequency;
    dueDate = originalDueDate;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _saveEdit() async {
    if (_nameController.text.trim().isEmpty || _amountController.text.trim().isEmpty || dueDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng điền đầy đủ thông tin.')),
      );
      return;
    }

    if (int.tryParse(_amountController.text.trim()) == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Số tiền phải là số.')),
      );
      return;
    }

    if (_amountController.text.trim().length > 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Số tiền quá lớn.')),
      );
      return;
    }

    if (_amountController.text.trim().startsWith('-')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Số tiền không thể âm.')),
      );
      return;
    }

    Map<String, dynamic> updatedData = {
      'name': _nameController.text.trim(),
      'description': _descriptionController.text.trim(),
      'amount': int.parse(_amountController.text.trim()),
      'frequency': frequency,
      'commonFee': true,
      'dueDate': dueDate, // giữ dưới dạng DateTime
    };

    try {
      await widget.feesRepository.updateFee(widget.fee['name'], updatedData, widget.idToken);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cập nhật khoản phí thành công.')),
      );
      setState(() {
        isEditing = false;
        // Cập nhật giá trị gốc sau khi lưu
        originalName = _nameController.text.trim();
        originalDescription = _descriptionController.text.trim();
        originalAmount = _amountController.text.trim();
        originalFrequency = frequency;
        originalDueDate = dueDate;
      });
      widget.onUpdate(); // Thông báo FeeTable để cập nhật dữ liệu
    } catch (e) {
      print('Lỗi khi cập nhật khoản phí: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    }
  }

  Future<void> _selectDueDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: dueDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        dueDate = picked;
      });
    }
  }

  Future<void> _deleteFee() async {
    bool confirm = false;
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận'),
        content: const Text('Bạn có chắc chắn muốn xóa khoản phí này không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Huỷ'),
          ),
          TextButton(
            onPressed: () {
              confirm = true;
              Navigator.of(context).pop();
            },
            child: const Text(
              'Xóa',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirm) {
      try {
        await widget.feesRepository.deleteFee(widget.fee['name'], widget.idToken);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Xóa khoản phí thành công.')),
        );
        widget.onDelete(); // Thông báo FeeTable để cập nhật dữ liệu
      } catch (e) {
        print('Lỗi khi xóa khoản phí: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    }
  }

  // Hàm khôi phục các trường về giá trị gốc
  void _cancelEdit() {
    setState(() {
      _nameController.text = originalName;
      _descriptionController.text = originalDescription;
      _amountController.text = originalAmount;
      frequency = originalFrequency;
      dueDate = originalDueDate;
      isEditing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      // Bọc Card trong IntrinsicHeight để đảm bảo chiều cao tự động điều chỉnh
      child: Card(
        margin: EdgeInsets.zero, // Loại bỏ margin giữa các Card
        elevation: 0, // Loại bỏ hiệu ứng đổ bóng
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.zero, // Loại bỏ bo góc
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0), // Đệm trong Card
          child: isEditing ? _buildEditForm() : _buildDisplayCard(),
        ),
      ),
    );
  }

  Widget _buildDisplayCard() {
    final dueDateString = dueDate != null ? DateFormat('dd/MM/yyyy').format(dueDate!) : 'Chọn ngày';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Tên Phí
        Expanded(
          flex: 2,
          child: Text(
            _nameController.text,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(width: 16),
        // Mô Tả
        Expanded(
          flex: 5,
          child: Text(
            _descriptionController.text,
            style: const TextStyle(fontSize: 16),
            textAlign: TextAlign.justify,
          ),
        ),
        const SizedBox(width: 16),
        // Số Tiền (Căn lề trái)
        Expanded(
          flex: 2,
          child: Text(
            '${_amountController.text}',
            style: const TextStyle(fontSize: 16),
            textAlign: TextAlign.center, // Căn lề trái
          ),
        ),
        const SizedBox(width: 16),
        // Tần Suất
        Expanded(
          flex: 2,
          child: Text(
            frequency,
            style: const TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(width: 16),
        // Ngày Đến Hạn
        Expanded(
          flex: 2,
          child: Text(
            dueDateString,
            style: const TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(width: 16),
        // Thao Tác: IconButtons
        Expanded(
          flex: 1,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
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
                onPressed: _deleteFee,
                tooltip: 'Xóa',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEditForm() {
    final dueDateString = dueDate != null ? DateFormat('dd/MM/yyyy').format(dueDate!) : 'Chọn ngày';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch, // Đảm bảo các widget con kéo dài theo chiều dọc
      children: [
        // Tên Phí
        Expanded(
          flex: 2,
          child: TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Tên Phí',
              border: OutlineInputBorder(),
            ),
            maxLines: 2, // Cho phép nhiều dòng nếu nội dung dài
            minLines: 1,
            expands: false, // Không mở rộng tự động theo chiều dọc
          ),
        ),
        const SizedBox(width: 16),
        // Mô Tả
        Expanded(
          flex: 5,
          child: TextField(
            controller: _descriptionController,
            decoration: const InputDecoration(
              labelText: 'Mô Tả',
              border: OutlineInputBorder(),
            ),
            maxLines: 3, // Cho phép nhiều dòng nếu nội dung dài
            minLines: 1,
            expands: false,
          ),
        ),
        const SizedBox(width: 16),
        // Số Tiền
        Expanded(
          flex: 2,
          child: TextField(
            controller: _amountController,
            decoration: const InputDecoration(
              labelText: 'Số Tiền (kVNĐ)',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center, // Căn giữa nội dung
          ),
        ),
        const SizedBox(width: 16),
        // Tần Suất
        Expanded(
          flex: 2,
          child: DropdownButtonFormField<String>(
            value: frequency,
            decoration: const InputDecoration(
              labelText: 'Tần Suất',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(
                value: 'Hàng tuần',
                child: Text('Hàng tuần'),
              ),
              DropdownMenuItem(
                value: 'Hàng tháng',
                child: Text('Hàng tháng'),
              ),
              DropdownMenuItem(
                value: 'Hàng quý',
                child: Text('Hàng quý'),
              ),
              DropdownMenuItem(
                value: 'Hàng năm',
                child: Text('Hàng năm'),
              ),
              DropdownMenuItem(
                value: 'Một lần',
                child: Text('Một lần'),
              ),
              DropdownMenuItem(
                value: 'Không bắt buộc',
                child: Text('Không bắt buộc'),
              ),
              DropdownMenuItem(
                value: 'Khác',
                child: Text('Khác'),
              )
            ],
            onChanged: (value) {
              setState(() {
                frequency = value!;
              });
            },
          ),
        ),
        const SizedBox(width: 16),
        // Ngày Đến Hạn
        Expanded(
          flex: 2,
          child: InkWell(
            onTap: _selectDueDate,
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Ngày Đến Hạn',
                border: OutlineInputBorder(),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    dueDate != null ? dueDateString : 'Chọn ngày',
                    style: TextStyle(
                      color: dueDate != null ? Colors.black : Colors.grey[600],
                    ),
                  ),
                  const Icon(Icons.calendar_today),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        // Thao Tác: IconButtons (Save và Cancel)
        Expanded(
          flex: 1,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.save, color: Colors.green),
                onPressed: _saveEdit,
                tooltip: 'Lưu',
              ),
              IconButton(
                icon: const Icon(Icons.cancel, color: Colors.grey),
                onPressed: _cancelEdit, // Sử dụng hàm khôi phục
                tooltip: 'Huỷ',
              ),
            ],
          ),
        ),
      ],
    );
  }
}
