// admin/home/home_page.dart
import 'package:flutter/material.dart';
import 'package:animated_sidebar/animated_sidebar.dart'; // Import thư viện animated_sidebar
import '../../.authentication/data/auth_service.dart';
import '../../.authentication/presentation/login_page.dart';
import 'dashboard_page.dart';
import 'events_page.dart';
import 'fees_page.dart';
import 'users_page.dart';

class AdminHomePage extends StatefulWidget {
  final AuthenticationService authService;
  final String idToken;
  final String uid;

  const AdminHomePage({
    Key? key,
    required this.authService,
    required this.idToken,
    required this.uid,
  }) : super(key: key);

  @override
  _AdminHomePageState createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  // Chỉ số để quản lý trang hiện tại
  int _selectedIndex = 0;

  // Danh sách các trang tương ứng với sidebar
  late final List<Widget> _pages;

  // Danh sách các mục trong sidebar
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
      // Loại bỏ phần children để UsersPage không có child side_items
    ),
    SidebarItem(
      text: 'Phí và Tài chính',
      icon: Icons.payment_outlined,
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
      const EventsPage(), // 4: Sự kiện
      // 5: Đăng xuất sẽ được xử lý riêng
    ];
  }

  // Hàm logout
  Future<void> logout() async {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => LoginPage(authService: widget.authService),
      ),
    );
  }

  // Hàm xử lý khi chọn một mục trong sidebar hoặc drawer
  void _onSelectItem(int index) {
    if (index == 5) {
      // Đăng xuất
      logout();
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  // Widget cho Sidebar với thiết kế đẹp hơn bằng animated_sidebar
  Widget _buildAnimatedSidebar() {
    return AnimatedSidebar(
      items: _sidebarItems,
      selectedIndex: _selectedIndex,
      onItemSelected: _onSelectItem,
      minSize: 70, // Chiều rộng khi sidebar thu gọn
      maxSize: 200, // Chiều rộng khi sidebar mở rộng
      expanded: true, // Khởi tạo sidebar ở trạng thái mở rộng
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
      itemSelectedColor: Color.fromRGBO(161, 214, 178, 1),
      itemHoverColor: Color.fromRGBO(161, 214, 178, 0.25),
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

  Widget _buildDrawer() {
    return Drawer(
      child: Container(
        color: Colors.white,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color.fromARGB(255, 142, 254, 142),
                    const Color.fromARGB(255, 255, 250, 152),
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
                  const SizedBox(height: 10),
                  const Text(
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
                contentPadding: EdgeInsets.symmetric(horizontal: 25.0, vertical: 4.0), // Tùy chỉnh padding
                title: Row(
                  children: [
                    Icon(
                      item.icon,
                      color: Colors.grey[850],
                      size: 24,
                    ),
                    SizedBox(width: 25), // Khoảng cách giữa icon và text
                    Text(
                      item.text,
                      style: const TextStyle(color: Color.fromRGBO(0, 0, 0, 1)),
                    ),
                  ],
                ),
                onTap: () {
                  Navigator.pop(context); // Đóng Drawer
                  _onSelectItem(index);
                },
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Đặt breakpoint ở 600 pixels
        if (constraints.maxWidth >= 600) {
          // Desktop layout
          return Scaffold(
            body: Row(
              children: [
                // Sidebar
                _buildAnimatedSidebar(),
                // Nội dung chính
                Expanded(
                  child: Scaffold(
                    appBar: AppBar(
                      title: const Text('Trang Chủ Admin'),
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
              // title: const Text('Trang Chủ Admin'),
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

// Widget cho Trang Chủ trống
class EmptyPage extends StatelessWidget {
  const EmptyPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Trang chủ đang được phát triển...',
        style: TextStyle(fontSize: 18, color: Colors.grey[700]),
      ),
    );
  }
}
