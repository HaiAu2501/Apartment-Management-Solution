// lib/features/admin/presentation/tabs/finance_tab.dart

import 'package:flutter/material.dart';
import '../widgets/fee_table.dart';
import '../widgets/fee_form.dart';
import '../widgets/fee_statistics.dart';
import '../../data/fees_repository.dart';
import '../../../.authentication/data/auth_service.dart';

class FinanceTab extends StatefulWidget {
  final FeesRepository feesRepository;
  final AuthenticationService authService;
  final String idToken;

  const FinanceTab({
    Key? key,
    required this.feesRepository,
    required this.authService,
    required this.idToken,
  }) : super(key: key);

  @override
  _FinanceTabState createState() => _FinanceTabState();
}

class _FinanceTabState extends State<FinanceTab> {
  final GlobalKey<FeeTableState> _feeTableKey = GlobalKey<FeeTableState>();

  void _showFeeForm({String? documentPath}) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(documentPath == null ? 'Thêm Khoản Phí Mới' : 'Chỉnh Sửa Khoản Phí'),
          content: SizedBox(
            width: double.maxFinite,
            child: FeeForm(
              feesRepository: widget.feesRepository,
              idToken: widget.idToken,
              documentPath: documentPath,
            ),
          ),
        );
      },
    ).then((_) {
      // Cập nhật lại bảng sau khi đóng form
      _feeTableKey.currentState?.refreshFees();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          FeeStatistics(
            feesRepository: widget.feesRepository,
            idToken: widget.idToken,
          ), // Thêm widget thống kê với dữ liệu thực, // Thêm widget thống kê ở đây
          const SizedBox(height: 16),
          Expanded(
            child: FeeTable(
              key: _feeTableKey,
              feesRepository: widget.feesRepository,
              idToken: widget.idToken,
              onAddFee: _showFeeForm, // Truyền hàm callback
            ),
          ),
        ],
      ),
    );
  }
}
