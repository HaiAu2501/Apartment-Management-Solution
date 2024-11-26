// lib/features/admin/presentation/widgets/event_box.dart

import 'package:flutter/material.dart';
import '../../../admin/domain/events.dart';
import 'package:intl/intl.dart';

class EventBox extends StatelessWidget {
  final String title;
  final String countMessage; // Changed from int count to String countMessage
  final List<EventWithDate> events;
  final String emptyMessage;
  final Function(Event) onEventTap;
  final Function(Event) onEdit;
  final Function(Event) onDelete;
  final String screenSize;
  final bool scrollable;

  const EventBox({
    Key? key,
    required this.title,
    required this.countMessage, // Updated parameter
    required this.events,
    required this.emptyMessage,
    required this.onEventTap,
    required this.onEdit,
    required this.onDelete,
    required this.screenSize,
    this.scrollable = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget content;

    if (events.isEmpty) {
      content = Center(child: Text(emptyMessage));
    } else {
      content = ListView.builder(
        shrinkWrap: true,
        physics: scrollable ? const AlwaysScrollableScrollPhysics() : const NeverScrollableScrollPhysics(),
        itemCount: events.length,
        itemBuilder: (context, index) {
          final eventWithDate = events[index];
          final event = eventWithDate.event;
          return Card(
            color: const Color.fromARGB(255, 255, 253, 232),
            margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4), // Adds spacing between cards
            child: ListTile(
              leading: const Icon(Icons.event, color: Colors.black),
              title: Text(event.title, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text('Thời gian: ${DateFormat('dd/MM/yyyy').format(event.date)}'),
                  const SizedBox(height: 2),
                  Text('Địa điểm: ${event.location}'),
                ],
              ),
              onTap: () => onEventTap(event),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
              ),
            ),
          );
        },
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, // Align to left
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            textAlign: TextAlign.left,
          ),
          const SizedBox(height: 4),
          Text(
            countMessage,
            style: const TextStyle(fontSize: 14, color: Colors.black),
          ),
          const Divider(),
          Expanded(
            child: scrollable ? SingleChildScrollView(child: content) : content,
          ),
        ],
      ),
    );
  }
}
