// lib/features/admin/presentation/events_page.dart

import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../../.authentication/data/auth_service.dart';
import '../data/events_repository.dart';

class Event {
  String id; // Document ID in Firestore
  String title;
  String content;
  String organizer;
  String participants;
  String location;
  DateTime date;

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

class EventsPage extends StatefulWidget {
  const EventsPage({super.key});

  @override
  _EventsPageState createState() => _EventsPageState();
}

class _EventsPageState extends State<EventsPage> {
  // Khởi tạo EventsRepository với thông tin dự án Firebase của bạn
  final EventsRepository eventsRepository = EventsRepository(
    apiKey: 'YOUR_API_KEY', // Thay thế bằng API Key thực tế
    projectId: 'apartment-management-solution', // Thay thế bằng Project ID thực tế
  );

  final AuthenticationService authService = AuthenticationService(
    apiKey: 'YOUR_API_KEY', // Thay thế bằng API Key thực tế
    projectId: 'apartment-management-solution', // Thay thế bằng Project ID thực tế
  );

  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;

  // Map để lưu trữ sự kiện lấy từ Firestore
  Map<DateTime, List<Event>> _events = {};

  bool _isLoading = true; // Biến chỉ thị đang tải sự kiện

  @override
  void initState() {
    super.initState();
    _fetchEvents(); // Lấy sự kiện khi trang khởi tạo
  }

  /// Lấy tất cả các sự kiện từ Firestore và cập nhật Map _events
  Future<void> _fetchEvents() async {
    // Gọi setState để cập nhật _isLoading
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      String? idToken = await authService.getIdToken(); // Lấy ID token
      if (idToken == null) {
        throw Exception('User not authenticated');
      }

      List<dynamic> documents = await eventsRepository.fetchAllEvents(idToken);
      Map<DateTime, List<Event>> fetchedEvents = {};

      for (var doc in documents) {
        String documentName = doc['name'];
        String documentId = documentName.split('/').last;
        Map<String, dynamic> fields = doc['fields'];

        Event event = Event.fromFirestore(fields, documentId);
        DateTime eventDate = DateTime(event.date.year, event.date.month, event.date.day);

        if (fetchedEvents[eventDate] != null) {
          fetchedEvents[eventDate]!.add(event);
        } else {
          fetchedEvents[eventDate] = [event];
        }
      }

      if (mounted) {
        setState(() {
          _events = fetchedEvents;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching events: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching events: $e')),
        );
      }
    }
  }

  /// Lấy các sự kiện sắp tới trong vòng 30 ngày
  List<EventWithDate> _getUpcomingEvents() {
    DateTime today = DateTime.now();
    DateTime endDate = today.add(const Duration(days: 30));
    List<EventWithDate> allEvents = [];

    _events.forEach((date, events) {
      for (var event in events) {
        if (!date.isBefore(DateTime(today.year, today.month, today.day)) && !date.isAfter(endDate)) {
          allEvents.add(EventWithDate(event: event, date: date));
        }
      }
    });

    allEvents.sort((a, b) => a.date.compareTo(b.date));
    return allEvents;
  }

  /// Lấy các sự kiện đã qua trong vòng 30 ngày
  List<EventWithDate> _getPastEvents() {
    DateTime today = DateTime.now();
    DateTime startDate = today.subtract(const Duration(days: 30));
    List<EventWithDate> allEvents = [];

    _events.forEach((date, events) {
      for (var event in events) {
        if (date.isBefore(DateTime(today.year, today.month, today.day)) && date.isAfter(startDate)) {
          allEvents.add(EventWithDate(event: event, date: date));
        }
      }
    });

    allEvents.sort((a, b) => a.date.compareTo(b.date));
    return allEvents;
  }

  /// Lấy ngày của một sự kiện cụ thể
  DateTime _getEventDate(Event event) {
    for (var entry in _events.entries) {
      if (entry.value.contains(event)) {
        return entry.key;
      }
    }
    return DateTime.now();
  }

