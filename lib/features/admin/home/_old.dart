// admin/home/home_page.dart
import 'package:flutter/material.dart';
import 'package:animated_sidebar/animated_sidebar.dart'; // Import thư viện animated_sidebar
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
  // Chỉ số để quản lý trang hiện tại
  int _selectedIndex = 0;

  // Danh sách các trang tương ứng với sidebar
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      const EmptyPage(), // Trang chủ trống
      const DashboardPage(),
      UsersPage(
        authService: widget.authService,
        idToken: widget.idToken,
        uid: widget.uid,
      ),
      const FeesPage(),
      const EventsPage(),
      // Đăng xuất sẽ được xử lý riêng
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
    }
  }

  // Widget cho Sidebar với thiết kế đẹp hơn bằng animated_sidebar
  Widget _buildSidebar() {
    return AnimatedSidebar(
      items: [
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
          text: 'Sự kiện',
          icon: Icons.event_outlined,
        ),
        SidebarItem(
          text: 'Đăng xuất',
          icon: Icons.logout_outlined,
        ),
      ],
      selectedIndex: _selectedIndex,
      onItemSelected: _onSelectItem,
      minSize: 70, // Chiều rộng khi sidebar thu gọn
      maxSize: 200, // Chiều rộng khi sidebar mở rộng
      expanded: true, // Khởi tạo sidebar ở trạng thái mở rộng
      margin: const EdgeInsets.all(16),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      itemIconSize: 24,
      itemIconColor: Colors.white,
      itemTextStyle: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: Colors.white,
      ),
      itemSpaceBetween: 12,
      itemSelectedColor: Colors.indigoAccent,
      itemHoverColor: Colors.indigoAccent.withOpacity(0.3),
      itemSelectedBorder: BorderRadius.circular(8),
      itemMargin: 12,
      switchIconExpanded: Icons.arrow_back_ios_new,
      switchIconCollapsed: Icons.arrow_forward_ios,
      frameDecoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(10),
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
      headerText: 'Admin',
      headerIconSize: 28,
      headerIconColor: Colors.blueAccent,
      headerTextStyle: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Sử dụng Row để đặt Sidebar và nội dung chính bên cạnh
      body: Row(
        children: [
          // Sidebar
          _buildSidebar(),
          // Nội dung chính
          Expanded(
            child: Scaffold(
              appBar: AppBar(
                title: const Text('Trang Chủ Admin'),
                backgroundColor: Colors.grey[850],
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
