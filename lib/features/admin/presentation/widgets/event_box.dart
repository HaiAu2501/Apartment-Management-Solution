// lib/widgets/event_box.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/events.dart';

class EventBox extends StatelessWidget {
  final String title;
  final int count;
  final List<EventWithDate> events;
  final String emptyMessage;
  final Function(Event) onEventTap;
  final Function(Event) onEdit;
  final Function(Event) onDelete;
  final String screenSize; // 'wide', 'medium', 'small'

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
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Determine button layout based on screen size
    bool isMediumScreen = screenSize == 'medium';
    bool isWideScreen = screenSize == 'wide';
    bool isSmallScreen = screenSize == 'small';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white, // Màu nền trắng
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
          // Tiêu đề và thống kê
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4.0),
              Text(
                count > 0 ? (title == 'Sự kiện sắp tới' ? 'Trong 30 ngày sắp tới: $count sự kiện' : 'Trong 30 ngày đã qua: $count sự kiện') : (title == 'Sự kiện sắp tới' ? 'Trong 30 ngày sắp tới: 0 sự kiện' : 'Trong 30 ngày đã qua: 0 sự kiện'),
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8.0),
          // Danh sách sự kiện
          events.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text(emptyMessage),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: events.length,
                  itemBuilder: (context, index) {
                    final eventWithDate = events[index];
                    return ListTile(
                      leading: const Icon(Icons.event),
                      title: isMediumScreen || isSmallScreen
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  eventWithDate.event.title,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                                const SizedBox(height: 4.0),
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
                                      onPressed: () {
                                        onEdit(eventWithDate.event);
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                      onPressed: () {
                                        onDelete(eventWithDate.event);
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            )
                          : Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    eventWithDate.event.title,
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.blue),
                                  onPressed: () {
                                    onEdit(eventWithDate.event);
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () {
                                    onDelete(eventWithDate.event);
                                  },
                                ),
                              ],
                            ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Thời gian: ${DateFormat('dd/MM/yyyy').format(eventWithDate.date)}'),
                          Text('Địa điểm: ${eventWithDate.event.location}'),
                        ],
                      ),
                      onTap: () {
                        onEventTap(eventWithDate.event);
                      },
                    );
                  },
                ),
        ],
      ),
    );
  }
}
