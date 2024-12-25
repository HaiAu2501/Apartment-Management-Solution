// lib/features/admin/presentation/widgets/fee_form.dart

import 'package:flutter/material.dart';
import '../../data/fees_repository.dart';

class FeeForm extends StatefulWidget {
  final FeesRepository feesRepository;
  final String idToken;
  final String? documentPath; // null nếu thêm mới, không null nếu chỉnh sửa

  const FeeForm({
    Key? key,
    required this.feesRepository,
    required this.idToken,
    this.documentPath,
  }) : super(key: key);

  @override
  _FeeFormState createState() => _FeeFormState();
}

class _FeeFormState extends State<FeeForm> {
  final _formKey = GlobalKey<FormState>();

  // Sử dụng các TextEditingController để quản lý giá trị của các trường form
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _amountController;
  String frequency = 'Hàng tháng';
  DateTime? dueDate;

  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    // Khởi tạo các controller với giá trị rỗng hoặc giá trị hiện tại nếu đang chỉnh sửa
    _nameController = TextEditingController();
    _descriptionController = TextEditingController();
    _amountController = TextEditingController();

    if (widget.documentPath != null) {
      // Nếu đang chỉnh sửa, tải dữ liệu hiện tại của khoản phí
      _loadFeeData();
    }
  }

  @override
  void dispose() {
    // Giải phóng các controller khi widget bị huỷ
    _nameController.dispose();
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _loadFeeData() async {
    setState(() {
      isLoading = true;
    });

    try {
      final fee = await widget.feesRepository.fetchFeeByPath(widget.documentPath!, widget.idToken);

      // Kiểm tra cấu trúc dữ liệu trả về
      if (fee.containsKey('fields')) {
        final fields = fee['fields'];

        setState(() {
          _nameController.text = fields['name']['stringValue'] ?? '';
          _descriptionController.text = fields['description']['stringValue'] ?? '';
          _amountController.text = fields['amount']['integerValue']?.toString() ?? '';
          frequency = fields['frequency']['stringValue'] ?? 'Hàng tháng';
          dueDate = fields['dueDate']['timestampValue'] != null ? DateTime.parse(fields['dueDate']['timestampValue']).toLocal() : null;
          isLoading = false;
        });
      } else {
        throw Exception('Dữ liệu khoản phí không hợp lệ.');
      }
    } catch (e) {
      print('Lỗi khi tải dữ liệu khoản phí: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi tải dữ liệu: $e')),
      );
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate() && dueDate != null) {
      _formKey.currentState!.save();

      // Xác định 'commonFee' dựa trên 'frequency'
      bool commonFee = frequency != 'Không bắt buộc';

      // **Debug:** Kiểm tra giá trị của 'frequency' và 'commonFee'
      print('Frequency: $frequency');
      print('CommonFee: $commonFee');

      Map<String, dynamic> feeData = {
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'amount': int.parse(_amountController.text.trim()),
        'frequency': frequency,
        'commonFee': commonFee, // Thiết lập 'commonFee' chính xác
        'dueDate': dueDate, // giữ 'dueDate' dưới dạng DateTime
      };

      setState(() {
        isLoading = true;
      });

      try {
        if (widget.documentPath == null) {
          // Thêm mới
          await widget.feesRepository.addFee(feeData, widget.idToken);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Thêm khoản phí thành công.')),
          );
        } else {
          // Cập nhật
          await widget.feesRepository.updateFee(widget.documentPath!, feeData, widget.idToken);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cập nhật khoản phí thành công.')),
          );
        }
        Navigator.pop(context);
      } catch (e) {
        print('Lỗi khi gửi dữ liệu khoản phí: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      } finally {
        setState(() {
          isLoading = false;
        });
      }
    } else if (dueDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn ngày đến hạn.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Tên Phí
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Tên Phí',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập tên phí';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Mô Tả
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Mô Tả',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              // Số Tiền
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: 'Số Tiền (kVNĐ)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập số tiền';
                  }
                  if (value.trim().length > 10) {
                    return 'Số tiền quá lớn';
                  }
                  if (value.trim().startsWith('-')) {
                    return 'Số tiền không thể âm';
                  }
                  if (int.tryParse(value.trim()) == null) {
                    return 'Số tiền phải là số';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Tần Suất
              DropdownButtonFormField<String>(
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
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    frequency = value!;
                  });
                },
                onSaved: (value) {
                  frequency = value!;
                },
              ),
              const SizedBox(height: 16),
              // Ngày Đến Hạn
              InkWell(
                onTap: () async {
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
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Ngày Đến Hạn',
                    border: OutlineInputBorder(),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        dueDate != null ? "${dueDate!.day}/${dueDate!.month}/${dueDate!.year}" : 'Chọn ngày đến hạn',
                        style: TextStyle(
                          color: dueDate != null ? Colors.black : Colors.grey[600],
                        ),
                      ),
                      const Icon(Icons.calendar_today),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Nút Lưu và Hủy
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton(
                    onPressed: _submitForm,
                    child: const Text('Lưu'),
                  ),
                  const SizedBox(width: 16),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text('Hủy'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
