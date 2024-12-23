// lib/resident/presentation/resident_home_page.dart

import 'package:flutter/material.dart';
import 'package:animated_sidebar/animated_sidebar.dart';
import '../../.authentication/data/auth_service.dart';
import '../../.authentication/presentation/login_page.dart';
import '../data/resident_repository.dart';
import 'profile_page.dart';
import 'fees_page.dart';
import 'events_page.dart';
import 'complaints_page.dart';

class ResidentHomePage extends StatefulWidget {
  final AuthenticationService authService;
  final String idToken;
  final String uid; // Thay đổi từ profileId thành uid

  const ResidentHomePage({
    super.key,
    required this.authService,
    required this.idToken,
    required this.uid, // Thêm uid
  });

  @override
  _ResidentHomePageState createState() => _ResidentHomePageState();
}

class _ResidentHomePageState extends State<ResidentHomePage> {
  int _selectedIndex = 0;
  late final List<Widget> _pages;

  final List<SidebarItem> _sidebarItems = [
    SidebarItem(
      text: 'Hồ sơ nhân khẩu',
      icon: Icons.person_outline,
    ),
    SidebarItem(
      text: 'Phí thanh toán',
      icon: Icons.payment_outlined,
    ),
    SidebarItem(
      text: 'Sự kiện',
      icon: Icons.event_outlined,
    ),
    SidebarItem(
      text: 'Khiếu nại',
      icon: Icons.mail_outlined,
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
      // Cung cấp uid, idToken và residentRepository cho ProfilePage
      ProfilePage(
        uid: widget.uid, // Truyền uid thay vì profileId
        idToken: widget.idToken,
        residentRepository: ResidentRepository(
          apiKey: widget.authService.apiKey, // Đảm bảo authService có apiKey
          projectId: widget.authService.projectId, // Đảm bảo authService có projectId
        ),
      ), // 0: Hồ sơ nhân khẩu
      const FeesPage(), // 1: Phí thanh toán
      EventsPage(
        authService: widget.authService,
      ), // 2: Sự kiện
      ComplaintsPage(
        authService: widget.authService,
      ), //3: Khiếu nại
      // 4: Đăng xuất sẽ được xử lý riêng
    ];
  }

  /// Hàm logout
  Future<void> logout() async {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => LoginPage(authService: widget.authService),
      ),
    );
  }

  /// Xử lý khi chọn mục trong sidebar
  void _onSelectItem(int index) {
    if (index == 4) {
      // Đăng xuất
      logout();
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  /// Xây dựng thanh sidebar hoạt hình
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
      headerIcon: Icons.person,
      headerText: 'CƯ DÂN',
      headerIconSize: 28,
      headerIconColor: Colors.blueAccent,
      headerTextStyle: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: Colors.blueAccent,
      ),
    );
  }

  /// Xây dựng drawer cho layout di động
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
                    Icons.person,
                    size: 40,
                    color: Colors.blue,
                  ),
                  SizedBox(height: 10),
                  Text(
                    'CƯ DÂN',
                    style: TextStyle(
                      color: Colors.blue,
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
                  Navigator.pop(context); // Đóng Drawer
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
        // Định nghĩa breakpoint tại 600 pixels
        if (constraints.maxWidth >= 600) {
          // Layout Desktop
          return Scaffold(
            body: Row(
              children: [
                // Sidebar
                _buildAnimatedSidebar(),
                // Nội dung chính
                Expanded(
                  child: Scaffold(
                    appBar: AppBar(
                      title: const Text('Trang Chủ Cư Dân'),
                      backgroundColor: Colors.white,
                    ),
                    body: _pages[_selectedIndex],
                  ),
                ),
              ],
            ),
          );
        } else {
          // Layout Di động
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
              title: const Text('Trang Chủ Cư Dân', style: TextStyle(color: Colors.black)),
              iconTheme: const IconThemeData(color: Colors.black),
              actions: [
                IconButton(
                  icon: const Icon(Icons.logout),
                  onPressed: () => logout(),
                  tooltip: 'Đăng xuất',
                ),
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
