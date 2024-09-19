import 'package:flutter/material.dart';

class ThirdPartyHomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Giao diện cho bên thứ 3
      appBar: AppBar(
        title: Text('Trang Bên Thứ 3'),
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
              leading: Icon(Icons.info),
              title: Text('Thông Tin Hạn Chế'),
              onTap: () {
                // Điều hướng đến trang thông tin hạn chế (để trắng)
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
        child: Text('Thông tin hạn chế.'),
      ),
    );
  }
}
