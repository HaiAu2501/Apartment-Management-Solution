// lib/features/admin/presentation/widgets/donations_tab.dart

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'dart:io';
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
  List<String> donationNames = [];
  String? selectedDonation;
  int? selectedFloor;

  List<RoomData> roomData = [];
  bool isLoading = false;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchDonationNames();
  }

  /// Lấy danh sách tên khoản quyên góp
  Future<void> _fetchDonationNames() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final names = await widget.tableRepository.getFeeNames('donations-table', widget.idToken);
      setState(() {
        donationNames = names;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Lỗi khi tải danh sách khoản quyên góp: $e';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  /// Lấy dữ liệu quyên góp theo phòng
  Future<void> _fetchDonationData() async {
    if (selectedDonation == null || selectedFloor == null) return;

    setState(() {
      isLoading = true;
      errorMessage = '';
      roomData = [];
    });

    try {
      final data = await widget.tableRepository.getFloorData('donations-table', selectedDonation!, selectedFloor!, widget.idToken);
      setState(() {
        roomData = data;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Lỗi khi tải dữ liệu quyên góp: $e';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  List<DropdownMenuItem<int>> get floorDropdownItems {
    return List.generate(50, (index) {
      final floorNum = index + 1;
      return DropdownMenuItem(
        value: floorNum,
        child: Text('Tầng ${floorNum.toString().padLeft(2, '0')}'),
      );
    });
  }

  /// Dialog cập nhật dữ liệu
  void _showUpdateDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Cập nhật dữ liệu"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton.icon(
                icon: Icon(Icons.edit),
                label: Text("Nhập dữ liệu phòng"),
                onPressed: () {
                  Navigator.pop(context);
                  _showManualUpdateForm();
                },
              ),
              SizedBox(height: 10),
              ElevatedButton.icon(
                icon: Icon(Icons.upload_file),
                label: Text("Tải lên file CSV"),
                onPressed: () {
                  Navigator.pop(context);
                  _showCSVUpload();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  /// Form cập nhật thủ công
  void _showManualUpdateForm() {
    showDialog(
      context: context,
      builder: (context) {
        return ManualUpdateDialog(
          tableRepository: widget.tableRepository,
          collection: 'donations-table',
          feeName: selectedDonation!,
          floorNumber: selectedFloor!,
          idToken: widget.idToken,
          onUpdate: _fetchDonationData,
        );
      },
    );
  }

  /// Tải file CSV
  Future<void> _showCSVUpload() async {
    print(">>> _showCSVUpload() called");
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (result == null) {
        print("User canceled file picker");
        return;
      }
      if (result.files.isEmpty) {
        print("No files selected");
        return;
      }

      final filePath = result.files.single.path;
      if (filePath == null) {
        print("No valid filePath");
        return;
      }

      // Desktop: read bytes from path
      final bytes = await File(filePath).readAsBytes();
      final csvString = utf8.decode(bytes);

      print("CSV content: $csvString"); // debug
      final csvTable = CsvToListConverter().convert(csvString);
      print("csvTable: $csvTable"); // debug

      // parse
      List<RoomData> parsedData = [];
      for (var row in csvTable) {
        if (row.length < 4) continue;
        final rNum = int.tryParse(row[0].toString()) ?? 0;
        final paid = int.tryParse(row[1].toString()) ?? 0;
        final dateStr = row[2].toString();
        final payerStr = row[3].toString();
        if (rNum < 1 || rNum > 20) continue;

        // parse date
        DateTime? dt;
        try {
          final parts = dateStr.split('/');
          if (parts.length == 3) {
            final day = int.parse(parts[0]);
            final month = int.parse(parts[1]);
            var year = int.parse(parts[2]);
            if (year < 100) year += 2000;
            dt = DateTime(year, month, day);
          }
        } catch (e) {
          print("Error parsing date $dateStr => $e");
        }

        parsedData.add(RoomData(
          roomNumber: rNum,
          paidAmount: paid,
          paymentDate: (dt != null) ? _formatDate(dt) : 'Chưa đóng',
          payer: payerStr.isNotEmpty ? payerStr : 'Không có',
        ));
      }

      if (parsedData.isEmpty) {
        print("No valid rows in CSV => stop");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('File CSV không hợp lệ hoặc không có dữ liệu.')),
        );
        return;
      }

      final confirm = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: Text("Xác nhận cập nhật"),
          content: Text("Bạn có chắc chắn muốn cập nhật dữ liệu từ file CSV?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text("Hủy"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text("Đồng ý"),
            ),
          ],
        ),
      );

      if (confirm != true) {
        print("User canceled CSV update");
        return;
      }

      // Thực hiện update
      setState(() => isLoading = true);
      try {
        await widget.tableRepository.updateRoomsData(
          'donations-table',
          selectedDonation!,
          selectedFloor!,
          parsedData,
          widget.idToken,
        );

        print("Update CSV success");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cập nhật dữ liệu thành công.')),
        );

        _fetchDonationData(); // load lại
      } catch (e) {
        print("Update CSV error: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi cập nhật dữ liệu: $e')),
        );
      } finally {
        setState(() => isLoading = false);
      }
    } catch (e) {
      print("showCSVUpload unknown error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi tải file: $e')),
      );
    }
  }

  /// Định dạng DateTime -> dd/MM/yy
  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = (date.year % 100).toString().padLeft(2, '0');
    return '$day/$month/$year';
  }

  @override
  Widget build(BuildContext context) {
    return isLoading
        ? Center(child: CircularProgressIndicator())
        : Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Chọn Khoản Quyên Góp
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'Chọn Khoản Quyên Góp',
                    border: OutlineInputBorder(),
                  ),
                  value: selectedDonation,
                  items: donationNames.map((name) {
                    return DropdownMenuItem(value: name, child: Text(name));
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedDonation = value;
                      roomData.clear();
                    });
                  },
                ),
                SizedBox(height: 16),

                // Chọn Tầng
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
                      roomData.clear();
                    });
                  },
                ),
                SizedBox(height: 16),

                // Nút Xem Dữ Liệu, Cập Nhật Dữ Liệu
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        if (selectedDonation != null && selectedFloor != null) {
                          _fetchDonationData();
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Vui lòng chọn khoản quyên góp và tầng')),
                          );
                        }
                      },
                      child: Text('Xem Dữ Liệu'),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        if (selectedDonation != null && selectedFloor != null) {
                          _showUpdateDialog();
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Vui lòng chọn khoản quyên góp & tầng trước khi cập nhật')),
                          );
                        }
                      },
                      icon: Icon(Icons.update),
                      label: Text('Cập nhật dữ liệu'),
                    ),
                  ],
                ),
                SizedBox(height: 16),

                if (errorMessage.isNotEmpty)
                  Text(
                    errorMessage,
                    style: TextStyle(color: Colors.red),
                  ),

                // Hiển thị bảng phòng
                if (roomData.isNotEmpty)
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.vertical,
                        child: DataTable(
                          columns: [
                            DataColumn(label: Text('Số Phòng')),
                            DataColumn(label: Text('Tiền Đã Đóng')),
                            DataColumn(label: Text('Ngày Đóng')),
                            DataColumn(label: Text('Người Đóng')),
                          ],
                          rows: roomData.map((rd) {
                            return DataRow(cells: [
                              DataCell(Text(rd.roomNumber.toString())),
                              DataCell(Text('${rd.paidAmount} kVNĐ')),
                              DataCell(Text(rd.paymentDate)),
                              DataCell(Text(rd.payer)),
                            ]);
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

/// Dialog cập nhật thủ công 1 phòng
class ManualUpdateDialog extends StatefulWidget {
  final TableRepository tableRepository;
  final String collection;
  final String feeName;
  final int floorNumber;
  final String idToken;
  final VoidCallback onUpdate;

  const ManualUpdateDialog({
    Key? key,
    required this.tableRepository,
    required this.collection,
    required this.feeName,
    required this.floorNumber,
    required this.idToken,
    required this.onUpdate,
  }) : super(key: key);

  @override
  _ManualUpdateDialogState createState() => _ManualUpdateDialogState();
}

class _ManualUpdateDialogState extends State<ManualUpdateDialog> {
  final _formKey = GlobalKey<FormState>();
  final _roomNumberController = TextEditingController();
  final _paidAmountController = TextEditingController();
  final _payerController = TextEditingController();
  DateTime? _selectedDate;

  bool isSubmitting = false;
  String errorMessage = '';

  @override
  void dispose() {
    _roomNumberController.dispose();
    _paidAmountController.dispose();
    _payerController.dispose();
    super.dispose();
  }

  Future<void> _submitUpdates() async {
    if (!_formKey.currentState!.validate() || _selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Vui lòng điền đủ thông tin & chọn ngày đóng')),
      );
      return;
    }
    setState(() {
      isSubmitting = true;
      errorMessage = '';
    });

    try {
      final roomNumber = int.parse(_roomNumberController.text.trim());
      final paidAmount = int.parse(_paidAmountController.text.trim());
      final payerStr = _payerController.text.trim().isNotEmpty ? _payerController.text.trim() : 'Không có';
      final DateTime dt = DateTime(_selectedDate!.year, _selectedDate!.month, _selectedDate!.day);

      await widget.tableRepository.updateRoomData(
        widget.collection,
        widget.feeName,
        widget.floorNumber,
        roomNumber,
        paidAmount,
        dt,
        payerStr != 'Không có' ? payerStr : null,
        widget.idToken,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cập nhật dữ liệu thành công.')),
      );

      widget.onUpdate();
      Navigator.pop(context);
    } catch (e) {
      setState(() => errorMessage = 'Lỗi khi cập nhật dữ liệu: $e');
    } finally {
      setState(() => isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("Nhập Dữ Liệu Phòng"),
      content: isSubmitting
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Số Phòng
                    TextFormField(
                      controller: _roomNumberController,
                      decoration: InputDecoration(
                        labelText: 'Số Phòng (1-20)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) return 'Vui lòng nhập số phòng';
                        final num = int.tryParse(val.trim());
                        if (num == null || num < 1 || num > 20) return 'Số phòng phải từ 1..20';
                        return null;
                      },
                    ),
                    SizedBox(height: 10),

                    // Tiền Đóng
                    TextFormField(
                      controller: _paidAmountController,
                      decoration: InputDecoration(
                        labelText: 'Tiền Đóng (kVNĐ)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) return 'Vui lòng nhập tiền đóng';
                        final num = int.tryParse(val.trim());
                        if (num == null || num < 0) return 'Tiền đóng phải là số >= 0';
                        return null;
                      },
                    ),
                    SizedBox(height: 10),

                    // Ngày Đóng
                    InkWell(
                      onTap: () async {
                        final pick = await showDatePicker(
                          context: context,
                          initialDate: _selectedDate ?? DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (pick != null) {
                          setState(() => _selectedDate = pick);
                        }
                      },
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Ngày Đóng',
                          border: OutlineInputBorder(),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _selectedDate != null ? "${_selectedDate!.day.toString().padLeft(2, '0')}/${_selectedDate!.month.toString().padLeft(2, '0')}/${_selectedDate!.year}" : 'Chọn ngày...',
                              style: TextStyle(
                                color: _selectedDate != null ? Colors.black : Colors.grey,
                              ),
                            ),
                            Icon(Icons.calendar_today),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 10),

                    // Người Đóng
                    TextFormField(
                      controller: _payerController,
                      decoration: InputDecoration(
                        labelText: 'Người Đóng',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 10),

                    if (errorMessage.isNotEmpty) Text(errorMessage, style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ),
      actions: [
        TextButton(
          onPressed: isSubmitting ? null : () => Navigator.pop(context),
          child: Text("Hủy"),
        ),
        ElevatedButton(
          onPressed: isSubmitting ? null : _submitUpdates,
          child: Text("Cập nhật"),
        ),
      ],
    );
  }
}
