// lib/features/admin/presentation/widgets/daily_event_box.dart

import 'package:flutter/material.dart';
import '../../../admin/domain/events.dart';
import 'package:intl/intl.dart';

class DailyEventBox extends StatelessWidget {
  final DateTime selectedDay;
  final List<Event> events;
  final Function(Event) onEdit;
  final Function(Event) onDelete;
  final bool scrollable; // Added scrollable parameter

  const DailyEventBox({
    Key? key,
    required this.selectedDay,
    required this.events,
    required this.onEdit,
    required this.onDelete,
    this.scrollable = false, // Default value is false
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget content;

    if (events.isEmpty) {
      content = Center(
        child: Text(
          'Không có sự kiện nào trong ngày này.',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    } else {
      content = ListView.builder(
        shrinkWrap: true,
        physics: scrollable ? const AlwaysScrollableScrollPhysics() : const NeverScrollableScrollPhysics(),
        itemCount: events.length,
        itemBuilder: (context, index) {
          final event = events[index];
          return Card(
            color: Colors.blue[50],
            margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4), // Adds spacing between cards
            child: ExpansionTile(
              leading: const Icon(Icons.event, color: Colors.black),
              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      event.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  )
                ],
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start, // Align to left
                    children: [
                      Text(
                        'Nội dung: ${event.content}',
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Người tổ chức: ${event.organizer}',
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Thành phần tham dự: ${event.participants}',
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Địa điểm: ${event.location}',
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Thời gian: ${DateFormat('dd/MM/yyyy').format(event.date)}',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.yellow[50], // Changed to white for better contrast
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(12),
      child: scrollable ? SingleChildScrollView(child: content) : content,
    );
  }
}
