// lib/features/admin/presentation/fees_page.dart

import 'package:flutter/material.dart';
import 'widgets/fee_table.dart';
import 'widgets/fee_form.dart';
import '../data/fees_repository.dart';
import '../../.authentication/data/auth_service.dart';
import '../../.authentication/presentation/login_page.dart';

class FeesPage extends StatefulWidget {
  final AuthenticationService authService;
  final String idToken;

  const FeesPage({
    Key? key,
    required this.authService,
    required this.idToken,
  }) : super(key: key);

  @override
  _FeesPageState createState() => _FeesPageState();
}

class _FeesPageState extends State<FeesPage> {
  late FeesRepository feesRepository;
  final GlobalKey<FeeTableState> _feeTableKey = GlobalKey<FeeTableState>();

  @override
  void initState() {
    super.initState();
    // Khởi tạo FeesRepository sử dụng apiKey và projectId từ authService
    feesRepository = FeesRepository(
      apiKey: widget.authService.apiKey,
      projectId: widget.authService.projectId,
    );
  }

  void _showFeeForm({String? documentPath}) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(documentPath == null ? 'Thêm Khoản Phí Mới' : 'Chỉnh Sửa Khoản Phí'),
          content: SizedBox(
            width: double.maxFinite,
            child: FeeForm(
              feesRepository: feesRepository,
              idToken: widget.idToken,
              documentPath: documentPath,
            ),
          ),
        );
      },
    ).then((_) {
      // Refresh the table after closing the form
      _feeTableKey.currentState?.refreshFees();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FeeTable(
        key: _feeTableKey,
        feesRepository: feesRepository,
        idToken: widget.idToken,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showFeeForm(),
        child: const Icon(Icons.add),
        tooltip: 'Thêm Khoản Phí',
      ),
    );
  }
}
