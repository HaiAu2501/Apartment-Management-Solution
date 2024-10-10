// lib/features/admin/presentation/tabs/guests_tab.dart
import 'package:flutter/material.dart';
import '../../data/admin_repository.dart';
import 'package:intl/intl.dart';

class GuestsTab extends StatefulWidget {
  final AdminRepository adminRepository;
  final String idToken;

  const GuestsTab({
    super.key,
    required this.adminRepository,
    required this.idToken,
  });

  @override
  _GuestsTabState createState() => _GuestsTabState();
}

class _GuestsTabState extends State<GuestsTab> {
  List<dynamic> guestsList = [];
  bool isLoadingGuests = false;

  @override
  void initState() {
    super.initState();
    fetchGuests();
  }

  @override
  void dispose() {
    // Nếu bạn có các Stream hoặc các đối tượng khác cần hủy bỏ, hãy thực hiện ở đây.
    super.dispose();
  }

  // Hàm lấy danh sách khách
  Future<void> fetchGuests() async {
    setState(() {
      isLoadingGuests = true;
    });

    try {
      List<dynamic> fetchedGuests = await widget.adminRepository.fetchGuests(widget.idToken);
      if (!mounted) return; // Kiểm tra nếu widget vẫn còn mount
      setState(() {
        guestsList = fetchedGuests;
        isLoadingGuests = false;
      });
    } catch (e) {
      if (!mounted) return; // Kiểm tra nếu widget vẫn còn mount
      setState(() {
        // Xử lý lỗi nếu cần
        isLoadingGuests = false;
      });
      print('Lỗi khi tải guests: $e');
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
    if (isLoadingGuests) {
      return const Center(child: CircularProgressIndicator());
    }

    if (guestsList.isEmpty) {
      return const Center(child: Text('Không có khách nào.'));
    }

    return ListView.builder(
      itemCount: guestsList.length,
      itemBuilder: (context, index) {
        final doc = guestsList[index];
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
                Text('Chức vụ: ${fields['jobTitle']['stringValue']}'),
                Text('Trạng thái: ${fields['status']['stringValue']}'),
              ],
            ),
          ),
        );
      },
    );
  }
}
