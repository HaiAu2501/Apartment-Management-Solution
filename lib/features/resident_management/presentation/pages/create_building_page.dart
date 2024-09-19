import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/utils/validators.dart';

class CreateBuildingPage extends StatefulWidget {
  @override
  _CreateBuildingPageState createState() => _CreateBuildingPageState();
}

class _CreateBuildingPageState extends State<CreateBuildingPage> {
  final _formKey = GlobalKey<FormState>();
  String _buildingName = '';
  int _numberOfApartments = 0;
  String _error = '';
  bool _loading = false;

  void _createBuilding() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      setState(() {
        _loading = true;
        _error = '';
      });

      try {
        // Tạo document mới trong collection 'buildings'
        DocumentReference buildingRef =
            await FirebaseFirestore.instance.collection('buildings').add({
          'name': _buildingName,
          'numberOfApartments': _numberOfApartments,
          'createdBy': FirebaseFirestore.instance
              .collection('users')
              .doc(FirebaseFirestore.instance.doc('users').id)
              .id, // Lấy UID của admin hiện tại
          'createdAt': FieldValue.serverTimestamp(),
        });

        // Tạo các căn hộ trong collection 'apartments'
        for (int i = 1; i <= _numberOfApartments; i++) {
          await FirebaseFirestore.instance.collection('apartments').add({
            'buildingId': buildingRef.id,
            'apartmentNumber': 'A${i.toString().padLeft(3, '0')}',
            'residentId': null,
            'status': 'vacant',
            'createdAt': FieldValue.serverTimestamp(),
          });
        }

        // Thông báo và điều hướng
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đã tạo tòa nhà thành công!')),
        );
        Navigator.pop(context);
      } catch (e) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tạo Tòa Nhà'),
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  // Thêm để tránh overflow
                  child: Column(
                    children: [
                      // Tên tòa nhà
                      TextFormField(
                        decoration: InputDecoration(labelText: 'Tên Tòa Nhà'),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Vui lòng nhập tên tòa nhà';
                          }
                          return null;
                        },
                        onSaved: (value) {
                          _buildingName = value!;
                        },
                      ),
                      // Số căn hộ
                      TextFormField(
                        decoration: InputDecoration(labelText: 'Số Căn Hộ'),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null ||
                              int.tryParse(value) == null ||
                              int.parse(value) <= 0) {
                            return 'Vui lòng nhập số căn hộ hợp lệ';
                          }
                          return null;
                        },
                        onSaved: (value) {
                          _numberOfApartments = int.parse(value!);
                        },
                      ),
                      SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _createBuilding,
                        child: Text('Tạo Tòa Nhà'),
                      ),
                      SizedBox(height: 12),
                      // Hiển thị lỗi
                      Text(
                        _error,
                        style: TextStyle(color: Colors.red),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
