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

  // Widget cho Sidebar với thiết kế đẹp hơn
  Widget _buildSidebar() {
    return NavigationRail(
      selectedIndex: _selectedIndex,
      onDestinationSelected: _onSelectItem,
      labelType: NavigationRailLabelType.all,
      backgroundColor: Colors.grey[900], // Nền tương phản
      selectedIconTheme: const IconThemeData(color: Colors.green),
      unselectedIconTheme: const IconThemeData(color: Colors.greenAccent),
      selectedLabelTextStyle:
          const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
      unselectedLabelTextStyle: const TextStyle(color: Colors.greenAccent),
      destinations: const [
        NavigationRailDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: Text('Trang chủ'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.dashboard_outlined),
          selectedIcon: Icon(Icons.dashboard),
          label: Text('Bảng điều khiển'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person),
          label: Text('Người dùng'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.payment_outlined),
          selectedIcon: Icon(Icons.payment),
          label: Text('Phí và Tài chính'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.event_outlined),
          selectedIcon: Icon(Icons.event),
          label: Text('Sự kiện'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.logout_outlined),
          selectedIcon: Icon(Icons.logout),
          label: Text('Đăng xuất'),
        ),
      ],
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
