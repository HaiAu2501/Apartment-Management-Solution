// lib/widgets/daily_event_box.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/events.dart';

class DailyEventBox extends StatelessWidget {
  final DateTime selectedDay;
  final List<Event> events;
  final Function(Event) onEdit;
  final Function(Event) onDelete;

  const DailyEventBox({
    Key? key,
    required this.selectedDay,
    required this.events,
    required this.onEdit,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    String formattedDate = DateFormat('dd/MM/yyyy').format(selectedDay);

    return Container(
      decoration: BoxDecoration(
        color: Colors.blue[50], // Màu nền xanh dương nhẹ
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16.0),
      width: double.infinity, // Ensure full width
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tiêu đề
          Text(
            'Sự kiện ngày $formattedDate',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8.0),
          // Danh sách sự kiện
          events.isEmpty
              ? const Center(
                  child: Text('Không có sự kiện nào trong ngày này.'),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const BouncingScrollPhysics(),
                  itemCount: events.length,
                  itemBuilder: (context, index) {
                    final event = events[index];
                    return ExpansionTile(
                      leading: const Icon(Icons.event),
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              event.title,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () {
                              onEdit(event);
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              onDelete(event);
                            },
                          ),
                        ],
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Nội dung: ${event.content}'),
                              const SizedBox(height: 4),
                              Text('Người tổ chức: ${event.organizer}'),
                              const SizedBox(height: 4),
                              Text('Thành phần tham dự: ${event.participants}'),
                              const SizedBox(height: 4),
                              Text('Địa điểm: ${event.location}'),
                              const SizedBox(height: 4),
                              Text('Thời gian: ${DateFormat('dd/MM/yyyy').format(event.date)}'),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
        ],
      ),
    );
  }
}
