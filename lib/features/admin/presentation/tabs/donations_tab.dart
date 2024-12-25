// lib/features/admin/presentation/widgets/donations_tab.dart

import 'package:flutter/material.dart';
import '../../data/table_repository.dart';
import '../../../.authentication/data/auth_service.dart';

class DonationsTab extends StatefulWidget {
  final TableRepository tableRepository;
  final AuthenticationService authService;
  final String idToken;

  const DonationsTab({
    Key? key,
    required this.tableRepository,
    required this.authService,
    required this.idToken,
  }) : super(key: key);

  @override
  _DonationsTabState createState() => _DonationsTabState();
}

class _DonationsTabState extends State<DonationsTab> {
  List<String> feeNames = [];
  String? selectedFee;
  int? selectedFloor;

  List<RoomData> roomData = [];
  bool isLoading = false;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchFeeNames();
  }

  Future<void> _fetchFeeNames() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final names = await widget.tableRepository.getFeeNames('donations-table', widget.idToken);
      setState(() {
        feeNames = names;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Lỗi khi tải danh sách phí: $e';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _fetchRoomData() async {
    if (selectedFee == null || selectedFloor == null) return;

    setState(() {
      isLoading = true;
      errorMessage = '';
      roomData = [];
    });

    try {
      final data = await widget.tableRepository.getFloorData('donations-table', selectedFee!, selectedFloor!, widget.idToken);
      setState(() {
        roomData = data;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Lỗi khi tải dữ liệu phòng: $e';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // Dropdown items for floor numbers
  List<DropdownMenuItem<int>> get floorDropdownItems {
    return List.generate(50, (index) {
      int floor = index + 1;
      return DropdownMenuItem(
        value: floor,
        child: Text('Tầng ${floor.toString().padLeft(2, '0')}'),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return isLoading
        ? Center(child: CircularProgressIndicator())
        : Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Dropdown for Fee Names
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'Chọn Khoản Phí',
                    border: OutlineInputBorder(),
                  ),
                  value: selectedFee,
                  items: feeNames
                      .map((name) => DropdownMenuItem(
                            value: name,
                            child: Text(name),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedFee = value;
                      roomData = [];
                    });
                  },
                  validator: (value) => value == null ? 'Vui lòng chọn khoản phí' : null,
                ),
                SizedBox(height: 16),

                // Dropdown for Floor Numbers
                DropdownButtonFormField<int>(
                  decoration: InputDecoration(
                    labelText: 'Chọn Tầng',
                    border: OutlineInputBorder(),
                  ),
                  value: selectedFloor,
                  items: floorDropdownItems,
                  onChanged: (value) {
                    setState(() {
                      selectedFloor = value;
                      roomData = [];
                    });
                  },
                  validator: (value) => value == null ? 'Vui lòng chọn tầng' : null,
                ),
                SizedBox(height: 16),

                // Button to Fetch Data
                ElevatedButton(
                  onPressed: () {
                    if (selectedFee != null && selectedFloor != null) {
                      _fetchRoomData();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Vui lòng chọn cả khoản phí và tầng')),
                      );
                    }
                  },
                  child: Text('Xem Dữ Liệu'),
                ),
                SizedBox(height: 16),

                // Display Error Message
                if (errorMessage.isNotEmpty)
                  Text(
                    errorMessage,
                    style: TextStyle(color: Colors.red),
                  ),

                // Display Table Data
                if (roomData.isNotEmpty)
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal, // Cuộn ngang
                      child: SingleChildScrollView(
                        scrollDirection: Axis.vertical, // Cuộn dọc
                        child: DataTable(
                          columns: [
                            DataColumn(label: Text('Số Phòng')),
                            DataColumn(label: Text('Tiền Đã Đóng')),
                            DataColumn(label: Text('Ngày Đóng')),
                          ],
                          rows: roomData.map((room) {
                            return DataRow(
                              cells: [
                                DataCell(Text(room.roomNumber.toString())),
                                DataCell(Text('${room.paidAmount} kVNĐ')),
                                DataCell(Text(room.paymentDate)),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
  }
}
