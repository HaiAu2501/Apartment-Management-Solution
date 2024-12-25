// lib/features/admin/presentation/fees_page.dart

import 'package:flutter/material.dart';
import 'tabs/finance_tab.dart';
import 'tabs/fees_tab.dart';
import 'tabs/donations_tab.dart';
import '../data/fees_repository.dart';
import '../data/table_repository.dart';
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

class _FeesPageState extends State<FeesPage> with SingleTickerProviderStateMixin {
  late FeesRepository feesRepository;
  late TableRepository tableRepository;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    // Khởi tạo FeesRepository sử dụng apiKey và projectId từ authService
    feesRepository = FeesRepository(
      apiKey: widget.authService.apiKey,
      projectId: widget.authService.projectId,
    );
    tableRepository = TableRepository(
      apiKey: widget.authService.apiKey,
      projectId: widget.authService.projectId,
    );
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Đặt TabBar ở đầu thân của Scaffold
          Container(
            color: Theme.of(context).primaryColor,
            child: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Thông tin chung'),
                Tab(text: 'Phí bắt buộc'),
                Tab(text: 'Khoản đóng góp'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                FinanceTab(
                  feesRepository: feesRepository,
                  authService: widget.authService,
                  idToken: widget.idToken,
                ),
                FeesTab(
                  tableRepository: tableRepository,
                  authService: widget.authService,
                  idToken: widget.idToken,
                ), // Placeholder cho tab "Phí bắt buộc"
                DonationsTab(
                  tableRepository: tableRepository,
                  authService: widget.authService,
                  idToken: widget.idToken,
                ), // Placeholder cho tab "Khoản đóng góp"
              ],
            ),
          ),
        ],
      ),
    );
  }
}
