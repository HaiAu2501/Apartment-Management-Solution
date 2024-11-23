// lib/features/admin/presentation/widgets/event_box.dart

import 'package:flutter/material.dart';
import '../../domain/events.dart';
import 'package:intl/intl.dart';

class EventBox extends StatelessWidget {
  final String title;
  final int count;
  final List<EventWithDate> events;
  final String emptyMessage;
  final Function(Event) onEventTap;
  final Function(Event) onEdit;
  final Function(Event) onDelete;
  final String screenSize;
  final bool scrollable; // Thêm tham số scrollable

  const EventBox({
    Key? key,
    required this.title,
    required this.count,
    required this.events,
    required this.emptyMessage,
    required this.onEventTap,
    required this.onEdit,
    required this.onDelete,
    required this.screenSize,
    this.scrollable = false, // Giá trị mặc định là false
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget content;

    if (events.isEmpty) {
      content = Center(child: Text(emptyMessage));
    } else {
      content = ListView.builder(
        shrinkWrap: true,
        physics: scrollable ? AlwaysScrollableScrollPhysics() : NeverScrollableScrollPhysics(),
        itemCount: events.length,
        itemBuilder: (context, index) {
          final eventWithDate = events[index];
          final event = eventWithDate.event;
          return ListTile(
            title: Text(event.title),
            subtitle: Text(DateFormat('dd/MM/yyyy').format(event.date)),
            onTap: () => onEventTap(event),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
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
          );
        },
      );
    }

    return Card(
      child: Padding(
        padding: EdgeInsets.all(8.0),
        child: Column(
          children: [
            Text(
              '$title ($count)',
              style: TextStyle(fontSize: 22),
            ),
            Divider(),
            Expanded(
              child: scrollable ? SingleChildScrollView(child: content) : content,
            ),
          ],
        ),
      ),
    );
  }
}
