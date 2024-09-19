import 'package:flutter/material.dart';
import '../providers/resident_provider.dart';
import 'package:provider/provider.dart';
import '../../domain/entities/resident.dart';

class ResidentItem extends StatelessWidget {
  final ResidentEntity resident;

  ResidentItem({required this.resident});

  @override
  Widget build(BuildContext context) {
    final residentProvider =
        Provider.of<ResidentProvider>(context, listen: false);

    return ListTile(
      title: Text(resident.fullName),
      subtitle: Text('Email: ${resident.email}'),
      trailing: IconButton(
        icon: Icon(Icons.check),
        onPressed: () {
          // Xác nhận cư dân
          residentProvider.approveResident(resident.id);
        },
      ),
    );
  }
}
