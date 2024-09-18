import 'package:flutter/material.dart';

class ResidentListPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Giả sử bạn có một danh sách cư dân
    final residents = [
      {'name': 'Nguyễn Văn A', 'apartment': '101'},
      {'name': 'Trần Thị B', 'apartment': '102'},
      {'name': 'Lê Văn C', 'apartment': '103'},
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text('Danh Sách Cư Dân'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () {
              // Xử lý đăng xuất và quay về trang đăng nhập
              Navigator.pushReplacementNamed(context, '/');
            },
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: residents.length,
        itemBuilder: (context, index) {
          final resident = residents[index];
          return ListTile(
            title: Text(resident['name']!),
            subtitle: Text('Căn hộ: ${resident['apartment']}'),
            onTap: () {
              // Điều hướng đến trang chi tiết cư dân (nếu có)
            },
          );
        },
      ),
    );
  }
}
