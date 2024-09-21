// lib/features/admin/presentation/admin_home_page.dart

import 'package:flutter/material.dart';
import '../../authentication/data/authentication_service.dart';
import '../../authentication/presentation/login_page.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AdminHomePage extends StatefulWidget {
  final AuthenticationService authService;
  final String idToken;
  final String uid;

  AdminHomePage({
    required this.authService,
    required this.idToken,
    required this.uid,
  });

  @override
  _AdminHomePageState createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  List<dynamic> queueList = [];
  List<dynamic> usersList = [];
  bool isLoadingQueue = false;
  bool isLoadingUsers = false;
  String? message;

  @override
  void initState() {
    super.initState();
    fetchQueue();
    fetchUsers();
  }

  Future<void> fetchQueue() async {
    setState(() {
      isLoadingQueue = true;
    });

    final url =
        'https://firestore.googleapis.com/v1/projects/${widget.authService.projectId}/databases/(default)/documents/queue?key=${widget.authService.apiKey}';

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer ${widget.idToken}',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          queueList = data['documents'] ?? [];
          isLoadingQueue = false;
        });
      } else {
        setState(() {
          message = 'Lỗi khi tải danh sách chờ duyệt.';
          isLoadingQueue = false;
        });
        print('Lỗi khi tải queue: ${response.statusCode}');
        print('Chi tiết lỗi: ${response.body}');
      }
    } catch (e) {
      setState(() {
        message = 'Lỗi khi tải danh sách chờ duyệt.';
        isLoadingQueue = false;
      });
      print('Lỗi khi tải queue: $e');
    }
  }