  /// Xử lý khi người dùng chọn một ngày trên lịch
  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
      });
    }
  }

  /// Thêm một sự kiện mới
  void _addEvent() {
    showDialog(
      context: context,
      builder: (context) {
        // Các controller cho các trường nhập liệu
        TextEditingController titleController = TextEditingController();
        TextEditingController contentController = TextEditingController();
        TextEditingController organizerController = TextEditingController();
        TextEditingController participantsController = TextEditingController();
        TextEditingController locationController = TextEditingController();
        DateTime selectedDate = _selectedDay ?? _focusedDay;

        return AlertDialog(
          title: const Text('Thêm sự kiện mới'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Tên sự kiện'),
                ),
                TextField(
                  controller: contentController,
                  decoration: const InputDecoration(labelText: 'Nội dung'),
                ),
                TextField(
                  controller: organizerController,
                  decoration: const InputDecoration(labelText: 'Người tổ chức'),
                ),
                TextField(
                  controller: participantsController,
                  decoration: const InputDecoration(labelText: 'Thành phần tham dự'),
                ),
                TextField(
                  controller: locationController,
                  decoration: const InputDecoration(labelText: 'Địa điểm'),
                ),
                const SizedBox(height: 10),
                // Hiển thị ngày được chọn
                Row(
                  children: [
                    const Text('Ngày: '),
                    Text(
                      DateFormat('dd/MM/yyyy').format(selectedDate),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                // Tạo dữ liệu sự kiện
                Map<String, dynamic> eventData = {
                  'title': titleController.text,
                  'content': contentController.text,
                  'organizer': organizerController.text,
                  'participants': participantsController.text,
                  'location': locationController.text,
                  'date': selectedDate,
                };

                try {
                  String? idToken = await authService.getIdToken();
                  if (idToken == null) {
                    throw Exception('User not authenticated');
                  }

                  // Thêm sự kiện vào Firestore
                  await eventsRepository.addEvent(eventData, idToken);

                  // Làm mới danh sách sự kiện
                  await _fetchEvents();

                  if (mounted) {
                    Navigator.pop(context);
                  }
                } catch (e) {
                  print('Error adding event: $e');
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error adding event: $e')),
                    );
                    Navigator.pop(context);
                  }
                }
              },
              child: const Text('Lưu'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
          ],
        );
      },
    );
  }

  /// Chỉnh sửa một sự kiện hiện có
  void _editEvent(Event event) {
    showDialog(
      context: context,
      builder: (context) {
        // Các controller đã được điền sẵn với dữ liệu sự kiện hiện tại
        TextEditingController titleController = TextEditingController(text: event.title);
        TextEditingController contentController = TextEditingController(text: event.content);
        TextEditingController organizerController = TextEditingController(text: event.organizer);
        TextEditingController participantsController = TextEditingController(text: event.participants);
        TextEditingController locationController = TextEditingController(text: event.location);

        return AlertDialog(
          title: const Text('Chỉnh sửa sự kiện'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Tên sự kiện'),
                ),
                TextField(
                  controller: contentController,
                  decoration: const InputDecoration(labelText: 'Nội dung'),
                ),
                TextField(
                  controller: organizerController,
                  decoration: const InputDecoration(labelText: 'Người tổ chức'),
                ),
                TextField(
                  controller: participantsController,
                  decoration: const InputDecoration(labelText: 'Thành phần tham dự'),
                ),
                TextField(
                  controller: locationController,
                  decoration: const InputDecoration(labelText: 'Địa điểm'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                // Dữ liệu cập nhật
                Map<String, dynamic> updatedData = {
                  'title': titleController.text,
                  'content': contentController.text,
                  'organizer': organizerController.text,
                  'participants': participantsController.text,
                  'location': locationController.text,
                };

                try {
                  String? idToken = await authService.getIdToken();
                  if (idToken == null) {
                    throw Exception('User not authenticated');
                  }

                  // Gọi phương thức updateEvent với đường dẫn tài liệu đúng
                  await eventsRepository.updateEvent(
                    eventsRepository.getDocumentPath(event.id),
                    updatedData,
                    idToken,
                  );

                  // Làm mới danh sách sự kiện
                  await _fetchEvents();

                  if (mounted) {
                    Navigator.pop(context);
                  }
                } catch (e) {
                  print('Error updating event: $e');
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error updating event: $e')),
                    );
                    Navigator.pop(context);
                  }
                }
              },
              child: const Text('Lưu'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
          ],
        );
      },
    );
  }

  /// Xóa một sự kiện với xác nhận
  void _deleteEvent(Event event) {
    DateTime eventDate = _getEventDate(event);
    String formattedDate = DateFormat('dd/MM/yyyy').format(eventDate);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Xác nhận xóa'),
          content: Text('Bạn có chắc chắn muốn xóa sự kiện "${event.title}", ngày $formattedDate?'),
          actions: [
            TextButton(
              onPressed: () async {
                try {
                  String? idToken = await authService.getIdToken();
                  if (idToken == null) {
                    throw Exception('User not authenticated');
                  }

                  // Gọi phương thức deleteEvent với đường dẫn tài liệu đúng
                  await eventsRepository.deleteEvent(
                    eventsRepository.getDocumentPath(event.id),
                    idToken,
                  );

                  // Làm mới danh sách sự kiện
                  await _fetchEvents();

                  if (mounted) {
                    Navigator.pop(context);
                  }
                } catch (e) {
                  print('Error deleting event: $e');
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error deleting event: $e')),
                    );
                    Navigator.pop(context);
                  }
                }
              },
              child: const Text('Chắc chắn'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Từ chối'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    List<EventWithDate> upcomingEvents = _getUpcomingEvents();
    List<EventWithDate> pastEvents = _getPastEvents();

    return Scaffold(
      appBar: AppBar(title: const Text('Quản Lý Sự Kiện')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth > 600) {
                  // Màn hình rộng: Sử dụng layout ngang
                  return Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Phần bên trái: Hiển thị các sự kiện sắp tới và đã qua
                        Expanded(
                          flex: 1,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white, // Bạn có thể thay đổi màu nền nếu cần
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
                            child: Column(
                              children: [
                                // Sự kiện sắp tới - Chiếm 1/2 chiều cao
                                Expanded(
                                  flex: 1,
                                  child: Column(
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                                        child: Text(
                                          'Sự kiện sắp tới',
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          textAlign: TextAlign.center, // Center align the text
                                        ),
                                      ),
                                      upcomingEvents.isEmpty
                                          ? const Padding(
                                              padding: EdgeInsets.symmetric(horizontal: 8.0),
                                              child: Text('Không có sự kiện sắp tới'),
                                            )
                                          : Expanded(
                                              child: ListView.builder(
                                                shrinkWrap: true,
                                                physics: const BouncingScrollPhysics(),
                                                itemCount: upcomingEvents.length,
                                                itemBuilder: (context, index) {
                                                  final eventWithDate = upcomingEvents[index];
                                                  return ListTile(
                                                    leading: const Icon(Icons.event),
                                                    title: Text(eventWithDate.event.title),
                                                    subtitle: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Text('Thời gian: ${DateFormat('dd/MM/yyyy').format(eventWithDate.date)}'),
                                                        Text('Địa điểm: ${eventWithDate.event.location}'),
                                                      ],
                                                    ),
                                                    onTap: () {
                                                      // Thêm chức năng xem chi tiết sự kiện tại đây nếu cần
                                                    },
                                                  );
                                                },
                                              ),
                                            ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16.0),
                                // Sự kiện đã qua - Chiếm 1/2 chiều cao
                                Expanded(
                                  flex: 1,
                                  child: Column(
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                                        child: Text(
                                          'Sự kiện đã qua',
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          textAlign: TextAlign.center, // Center align the text
                                        ),
                                      ),
                                      pastEvents.isEmpty
                                          ? const Padding(
                                              padding: EdgeInsets.symmetric(horizontal: 8.0),
                                              child: Text('Không có sự kiện đã qua'),
                                            )
                                          : Expanded(
                                              child: ListView.builder(
                                                shrinkWrap: true,
                                                physics: const BouncingScrollPhysics(),
                                                itemCount: pastEvents.length,
                                                itemBuilder: (context, index) {
                                                  final eventWithDate = pastEvents[index];
                                                  return ListTile(
                                                    leading: const Icon(Icons.event),
                                                    title: Text(eventWithDate.event.title),
                                                    subtitle: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Text('Thời gian: ${DateFormat('dd/MM/yyyy').format(eventWithDate.date)}'),
                                                        Text('Địa điểm: ${eventWithDate.event.location}'),
                                                      ],
                                                    ),
                                                    onTap: () {
                                                      // Thêm chức năng xem chi tiết sự kiện tại đây nếu cần
                                                    },
                                                  );
                                                },
                                              ),
                                            ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 16.0),
                        // Phần bên phải: Lịch và thông tin sự kiện của ngày chọn
                        Expanded(
                          flex: 2,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.green[50], // Màu nền xanh lá cây nhẹ
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
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                TableCalendar<Event>(
                                  locale: 'vi_VN',
                                  firstDay: DateTime.utc(2020, 1, 1),
                                  lastDay: DateTime.utc(2030, 12, 31),
                                  focusedDay: _focusedDay,
                                  selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                                  onDaySelected: _onDaySelected,
                                  calendarFormat: _calendarFormat,
                                  onFormatChanged: (format) {
                                    setState(() {
                                      _calendarFormat = format;
                                    });
                                  },
                                  onPageChanged: (focusedDay) {
                                    setState(() {
                                      _focusedDay = focusedDay;
                                    });
                                  },
                                  calendarStyle: const CalendarStyle(
                                    todayDecoration: BoxDecoration(
                                      color: Colors.blueAccent,
                                      shape: BoxShape.circle,
                                    ),
                                    selectedDecoration: BoxDecoration(
                                      color: Colors.orangeAccent,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  eventLoader: _getEventsForDay,
                                  availableCalendarFormats: const {
                                    CalendarFormat.month: 'Tháng',
                                  },
                                  headerStyle: const HeaderStyle(
                                    formatButtonVisible: false,
                                    titleCentered: true,
                                  ),
                                ),
                                const SizedBox(height: 8.0),
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                                  child: Text(
                                    'Sự kiện ngày ${DateFormat('dd/MM/yyyy').format(_selectedDay ?? _focusedDay)}',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.left,
                                  ),
                                ),
                                Expanded(child: _buildEventList()),
                                const SizedBox(height: 16.0),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                } else {
                  // Màn hình nhỏ: Sử dụng layout dọc
                  return Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        // Phần bên trái: Hiển thị các sự kiện sắp tới và đã qua
                        Expanded(
                          flex: 1,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white, // Bạn có thể thay đổi màu nền nếu cần
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
                            child: Column(
                              children: [
                                // Sự kiện sắp tới - Chiếm 1/2 chiều cao
                                Expanded(
                                  flex: 1,
                                  child: Column(
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                                        child: Text(
                                          'Sự kiện sắp tới',
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          textAlign: TextAlign.center, // Center align the text
                                        ),
                                      ),
                                      upcomingEvents.isEmpty
                                          ? const Padding(
                                              padding: EdgeInsets.symmetric(horizontal: 8.0),
                                              child: Text('Không có sự kiện sắp tới'),
                                            )
                                          : Expanded(
                                              child: ListView.builder(
                                                shrinkWrap: true,
                                                physics: const BouncingScrollPhysics(),
                                                itemCount: upcomingEvents.length,
                                                itemBuilder: (context, index) {
                                                  final eventWithDate = upcomingEvents[index];
                                                  return ListTile(
                                                    leading: const Icon(Icons.event),
                                                    title: Text(eventWithDate.event.title),
                                                    subtitle: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Text('Thời gian: ${DateFormat('dd/MM/yyyy').format(eventWithDate.date)}'),
                                                        Text('Địa điểm: ${eventWithDate.event.location}'),
                                                      ],
                                                    ),
                                                    onTap: () {
                                                      // Thêm chức năng xem chi tiết sự kiện tại đây nếu cần
                                                    },
                                                  );
                                                },
                                              ),
                                            ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16.0),
                                // Sự kiện đã qua - Chiếm 1/2 chiều cao
                                Expanded(
                                  flex: 1,
                                  child: Column(
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                                        child: Text(
                                          'Sự kiện đã qua',
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          textAlign: TextAlign.center, // Center align the text
                                        ),
                                      ),
                                      pastEvents.isEmpty
                                          ? const Padding(
                                              padding: EdgeInsets.symmetric(horizontal: 8.0),
                                              child: Text('Không có sự kiện đã qua'),
                                            )
                                          : Expanded(
                                              child: ListView.builder(
                                                shrinkWrap: true,
                                                physics: const BouncingScrollPhysics(),
                                                itemCount: pastEvents.length,
                                                itemBuilder: (context, index) {
                                                  final eventWithDate = pastEvents[index];
                                                  return ListTile(
                                                    leading: const Icon(Icons.event),
                                                    title: Text(eventWithDate.event.title),
                                                    subtitle: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Text('Thời gian: ${DateFormat('dd/MM/yyyy').format(eventWithDate.date)}'),
                                                        Text('Địa điểm: ${eventWithDate.event.location}'),
                                                      ],
                                                    ),
                                                    onTap: () {
                                                      // Thêm chức năng xem chi tiết sự kiện tại đây nếu cần
                                                    },
                                                  );
                                                },
                                              ),
                                            ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16.0),
                        // Phần bên phải: Lịch và thông tin sự kiện của ngày chọn
                        Expanded(
                          flex: 2,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.green[50], // Màu nền xanh lá cây nhẹ
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
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                TableCalendar<Event>(
                                  locale: 'vi_VN',
                                  firstDay: DateTime.utc(2020, 1, 1),
                                  lastDay: DateTime.utc(2030, 12, 31),
                                  focusedDay: _focusedDay,
                                  selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                                  onDaySelected: _onDaySelected,
                                  calendarFormat: _calendarFormat,
                                  onFormatChanged: (format) {
                                    setState(() {
                                      _calendarFormat = format;
                                    });
                                  },
                                  onPageChanged: (focusedDay) {
                                    setState(() {
                                      _focusedDay = focusedDay;
                                    });
                                  },
                                  calendarStyle: const CalendarStyle(
                                    todayDecoration: BoxDecoration(
                                      color: Colors.blueAccent,
                                      shape: BoxShape.circle,
                                    ),
                                    selectedDecoration: BoxDecoration(
                                      color: Colors.orangeAccent,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  eventLoader: _getEventsForDay,
                                  availableCalendarFormats: const {
                                    CalendarFormat.month: 'Tháng',
                                  },
                                  headerStyle: const HeaderStyle(
                                    formatButtonVisible: false,
                                    titleCentered: true,
                                  ),
                                ),
                                const SizedBox(height: 8.0),
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                                  child: Text(
                                    'Sự kiện ngày ${DateFormat('dd/MM/yyyy').format(_selectedDay ?? _focusedDay)}',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.left,
                                  ),
                                ),
                                Expanded(child: _buildEventList()),
                                const SizedBox(height: 16.0),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addEvent,
        child: const Icon(Icons.add),
      ),
    );
  }

  /// Lấy các sự kiện cho một ngày cụ thể
  List<Event> _getEventsForDay(DateTime day) {
    return _events.entries.where((entry) => isSameDay(entry.key, day)).map((entry) => entry.value).expand((events) => events).toList();
  }

  /// Xây dựng danh sách sự kiện cho ngày được chọn
  Widget _buildEventList() {
    final events = _getEventsForDay(_selectedDay ?? _focusedDay);

    if (events.isEmpty) {
      return const Center(
        child: Text('Không có sự kiện nào trong ngày này.'),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const BouncingScrollPhysics(),
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];
        return ExpansionTile(
          leading: const Icon(Icons.event),
          title: Row(
            children: [
              Expanded(child: Text(event.title)),
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.blue),
                onPressed: () {
                  _editEvent(event);
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () {
                  _deleteEvent(event);
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
    );
  }
}
