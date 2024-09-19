import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/resident_provider.dart';
import 'resident_list_page.dart';
import '../../../authentication/presentation/providers/auth_provider.dart';
import 'create_building_page.dart'; // Đảm bảo đường dẫn đúng

class AdminHomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return ChangeNotifierProvider(
      create: (_) => ResidentProvider()..fetchResidents(),
      child: Scaffold(
        appBar: AppBar(
          title: Text('Trang Quản Trị'),
          leading: IconButton(
            icon: Icon(Icons.menu),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          ),
        ),
        drawer: Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: BoxDecoration(
                  color: Colors.blue,
                ),
                child: Text(
                  'Menu',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                  ),
                ),
              ),
              ListTile(
                leading: Icon(Icons.dashboard),
                title: Text('Bảng Điều Khiển'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => AdminHomePage()),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.people),
                title: Text('Quản Lý Cư Dân'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ResidentListPage()),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.apartment),
                title: Text('Quản Lý Tòa Nhà'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => CreateBuildingPage()),
                  );
                },
              ),
              Divider(),
              ListTile(
                leading: Icon(Icons.logout),
                title: Text('Đăng Xuất'),
                onTap: () async {
                  await authProvider.logout();
                  Navigator.pushReplacementNamed(context, '/');
                },
              ),
            ],
          ),
        ),
        body: Center(
          child: Text('Chào mừng đến với trang quản trị!'),
        ),
      ),
    );
  }
}
