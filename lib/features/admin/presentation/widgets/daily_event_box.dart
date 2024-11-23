// lib/features/admin/presentation/widgets/daily_event_box.dart

import 'package:flutter/material.dart';
import '../../domain/events.dart';
import 'package:intl/intl.dart';

class DailyEventBox extends StatelessWidget {
  final DateTime selectedDay;
  final List<Event> events;
  final Function(Event) onEdit;
  final Function(Event) onDelete;
  final bool scrollable; // Thêm tham số scrollable

  const DailyEventBox({
    Key? key,
    required this.selectedDay,
    required this.events,
    required this.onEdit,
    required this.onDelete,
    this.scrollable = false, // Giá trị mặc định là false
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget content;

    if (events.isEmpty) {
      content = Center(
        child: Text('Không có sự kiện nào trong ngày này.'),
      );
    } else {
      content = ListView.builder(
        shrinkWrap: true,
        physics: scrollable ? AlwaysScrollableScrollPhysics() : NeverScrollableScrollPhysics(),
        itemCount: events.length,
        itemBuilder: (context, index) {
          final event = events[index];
          return ExpansionTile(
            leading: Icon(Icons.event),
            title: Row(
              children: [
                Expanded(child: Text(event.title)),
                IconButton(
                  icon: Icon(Icons.edit, color: Colors.blue),
                  onPressed: () => onEdit(event),
                ),
                IconButton(
                  icon: Icon(Icons.delete, color: Colors.red),
                  onPressed: () => onDelete(event),
                ),
              ],
            ),
            children: [
              Padding(
                padding: EdgeInsets.only(left: 0.0, right: 16.0, top: 8.0, bottom: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, // Căn lề trái
                  children: [
                    Text('Nội dung: ${event.content}'),
                    SizedBox(height: 4),
                    Text('Người tổ chức: ${event.organizer}'),
                    SizedBox(height: 4),
                    Text('Thành phần tham dự: ${event.participants}'),
                    SizedBox(height: 4),
                    Text('Địa điểm: ${event.location}'),
                    SizedBox(height: 4),
                    Text('Thời gian: ${DateFormat('dd/MM/yyyy').format(event.date)}'),
                  ],
                ),
              ),
            ],
          );
        },
      );
    }

    return Card(
      child: scrollable ? SingleChildScrollView(child: content) : content,
      color: Colors.white,
    );
  }
}
