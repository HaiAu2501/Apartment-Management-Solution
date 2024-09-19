import 'package:flutter/material.dart';

class ResidentHomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Giao diện cho cư dân
      appBar: AppBar(
        title: Text('Trang Cư Dân'),
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
              leading: Icon(Icons.home),
              title: Text('Thông Tin Căn Hộ'),
              onTap: () {
                // Điều hướng đến trang thông tin căn hộ (để trắng)
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.logout),
              title: Text('Đăng Xuất'),
              onTap: () async {
                // Xử lý đăng xuất
                // Cần thêm logic đăng xuất từ AuthProvider
              },
            ),
          ],
        ),
      ),
      body: Center(
        child: Text('Thông tin căn hộ của bạn.'),
      ),
    );
  }
}
