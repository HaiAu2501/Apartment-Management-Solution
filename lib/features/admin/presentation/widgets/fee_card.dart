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

  @override
  void initState() {
    super.initState();
    final fields = widget.fee['fields'];
    _nameController = TextEditingController(text: fields['name']['stringValue'] ?? '');
    _descriptionController = TextEditingController(text: fields['description']['stringValue'] ?? '');
    _amountController = TextEditingController(text: fields['amount']['integerValue']?.toString() ?? '0');
    frequency = fields['frequency']['stringValue'] ?? 'Hàng tháng';
    dueDate = fields['dueDate']['timestampValue'] != null ? DateTime.parse(fields['dueDate']['timestampValue']).toLocal() : null;
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

  @override
  Widget build(BuildContext context) {
    final dueDateString = dueDate != null ? DateFormat('dd/MM/yyyy').format(dueDate!) : 'Chọn ngày';

    return Card(
      margin: EdgeInsets.zero, // Loại bỏ margin giữa các Card
      elevation: 0, // Loại bỏ hiệu ứng đổ bóng
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.zero, // Loại bỏ bo góc
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0), // Đệm trong Card
        child: isEditing ? _buildEditForm(dueDateString) : _buildDisplayCard(dueDateString),
      ),
    );
  }

  Widget _buildDisplayCard(String dueDateString) {
    return Row(
      children: [
        // Tên Phí
        Expanded(
          flex: 2, // Tỷ lệ rộng của cột
          child: Text(
            _nameController.text,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        // Vertical Divider
        VerticalDivider(
          color: Colors.grey,
          thickness: 1,
        ),
        // Mô Tả
        Expanded(
          flex: 5,
          child: Text(
            _descriptionController.text,
            style: const TextStyle(fontSize: 16),
            textAlign: TextAlign.justify,
          ),
        ),
        // Vertical Divider
        VerticalDivider(
          color: Colors.grey,
          thickness: 1,
        ),
        // Số Tiền (Căn lề trái)
        Expanded(
          flex: 2,
          child: Text(
            '${_amountController.text}',
            style: const TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ),
        // Vertical Divider
        VerticalDivider(
          color: Colors.grey,
          thickness: 1,
        ),
        // Tần Suất
        Expanded(
          flex: 2,
          child: Text(
            frequency,
            style: const TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ),
        // Vertical Divider
        VerticalDivider(
          color: Colors.grey,
          thickness: 1,
        ),
        // Ngày Đến Hạn
        Expanded(
          flex: 2,
          child: Text(
            dueDateString,
            style: const TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ),
        // Vertical Divider
        VerticalDivider(
          color: Colors.grey,
          thickness: 1,
        ),
        // Thao Tác
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

  Widget _buildEditForm(String dueDateString) {
    return Column(
      children: [
        Row(
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
              ),
            ),
            // Vertical Divider
            VerticalDivider(
              color: Colors.grey,
              thickness: 1,
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
                maxLines: 1,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
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
              ),
            ),
            // Vertical Divider
            VerticalDivider(
              color: Colors.grey,
              thickness: 1,
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
                ],
                onChanged: (value) {
                  setState(() {
                    frequency = value!;
                  });
                },
              ),
            ),
            // Vertical Divider
            VerticalDivider(
              color: Colors.grey,
              thickness: 1,
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
                        dueDate != null ? DateFormat('dd/MM/yyyy').format(dueDate!) : 'Chọn ngày',
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
          ],
        ),
        const SizedBox(height: 16),
        // Nút Lưu và Huỷ
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            ElevatedButton(
              onPressed: _saveEdit,
              child: const Text('Lưu'),
            ),
            const SizedBox(width: 16),
            TextButton(
              onPressed: () {
                setState(() {
                  isEditing = false;
                });
              },
              child: const Text('Huỷ'),
            ),
          ],
        ),
      ],
    );
  }
}
