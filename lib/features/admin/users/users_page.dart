// admin/users/users_page.dart
import 'package:flutter/material.dart';
import '../../authentication/data/authentication_service.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart'; // Thêm thư viện để định dạng ngày tháng

class UsersPage extends StatefulWidget {
  final AuthenticationService authService;
  final String idToken;
  final String uid;

  const UsersPage({
    Key? key,
    required this.authService,
    required this.idToken,
    required this.uid,
  }) : super(key: key);

  @override
  _UsersPageState createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  List<dynamic> queueList = [];
  List<dynamic> residentsList = [];
  List<dynamic> thirdPartiesList = [];
  bool isLoadingQueue = false;
  bool isLoadingResidents = false;
  bool isLoadingThirdParties = false;
  String? message;

  @override
  void initState() {
    super.initState();
    fetchQueue();
    fetchResidents();
    fetchThirdParties();
  }

  @override
  void dispose() {
    // Nếu bạn sử dụng Timer hoặc nguồn bất đồng bộ khác, hãy hủy chúng tại đây
    super.dispose();
  }

  // Hàm lấy danh sách chờ duyệt
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

      if (!mounted) return; // Kiểm tra mounted

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
      if (!mounted) return; // Kiểm tra mounted
      setState(() {
        message = 'Lỗi khi tải danh sách chờ duyệt.';
        isLoadingQueue = false;
      });
      print('Lỗi khi tải queue: $e');
    }
  }

  // Hàm lấy danh sách cư dân
  Future<void> fetchResidents() async {
    setState(() {
      isLoadingResidents = true;
    });

    final url =
        'https://firestore.googleapis.com/v1/projects/${widget.authService.projectId}/databases/(default)/documents/residents?key=${widget.authService.apiKey}';

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer ${widget.idToken}',
          'Content-Type': 'application/json',
        },
      );

      if (!mounted) return; // Kiểm tra mounted

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          residentsList = data['documents'] ?? [];
          isLoadingResidents = false;
        });
      } else {
        setState(() {
          message = 'Lỗi khi tải danh sách cư dân.';
          isLoadingResidents = false;
        });
        print('Lỗi khi tải residents: ${response.statusCode}');
        print('Chi tiết lỗi: ${response.body}');
      }
    } catch (e) {
      if (!mounted) return; // Kiểm tra mounted
      setState(() {
        message = 'Lỗi khi tải danh sách cư dân.';
        isLoadingResidents = false;
      });
      print('Lỗi khi tải residents: $e');
    }
  }

  // Hàm lấy danh sách bên thứ 3
  Future<void> fetchThirdParties() async {
    setState(() {
      isLoadingThirdParties = true;
    });

    final url =
        'https://firestore.googleapis.com/v1/projects/${widget.authService.projectId}/databases/(default)/documents/thirdParties?key=${widget.authService.apiKey}';

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer ${widget.idToken}',
          'Content-Type': 'application/json',
        },
      );

      if (!mounted) return; // Kiểm tra mounted

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          thirdPartiesList = data['documents'] ?? [];
          isLoadingThirdParties = false;
        });
      } else {
        setState(() {
          message = 'Lỗi khi tải danh sách bên thứ 3.';
          isLoadingThirdParties = false;
        });
        print('Lỗi khi tải thirdParties: ${response.statusCode}');
        print('Chi tiết lỗi: ${response.body}');
      }
    } catch (e) {
      if (!mounted) return; // Kiểm tra mounted
      setState(() {
        message = 'Lỗi khi tải danh sách bên thứ 3.';
        isLoadingThirdParties = false;
      });
      print('Lỗi khi tải thirdParties: $e');
    }
  }

  // Hàm phê duyệt người dùng từ queue
  Future<void> approveUser(
      String queueDocName, Map<String, dynamic> queueData) async {
    setState(() {
      message = null;
    });

    try {
      String role = queueData['role']['stringValue'];
      Map<String, dynamic> targetData = {};

      if (role == 'Cư dân') {
        targetData = {
          'fullName': queueData['fullName']['stringValue'],
          'gender': queueData['gender']['stringValue'],
          'dob': queueData['dob']['stringValue'],
          'phone': queueData['phone']['stringValue'],
          'id': queueData['id']['stringValue'],
          'uid': queueData['uid']['stringValue'],
          'floor': int.parse(queueData['floor']['integerValue']),
          'apartmentNumber':
              int.parse(queueData['apartmentNumber']['integerValue']),
          'email': queueData['email']['stringValue'],
          'status': 'Đã duyệt',
        };
      } else if (role == 'Bên thứ 3') {
        targetData = {
          'fullName': queueData['fullName']['stringValue'],
          'gender': queueData['gender']['stringValue'],
          'dob': queueData['dob']['stringValue'],
          'phone': queueData['phone']['stringValue'],
          'id': queueData['id']['stringValue'],
          'uid': queueData['uid']['stringValue'],
          'email': queueData['email']['stringValue'],
          'jobTitle': queueData['jobTitle']['stringValue'],
          'status': 'Đã duyệt',
        };
      } else {
        if (!mounted) return; // Kiểm tra mounted
        setState(() {
          message = 'Vai trò không hợp lệ.';
        });
        return;
      }

      // Chọn collection đích dựa trên vai trò
      String targetCollection = role == 'Cư dân' ? 'residents' : 'thirdParties';

      // Gọi phương thức để tạo document trong collection đích
      bool success = await widget.authService.createUserDocument(widget.idToken,
          queueData['uid']['stringValue'], targetData, targetCollection);

      if (success) {
        // Xóa tài liệu từ 'queue'
        bool deleteSuccess = await widget.authService
            .deleteQueueDocument(queueDocName, widget.idToken);
        if (!mounted) return; // Kiểm tra mounted
        if (deleteSuccess) {
          setState(() {
            message = 'Phê duyệt thành công.';
          });
          fetchQueue();
          if (role == 'Cư dân') {
            fetchResidents();
          } else {
            fetchThirdParties();
          }
        } else {
          setState(() {
            message =
                'Phê duyệt thành công nhưng không thể xóa tài liệu trong queue.';
          });
        }
      } else {
        setState(() {
          message =
              'Phê duyệt thất bại khi tạo tài liệu trong $targetCollection.';
        });
      }
    } catch (e) {
      if (!mounted) return; // Kiểm tra mounted
      setState(() {
        message = 'Lỗi khi phê duyệt người dùng.';
      });
      print('Lỗi khi phê duyệt user: $e');
    }
  }

  // Hàm định dạng ngày sinh
  String formatDob(String dobString) {
    try {
      // Giả sử dobString có định dạng DD/MM/YYYY
      DateFormat inputFormat = DateFormat('dd/MM/yyyy');
      DateFormat outputFormat = DateFormat('dd/MM/yyyy');
      DateTime date = inputFormat.parse(dobString);
      return outputFormat.format(date);
    } catch (e) {
      return dobString; // Nếu không thể định dạng, trả về nguyên bản
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
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
          const SizedBox(height: 20),
          // Tab để chuyển đổi giữa danh sách chờ và danh sách cư dân, bên thứ 3
          Expanded(
            child: DefaultTabController(
              length: 3,
              child: Column(
                children: [
                  const TabBar(
                    labelColor: Colors.green,
                    indicatorColor: Colors.green,
                    tabs: [
                      Tab(text: 'Chờ duyệt'),
                      Tab(text: 'Cư dân'),
                      Tab(text: 'Bên thứ 3'),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        // Tab 1: Danh Sách Chờ Duyệt
                        isLoadingQueue
                            ? const Center(child: CircularProgressIndicator())
                            : queueList.isEmpty
                                ? const Center(
                                    child: Text(
                                        'Không có yêu cầu nào đang chờ duyệt.'))
                                : ListView.builder(
                                    itemCount: queueList.length,
                                    itemBuilder: (context, index) {
                                      final doc = queueList[index];
                                      final fields = doc['fields'];
                                      return Card(
                                        child: ListTile(
                                          title: Text(fields['fullName']
                                              ['stringValue']),
                                          subtitle: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                  'Vai trò: ${fields['role']['stringValue']}'),
                                              Text(
                                                  'Giới tính: ${fields['gender']['stringValue']}'),
                                              Text(
                                                  'Ngày sinh: ${formatDob(fields['dob']['stringValue'])}'),
                                              Text(
                                                  'Số điện thoại: ${fields['phone']['stringValue']}'),
                                              Text(
                                                  'Số ID: ${fields['id']['stringValue']}'),
                                              Text(
                                                  'Email: ${fields['email']['stringValue']}'),
                                              if (fields['role']
                                                      ['stringValue'] ==
                                                  'Bên thứ 3')
                                                Text(
                                                    'Chức vụ: ${fields['jobTitle']['stringValue']}'),
                                              if (fields['role']
                                                      ['stringValue'] ==
                                                  'Cư dân') ...[
                                                Text(
                                                    'Tầng: ${fields['floor']['integerValue']}'),
                                                Text(
                                                    'Căn hộ số: ${fields['apartmentNumber']['integerValue']}'),
                                              ],
                                              Text(
                                                  'Trạng thái: ${fields['status']['stringValue']}'),
                                            ],
                                          ),
                                          trailing: ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  Colors.green, // Màu nền
                                            ),
                                            onPressed: () {
                                              approveUser(doc['name'], fields);
                                            },
                                            child: const Text('Phê duyệt'),
                                          ),
                                        ),
                                      );
                                    },
                                  ),

                        // Tab 2: Danh Sách Cư Dân
                        isLoadingResidents
                            ? const Center(child: CircularProgressIndicator())
                            : residentsList.isEmpty
                                ? const Center(
                                    child: Text('Không có cư dân nào.'))
                                : ListView.builder(
                                    itemCount: residentsList.length,
                                    itemBuilder: (context, index) {
                                      final doc = residentsList[index];
                                      final fields = doc['fields'];
                                      return Card(
                                        child: ListTile(
                                          title: Text(fields['fullName']
                                              ['stringValue']),
                                          subtitle: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                  'Giới tính: ${fields['gender']['stringValue']}'),
                                              Text(
                                                  'Ngày sinh: ${formatDob(fields['dob']['stringValue'])}'),
                                              Text(
                                                  'Số điện thoại: ${fields['phone']['stringValue']}'),
                                              Text(
                                                  'Số ID: ${fields['id']['stringValue']}'),
                                              Text(
                                                  'Email: ${fields['email']['stringValue']}'),
                                              Text(
                                                  'Tầng: ${fields['floor']['integerValue']}'),
                                              Text(
                                                  'Căn hộ số: ${fields['apartmentNumber']['integerValue']}'),
                                              Text(
                                                  'Trạng thái: ${fields['status']['stringValue']}'),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),

                        // Tab 3: Danh Sách Bên Thứ 3
                        isLoadingThirdParties
                            ? const Center(child: CircularProgressIndicator())
                            : thirdPartiesList.isEmpty
                                ? const Center(
                                    child: Text('Không có bên thứ 3 nào.'))
                                : ListView.builder(
                                    itemCount: thirdPartiesList.length,
                                    itemBuilder: (context, index) {
                                      final doc = thirdPartiesList[index];
                                      final fields = doc['fields'];
                                      return Card(
                                        child: ListTile(
                                          title: Text(fields['fullName']
                                              ['stringValue']),
                                          subtitle: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                  'Giới tính: ${fields['gender']['stringValue']}'),
                                              Text(
                                                  'Ngày sinh: ${formatDob(fields['dob']['stringValue'])}'),
                                              Text(
                                                  'Số điện thoại: ${fields['phone']['stringValue']}'),
                                              Text(
                                                  'Số ID: ${fields['id']['stringValue']}'),
                                              Text(
                                                  'Email: ${fields['email']['stringValue']}'),
                                              Text(
                                                  'Chức vụ: ${fields['jobTitle']['stringValue']}'),
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
          ),
        ],
      ),
    );
  }
}
