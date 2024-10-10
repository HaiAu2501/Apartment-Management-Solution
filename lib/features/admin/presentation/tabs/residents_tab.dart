// lib/features/admin/presentation/tabs/residents_tab.dart
import 'package:flutter/material.dart';
import '../../data/admin_repository.dart';
import 'package:intl/intl.dart';

class ResidentsTab extends StatefulWidget {
  final AdminRepository adminRepository;
  final String idToken;

  const ResidentsTab({
    super.key,
    required this.adminRepository,
    required this.idToken,
  });

  @override
  _ResidentsTabState createState() => _ResidentsTabState();
}

class _ResidentsTabState extends State<ResidentsTab> {
  List<dynamic> residentsList = [];
  bool isLoadingResidents = false;

  @override
  void initState() {
    super.initState();
    fetchResidents();
  }

  @override
  void dispose() {
    // Nếu bạn có các Stream hoặc các đối tượng khác cần hủy bỏ, hãy thực hiện ở đây.
    super.dispose();
  }

  // Hàm lấy danh sách cư dân
  Future<void> fetchResidents() async {
    setState(() {
      isLoadingResidents = true;
    });

    try {
      List<dynamic> fetchedResidents = await widget.adminRepository.fetchResidents(widget.idToken);
      if (!mounted) return; // Kiểm tra nếu widget vẫn còn mount
      setState(() {
        residentsList = fetchedResidents;
        isLoadingResidents = false;
      });
    } catch (e) {
      if (!mounted) return; // Kiểm tra nếu widget vẫn còn mount
      setState(() {
        // Xử lý lỗi nếu cần
        isLoadingResidents = false;
      });
      print('Lỗi khi tải residents: $e');
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
    if (isLoadingResidents) {
      return const Center(child: CircularProgressIndicator());
    }

    if (residentsList.isEmpty) {
      return const Center(child: Text('Không có cư dân nào.'));
    }

    return ListView.builder(
      itemCount: residentsList.length,
      itemBuilder: (context, index) {
        final doc = residentsList[index];
        final fields = doc['fields'];
        return Card(
          child: ListTile(
            title: Text(fields['fullName']['stringValue']),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Giới tính: ${fields['gender']['stringValue']}'),
                Text('Ngày sinh: ${formatDob(fields['dob']['stringValue'])}'),
                Text('Số điện thoại: ${fields['phone']['stringValue']}'),
                Text('Số ID: ${fields['id']['stringValue']}'),
                Text('Email: ${fields['email']['stringValue']}'),
                Text('Tầng: ${fields['floor']['integerValue']}'),
                Text('Căn hộ số: ${fields['apartmentNumber']['integerValue']}'),
                Text('Trạng thái: ${fields['status']['stringValue']}'),
              ],
            ),
          ),
        );
      },
    );
  }
}
