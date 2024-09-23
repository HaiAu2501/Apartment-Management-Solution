// admin/home/home_page.dart
import 'package:flutter/material.dart';
import '../../authentication/data/authentication_service.dart';
import '../../authentication/presentation/login_page.dart';
import '../dashboard/dashboard_page.dart';
import '../events/events_page.dart';
import '../fees/fees_page.dart';
import '../users/users_page.dart';

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
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedIndex = 0;
  bool isSidebarExpanded = true;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      const EmptyPage(),
      const DashboardPage(),
      UsersPage(
        authService: widget.authService,
        idToken: widget.idToken,
        uid: widget.uid,
      ),
      const FeesPage(),
      const EventsPage(),
      // Đăng xuất được xử lý riêng
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

  // Hàm xử lý khi chọn một mục trong sidebar
  void _onSelectItem(int index) {
    if (index == 5) {
      // Đăng xuất
      logout();
    } else {
      setState(() {
        _selectedIndex = index;
      });
      if (!isDesktop) {
        Navigator.of(context).pop(); // Đóng Drawer nếu đang trên mobile
      }
    }
  }

  // Hàm toggle sidebar
  void _toggleSidebar() {
    setState(() {
      isSidebarExpanded = !isSidebarExpanded;
    });
  }

  // Xác định xem hiện tại đang trên desktop hay mobile
  bool get isDesktop => MediaQuery.of(context).size.width >= 650;

  // Widget xây dựng Sidebar tùy chỉnh
  Widget _buildSidebar(double screenWidth) {
    double sidebarWidth = isSidebarExpanded
        ? (screenWidth * 0.3)
            .clamp(150.0, 250.0) // Chiều rộng tối đa 250, tối thiểu 150
        : (screenWidth * 0.1).clamp(50.0, 100.0); // Khi thu gọn

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      width: sidebarWidth,
      color: Colors.grey[200],
      child: Column(
        children: [
          // Icon để co lại hoặc mở rộng sidebar (chỉ trên desktop)
          if (isDesktop)
            IconButton(
              icon: Icon(
                isSidebarExpanded ? Icons.arrow_back : Icons.arrow_forward,
                color: Colors.black,
              ),
              onPressed: _toggleSidebar,
              tooltip:
                  isSidebarExpanded ? 'Thu nhỏ Sidebar' : 'Mở rộng Sidebar',
            ),
          if (isDesktop) const SizedBox(height: 20),
          // Các mục menu
          Expanded(
            child: ListView(
              children: [
                _buildMenuItem(Icons.home, 'Trang chủ', 0),
                _buildMenuItem(Icons.dashboard, 'Bảng điều khiển', 1),
                _buildMenuItem(Icons.person, 'Người dùng', 2),
                _buildMenuItem(Icons.payment, 'Phí và Tài chính', 3),
                _buildMenuItem(Icons.event, 'Sự kiện', 4),
                _buildMenuItem(Icons.logout, 'Đăng xuất', 5),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Hàm xây dựng một mục menu
  Widget _buildMenuItem(IconData icon, String title, int index) {
    bool isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () {
        _onSelectItem(index);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        padding: isSidebarExpanded
            ? const EdgeInsets.symmetric(horizontal: 8, vertical: 12)
            : const EdgeInsets.all(12), // Đều padding khi thu gọn
        decoration: isSelected
            ? BoxDecoration(
                color: Colors.green[100], // Nền xanh lá nhạt khi chọn
                borderRadius: BorderRadius.circular(8), // Bo góc
              )
            : null,
        child: Row(
          mainAxisAlignment: isSidebarExpanded
              ? MainAxisAlignment.start
              : MainAxisAlignment.center,
          crossAxisAlignment:
              CrossAxisAlignment.center, // Căn giữa theo trục dọc
          children: [
            Icon(
              icon,
              color: Colors.black, // Màu icon
              size: 24, // Điều chỉnh kích thước icon nếu cần
            ),
            if (isSidebarExpanded) ...[
              const SizedBox(width: 16),
              Flexible(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.black, // Màu chữ
                    fontWeight: FontWeight.normal,
                  ),
                  overflow: TextOverflow.ellipsis, // Tràn dòng nếu quá dài
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool desktop = isDesktop;
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      key: _scaffoldKey, // Thiết lập GlobalKey cho Scaffold
      drawer: desktop ? null : Drawer(child: _buildSidebar(screenWidth)),
      appBar: AppBar(
        title: const Text('Trang Chủ Admin'),
        backgroundColor: Colors.grey[850],
        leading: desktop
            ? null
            : IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                tooltip: 'Mở Menu',
              ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: logout,
            tooltip: 'Đăng xuất',
          )
        ],
      ),
      body: SafeArea(
        child: Row(
          children: [
            if (desktop)
              _buildSidebar(screenWidth), // Hiển thị sidebar luôn trên desktop
            Expanded(
              child: _pages[_selectedIndex], // Nội dung chính
            ),
          ],
        ),
      ),
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