// Hàm lấy danh sách cư dân
  Future<void> fetchUsers() async {
    setState(() {
      isLoadingUsers = true;
    });

    final url =
        'https://firestore.googleapis.com/v1/projects/${widget.authService.projectId}/databases/(default)/documents/users?key=${widget.authService.apiKey}';

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer ${widget.idToken}',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List<dynamic> fetchedUsers = data['documents'] ?? [];

        // Loại bỏ các tài liệu có role là 'admin'
        fetchedUsers = fetchedUsers.where((doc) {
          final fields = doc['fields'];
          return fields['role']['stringValue'] != 'admin';
        }).toList();

        setState(() {
          usersList = fetchedUsers;
          isLoadingUsers = false;
        });
      } else {
        setState(() {
          message = 'Lỗi khi tải danh sách cư dân.';
          isLoadingUsers = false;
        });
        print('Lỗi khi tải users: ${response.statusCode}');
        print('Chi tiết lỗi: ${response.body}');
      }
    } catch (e) {
      setState(() {
        message = 'Lỗi khi tải danh sách cư dân.';
        isLoadingUsers = false;
      });
      print('Lỗi khi tải users: $e');
    }
  }

  Future<void> approveUser(
      String queueDocName, Map<String, dynamic> queueData) async {
    setState(() {
      message = null;
    });

    try {
      // Tạo dữ liệu để tạo document trong 'users'
      Map<String, dynamic> userData = {
        'email': queueData['email'] ?? 'unknown@example.com', // Nếu cần thiết
        'full_name': queueData['full_name']['stringValue'],
        'gender': queueData['gender']['stringValue'],
        'dob': queueData['dob']['timestampValue'],
        'cccd': queueData['cccd']['stringValue'],
        'apartment_name': queueData['apartment_name']['stringValue'],
        'building_name': queueData['building_name']['stringValue'],
        'floor_number': int.parse(queueData['floor_number']['integerValue']),
        'apartment_number':
            int.parse(queueData['apartment_number']['integerValue']),
        'status': 'approval',
        'role': queueData['role'] != null
            ? queueData['role']['stringValue']
            : 'resident',
      };

      // Gọi phương thức createUserDocument từ AuthenticationService
      bool success = await widget.authService.createUserDocument(
          widget.idToken, queueData['uid']['stringValue'], userData);

      if (success) {
        // Xóa tài liệu từ 'queue'
        bool deleteSuccess = await widget.authService
            .deleteQueueDocument(queueDocName, widget.idToken);
        if (deleteSuccess) {
          setState(() {
            message = 'Phê duyệt thành công.';
          });
          fetchQueue();
          fetchUsers();
        } else {
          setState(() {
            message =
                'Phê duyệt thành công nhưng không thể xóa tài liệu trong queue.';
          });
        }
      } else {
        setState(() {
          message = 'Phê duyệt thất bại khi tạo tài liệu trong users.';
        });
      }
    } catch (e) {
      setState(() {
        message = 'Lỗi khi phê duyệt người dùng.';
      });
      print('Lỗi khi phê duyệt user: $e');
    }
  }

  Future<void> logout() async {
    // Hàm logout nếu bạn cần
    // Vì đang sử dụng REST API, bạn có thể xóa token từ client
    // Ví dụ: reset các biến trạng thái và chuyển hướng về LoginPage
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => LoginPage(authService: widget.authService),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Trang Chủ Admin'),
          actions: [
            IconButton(
              icon: Icon(Icons.logout),
              onPressed: logout,
            )
          ],
        ),
        body: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Hiển thị thông báo
              if (message != null)
                Text(
                  message!,
                  style: TextStyle(
                      color: message!.contains('thành công')
                          ? Colors.green
                          : Colors.red),
                ),
              SizedBox(height: 20),
              // Tab để chuyển đổi giữa danh sách chờ và danh sách cư dân
              Expanded(
                child: DefaultTabController(
                  length: 2,
                  child: Column(
                    children: [
                      TabBar(
                        tabs: [
                          Tab(text: 'Danh Sách Chờ Duyệt'),
                          Tab(text: 'Danh Sách Cư Dân'),
                        ],
                      ),
                      Expanded(
                        child: TabBarView(
                          children: [
                            // Tab 1: Danh Sách Chờ Duyệt
                            isLoadingQueue
                                ? Center(child: CircularProgressIndicator())
                                : ListView.builder(
                                    itemCount: queueList.length,
                                    itemBuilder: (context, index) {
                                      final doc = queueList[index];
                                      final fields = doc['fields'];
                                      return Card(
                                        child: ListTile(
                                          title: Text(fields['full_name']
                                              ['stringValue']),
                                          subtitle: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                  'Giới tính: ${fields['gender']['stringValue']}'),
                                              Text(
                                                  'Số CCCD: ${fields['cccd']['stringValue']}'),
                                              Text(
                                                  'Chung cư: ${fields['apartment_name']['stringValue']}'),
                                              Text(
                                                  'Tòa nhà: ${fields['building_name']['stringValue']}'),
                                              Text(
                                                  'Tầng: ${fields['floor_number']['integerValue']}'),
                                              Text(
                                                  'Căn hộ: ${fields['apartment_number']['integerValue']}'),
                                              Text(
                                                  'Vai trò: ${fields['role']['stringValue']}'),
                                            ],
                                          ),
                                          trailing: ElevatedButton(
                                            onPressed: () {
                                              approveUser(
                                                  doc['name'].split('/').last,
                                                  fields);
                                            },
                                            child: Text('Phê Duyệt'),
                                          ),
                                        ),
                                      );
                                    },
                                  ),

                            // Tab 2: Danh Sách Cư Dân
                            isLoadingUsers
                                ? Center(child: CircularProgressIndicator())
                                : ListView.builder(
                                    itemCount: usersList.length,
                                    itemBuilder: (context, index) {
                                      final doc = usersList[index];
                                      final fields = doc['fields'];
                                      return Card(
                                        child: ListTile(
                                          title: Text(fields['full_name']
                                              ['stringValue']),
                                          subtitle: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                  'Chung cư: ${fields['apartment_name']['stringValue']}'),
                                              Text(
                                                  'Tòa nhà: ${fields['building_name']['stringValue']}'),
                                              Text(
                                                  'Tầng: ${fields['floor_number']['integerValue']}'),
                                              Text(
                                                  'Căn hộ: ${fields['apartment_number']['integerValue']}'),
                                              Text(
                                                  'Trạng thái: ${fields['status']['stringValue']}'),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              )
            ],
          ),
        ));
  }
}
