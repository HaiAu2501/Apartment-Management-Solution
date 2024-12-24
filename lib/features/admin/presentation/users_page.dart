// lib/features/admin/presentation/users_page.dart
import 'package:flutter/material.dart';
import '../../.authentication/data/auth_service.dart';
import '../data/admin_repository.dart';
import 'tabs/queue_tab.dart';
import 'tabs/residents_tab.dart';
import 'tabs/guests_tab.dart';

class UsersPage extends StatefulWidget {
  final AuthenticationService authService;
  final String idToken;
  final String uid;

  const UsersPage({
    super.key,
    required this.authService,
    required this.idToken,
    required this.uid,
  });

  @override
  _UsersPageState createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  late AdminRepository adminRepository;
  String? message;

  @override
  void initState() {
    super.initState();
    adminRepository = AdminRepository(
      apiKey: widget.authService.apiKey,
      projectId: widget.authService.projectId,
    );
  }

  // Hàm hiển thị thông báo
  Widget buildMessage() {
    if (message == null) return const SizedBox.shrink();
    return Text(
      message!,
      style: TextStyle(color: message!.contains('thành công') ? Colors.green : Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          // Hiển thị thông báo
          buildMessage(),
          const SizedBox(height: 20),
          // Tab để chuyển đổi giữa các danh sách
          Expanded(
            child: DefaultTabController(
              length: 3,
              child: Column(
                children: [
                  const TabBar(
                    labelColor: Colors.green,
                    indicatorColor: Colors.green,
                    tabs: [
                      Tab(text: 'Chờ duyệt'),
                      Tab(text: 'Cư dân'),
                      Tab(text: 'Khách'),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        // Tab 1: Danh Sách Chờ Duyệt
                        QueueTab(
                          adminRepository: adminRepository,
                          idToken: widget.idToken,
                          authService: widget.authService,
                          onMessage: (msg) {
                            // Đổi kiểu tham số thành String?
                            setState(() {
                              message = msg;
                            });
                          },
                        ),
                        // Tab 2: Danh Sách Cư Dân
                        ResidentsTab(
                          adminRepository: adminRepository,
                          idToken: widget.idToken,
                        ),
                        // Tab 3: Danh Sách Khách
                        GuestsTab(
                          adminRepository: adminRepository,
                          idToken: widget.idToken,
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
