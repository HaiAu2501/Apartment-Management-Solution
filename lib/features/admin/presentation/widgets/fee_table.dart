// lib/features/admin/presentation/widgets/fee_table.dart

import 'package:flutter/material.dart';
import 'fee_card.dart';
import '../../data/fees_repository.dart';

class FeeTable extends StatefulWidget {
  final FeesRepository feesRepository;
  final String idToken;
  final VoidCallback onAddFee; // Thêm tham số callback

  const FeeTable({
    Key? key,
    required this.feesRepository,
    required this.idToken,
    required this.onAddFee, // Nhận callback
  }) : super(key: key);

  @override
  FeeTableState createState() => FeeTableState();
}

class FeeTableState extends State<FeeTable> {
  late Future<List<dynamic>> _feesFuture;

  @override
  void initState() {
    super.initState();
    _feesFuture = widget.feesRepository.fetchAllFees(widget.idToken);
  }

  // Phương thức để refresh dữ liệu
  void refreshFees() {
    setState(() {
      _feesFuture = widget.feesRepository.fetchAllFees(widget.idToken);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Định nghĩa các tên cột với tỷ lệ mới
    final List<String> columnNames = [
      'Tên Phí',
      'Mô Tả',
      'Số Tiền (kVNĐ)',
      'Tần Suất',
      'Ngày Đến Hạn',
      'Thao Tác',
    ];

    return FutureBuilder<List<dynamic>>(
      future: _feesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Lỗi: ${snapshot.error}'));
        }
        final fees = snapshot.data ?? [];

        if (fees.isEmpty) {
          return const Center(child: Text('Không có khoản phí nào.'));
        }

        return Column(
          children: [
            // Header Row
            Container(
              color: Colors.grey[300],
              padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
              child: Row(
                children: [
                  // Tên Phí
                  Expanded(
                    flex: 2,
                    child: Text(
                      columnNames[0],
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Mô Tả
                  Expanded(
                    flex: 5,
                    child: Text(
                      columnNames[1],
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Số Tiền
                  Expanded(
                    flex: 2,
                    child: Text(
                      columnNames[2],
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Tần Suất
                  Expanded(
                    flex: 2,
                    child: Text(
                      columnNames[3],
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Ngày Đến Hạn
                  Expanded(
                    flex: 2,
                    child: Text(
                      columnNames[4],
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Thao Tác - Biến đổi thành PopupMenuButton
                  Expanded(
                    flex: 1,
                    child: PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert),
                      onSelected: (value) {
                        if (value == 'add') {
                          widget.onAddFee(); // Gọi hàm callback để thêm khoản phí mới
                        }
                        // Bạn có thể thêm các tùy chọn khác ở đây nếu cần
                      },
                      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                        const PopupMenuItem<String>(
                          value: 'add',
                          child: Text('Thêm khoản phí mới'),
                        ),
                        // Thêm các tùy chọn khác nếu cần
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Divider giữa header và danh sách
            const Divider(height: 1, thickness: 1),
            // Danh sách FeeCards với Divider giữa các Card
            Expanded(
              child: ListView.separated(
                itemCount: fees.length,
                separatorBuilder: (context, index) => const Divider(height: 1, thickness: 1),
                itemBuilder: (context, index) {
                  final fee = fees[index];
                  return FeeCard(
                    fee: fee,
                    feesRepository: widget.feesRepository,
                    idToken: widget.idToken,
                    onUpdate: refreshFees,
                    onDelete: refreshFees,
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
