import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/resident_provider.dart';
import '../widgets/resident_item.dart';

class ResidentListPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final residentProvider = Provider.of<ResidentProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Danh Sách Cư Dân'),
      ),
      body: residentProvider.residents.isEmpty
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: residentProvider.residents.length,
              itemBuilder: (context, index) {
                return ResidentItem(
                  resident: residentProvider.residents[index],
                );
              },
            ),
    );
  }
}
