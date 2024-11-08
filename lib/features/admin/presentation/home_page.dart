// admin/home/home_page.dart

import 'package:flutter/material.dart';
import 'package:animated_sidebar/animated_sidebar.dart';
import '../../.authentication/data/auth_service.dart';
import '../../.authentication/presentation/login_page.dart';
import 'dashboard_page.dart';
import 'events_page.dart';
import 'fees_page.dart';
import 'users_page.dart';
import 'complaints_page.dart';
import 'widgets/weather.dart'; // Updated import

class AdminHomePage extends StatefulWidget {
  final AuthenticationService authService;
  final String idToken;
  final String uid;

  const AdminHomePage({
    super.key,
    required this.authService,
    required this.idToken,
    required this.uid,
  });

  @override
  _AdminHomePageState createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  int _selectedIndex = 0;
  late final List<Widget> _pages;

  final List<SidebarItem> _sidebarItems = [
    SidebarItem(
      text: 'Trang chủ',
      icon: Icons.home_outlined,
    ),
    SidebarItem(
      text: 'Bảng điều khiển',
      icon: Icons.dashboard_outlined,
    ),
    SidebarItem(
      text: 'Người dùng',
      icon: Icons.person_outline,
    ),
    SidebarItem(
      text: 'Phí và Tài chính',
      icon: Icons.payment_outlined,
    ),
    SidebarItem(
      text: 'Khiếu nại',
      icon: Icons.mail_outlined,
    ),
    SidebarItem(
      text: 'Sự kiện',
      icon: Icons.event_outlined,
    ),
    SidebarItem(
      text: 'Đăng xuất',
      icon: Icons.logout_outlined,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pages = [
      const EmptyPage(), // 0: Trang chủ trống
      const DashboardPage(), // 1: Bảng điều khiển
      UsersPage(
        authService: widget.authService,
        idToken: widget.idToken,
        uid: widget.uid,
      ), // 2: Người dùng
      const FeesPage(), // 3: Phí và Tài chính
       ComplaintsPage(authService: widget.authService,), // 4: Tiện ích và Khiếu nại
      EventsPage(
        authService: widget.authService,
      ), // 5: Sự kiện
      // 6: Đăng xuất sẽ được xử lý riêng
    ];
  }

  /// Logout function
  Future<void> logout() async {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => LoginPage(authService: widget.authService),
      ),
    );
  }

  /// Handle sidebar item selection
  void _onSelectItem(int index) {
    if (index == 6) {
      // Logout
      logout();
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  /// Build the animated sidebar
  Widget _buildAnimatedSidebar() {
    return AnimatedSidebar(
      items: _sidebarItems,
      selectedIndex: _selectedIndex,
      onItemSelected: _onSelectItem,
      minSize: 70,
      maxSize: 200,
      expanded: true,
      margin: const EdgeInsets.all(0),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      itemIconSize: 24,
      itemIconColor: Colors.black,
      itemTextStyle: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: Colors.black,
      ),
      itemSpaceBetween: 12,
      itemSelectedColor: const Color.fromRGBO(161, 214, 178, 1),
      itemHoverColor: const Color.fromRGBO(161, 214, 178, 0.25),
      itemSelectedBorder: BorderRadius.circular(8),
      itemMargin: 12,
      switchIconExpanded: Icons.arrow_back_ios_new,
      switchIconCollapsed: Icons.arrow_forward_ios,
      frameDecoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(0),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(66, 66, 66, 0.75),
            spreadRadius: 0,
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      headerIcon: Icons.admin_panel_settings,
      headerText: 'QUẢN TRỊ VIÊN',
      headerIconSize: 28,
      headerIconColor: Colors.redAccent,
      headerTextStyle: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: Colors.redAccent,
      ),
    );
  }

  /// Build the drawer for mobile layout
  Widget _buildDrawer() {
    return Drawer(
      child: Container(
        color: Colors.white,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color.fromARGB(255, 142, 254, 142),
                    Color.fromARGB(255, 255, 250, 152),
                  ],
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(
                    Icons.admin_panel_settings,
                    size: 40,
                    color: Colors.red,
                  ),
                  SizedBox(height: 10),
                  Text(
                    'QUẢN TRỊ VIÊN',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 24,
                    ),
                  ),
                ],
              ),
            ),
            ..._sidebarItems.asMap().entries.map((entry) {
              int index = entry.key;
              SidebarItem item = entry.value;

              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 25.0, vertical: 4.0),
                title: Row(
                  children: [
                    Icon(
                      item.icon,
                      color: Colors.grey[850],
                      size: 24,
                    ),
                    const SizedBox(width: 25),
                    Text(
                      item.text,
                      style: const TextStyle(color: Colors.black),
                    ),
                  ],
                ),
                onTap: () {
                  Navigator.pop(context); // Close Drawer
                  _onSelectItem(index);
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Define breakpoint at 600 pixels
        if (constraints.maxWidth >= 600) {
          // Desktop layout
          return Scaffold(
            body: Row(
              children: [
                // Sidebar
                _buildAnimatedSidebar(),
                // Main content
                Expanded(
                  child: Scaffold(
                    appBar: AppBar(
                      title: const Text('Trang chủ Quản trị viên'),
                      backgroundColor: Colors.white,
                      actions: [
                        IconButton(
                          icon: const Icon(Icons.logout),
                          onPressed: logout,
                          tooltip: 'Đăng xuất',
                        )
                      ],
                    ),
                    body: _pages[_selectedIndex],
                  ),
                ),
              ],
            ),
          );
        } else {
          // Mobile layout
          return Scaffold(
            appBar: AppBar(
              backgroundColor: Colors.white,
              leading: Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                  tooltip: 'Menu',
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.logout),
                  onPressed: logout,
                  tooltip: 'Đăng xuất',
                )
              ],
            ),
            drawer: _buildDrawer(),
            body: _pages[_selectedIndex],
          );
        }
      },
    );
  }
}

/// Widget for Empty Home Page
class EmptyPage extends StatelessWidget {
  const EmptyPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: const [
            SizedBox(height: 20),
            WeatherApiWidget(location: 'Hanoi'), // Updated widget
            SizedBox(height: 20),
            Text(
              'Trang chủ đang được phát triển...',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
