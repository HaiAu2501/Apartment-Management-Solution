// lib/domain/events.dart



class Event {
  final String id; // Document ID in Firestore
  final String title;
  final String content;
  final String organizer;
  final String participants;
  final String location;
  final DateTime date;

  Event({
    required this.id,
    required this.title,
    required this.content,
    required this.organizer,
    required this.participants,
    required this.location,
    required this.date,
  });

  /// Factory method để tạo Event từ tài liệu Firestore
  factory Event.fromFirestore(Map<String, dynamic> data, String documentId) {
    try {
      String? timestamp = data['date']?['timestampValue'];
      DateTime parsedDate = timestamp != null
          ? DateTime.parse(timestamp).toLocal() // Chuyển đổi sang múi giờ địa phương
          : DateTime.now();

      return Event(
        id: documentId,
        title: data['title']?['stringValue'] ?? '',
        content: data['content']?['stringValue'] ?? '',
        organizer: data['organizer']?['stringValue'] ?? '',
        participants: data['participants']?['stringValue'] ?? '',
        location: data['location']?['stringValue'] ?? '',
        date: parsedDate,
      );
    } catch (e) {
      return Event(
        id: documentId,
        title: 'Error',
        content: '',
        organizer: '',
        participants: '',
        location: '',
        date: DateTime.now(),
      );
    }
  }

  /// Chuyển đổi Event thành các trường Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'title': {'stringValue': title},
      'content': {'stringValue': content},
      'organizer': {'stringValue': organizer},
      'participants': {'stringValue': participants},
      'location': {'stringValue': location},
      'date': {'timestampValue': date.toUtc().toIso8601String()},
    };
  }
}

class EventWithDate {
  final Event event;
  final DateTime date;

  EventWithDate({required this.event, required this.date});
}
