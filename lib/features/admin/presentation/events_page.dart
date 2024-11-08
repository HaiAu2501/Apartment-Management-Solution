// lib/features/admin/presentation/events_page.dart

import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../domain/events.dart';
import '../../.authentication/data/auth_service.dart';
import '../data/events_repository.dart';
import 'widgets/event_box.dart';
import 'widgets/daily_event_box.dart';

class EventsPage extends StatefulWidget {
  final AuthenticationService authService;
  const EventsPage({
    super.key,
    required this.authService,
  });

  @override
  _EventsPageState createState() => _EventsPageState();
}

class _EventsPageState extends State<EventsPage> {
  late final EventsRepository eventsRepository;
  late final AuthenticationService authService; // Added local variable

  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;

  // Map để lưu trữ sự kiện lấy từ Firestore
  Map<DateTime, List<Event>> _events = {};

  bool _isLoading = true; // Biến chỉ thị đang tải sự kiện

  @override
  void initState() {
    super.initState();
    authService = widget.authService; // Initialize local authService
    eventsRepository = EventsRepository(
      apiKey: authService.apiKey, // Sử dụng authService đã được định nghĩa
      projectId: authService.projectId,
    );
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

  /// Tính số lượng sự kiện sắp tới và đã qua
  int get upcomingEventCount => _getUpcomingEvents().length;
  int get pastEventCount => _getPastEvents().length;

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
    // Lấy chiều rộng màn hình
    double screenWidth = MediaQuery.of(context).size.width;
    bool isSmallScreen = screenWidth <= 600;
    bool isMediumScreen = screenWidth > 600 && screenWidth <= 900;
    bool isWideScreen = screenWidth > 900;

    List<EventWithDate> upcomingEvents = _getUpcomingEvents();
    List<EventWithDate> pastEvents = _getPastEvents();

    return Scaffold(
      appBar: AppBar(title: const Text('Quản Lý Sự Kiện')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : LayoutBuilder(
              builder: (context, constraints) {
                // Determine calendar format based on screen size
                CalendarFormat currentCalendarFormat = isSmallScreen ? CalendarFormat.twoWeeks : CalendarFormat.month;

                return SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: isWideScreen || isMediumScreen
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Left Section: Past and Upcoming Events
                              Expanded(
                                flex: 1,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch, // Ensure full width
                                  children: [
                                    // Sự kiện sắp tới
                                    EventBox(
                                      title: 'Sự kiện sắp tới',
                                      count: upcomingEventCount,
                                      events: upcomingEvents,
                                      emptyMessage: '',
                                      onEventTap: (event) {
                                        // Thêm chức năng xem chi tiết sự kiện tại đây nếu cần
                                      },
                                      onEdit: _editEvent,
                                      onDelete: _deleteEvent,
                                      screenSize: isWideScreen
                                          ? 'wide'
                                          : isMediumScreen
                                              ? 'medium'
                                              : 'small',
                                    ),
                                    const SizedBox(height: 16.0),
                                    // Sự kiện đã qua
                                    EventBox(
                                      title: 'Sự kiện đã qua',
                                      count: pastEventCount,
                                      events: pastEvents,
                                      emptyMessage: '',
                                      onEventTap: (event) {
                                        // Thêm chức năng xem chi tiết sự kiện tại đây nếu cần
                                      },
                                      onEdit: _editEvent,
                                      onDelete: _deleteEvent,
                                      screenSize: isWideScreen
                                          ? 'wide'
                                          : isMediumScreen
                                              ? 'medium'
                                              : 'small',
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16.0),
                              // Right Section: Calendar and Daily Events
                              Expanded(
                                flex: 2,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch, // Ensure full width
                                  children: [
                                    // Calendar Box
                                    Container(
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
                                      width: double.infinity, // Ensure full width
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
                                            calendarFormat: currentCalendarFormat,
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
                                              CalendarFormat.twoWeeks: 'Hai tuần',
                                            },
                                            headerStyle: const HeaderStyle(
                                              formatButtonVisible: false,
                                              titleCentered: true,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 16.0),
                                    // Daily Events Box
                                    DailyEventBox(
                                      selectedDay: _selectedDay ?? _focusedDay,
                                      events: _getEventsForDay(_selectedDay ?? _focusedDay),
                                      onEdit: _editEvent,
                                      onDelete: _deleteEvent,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Left Section: Past and Upcoming Events
                              // Sự kiện sắp tới
                              EventBox(
                                title: 'Sự kiện sắp tới',
                                count: upcomingEventCount,
                                events: upcomingEvents,
                                emptyMessage: '',
                                onEventTap: (event) {
                                  // Thêm chức năng xem chi tiết sự kiện tại đây nếu cần
                                },
                                onEdit: _editEvent,
                                onDelete: _deleteEvent,
                                screenSize: 'small',
                              ),
                              const SizedBox(height: 16.0),
                              // Sự kiện đã qua
                              EventBox(
                                title: 'Sự kiện đã qua',
                                count: pastEventCount,
                                events: pastEvents,
                                emptyMessage: '',
                                onEventTap: (event) {
                                  // Thêm chức năng xem chi tiết sự kiện tại đây nếu cần
                                },
                                onEdit: _editEvent,
                                onDelete: _deleteEvent,
                                screenSize: 'small',
                              ),
                              const SizedBox(height: 16.0),
                              // Right Section: Calendar and Daily Events
                              // Calendar Box
                              Container(
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
                                width: double.infinity, // Ensure full width
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
                                      calendarFormat: isSmallScreen ? CalendarFormat.twoWeeks : CalendarFormat.month,
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
                                        CalendarFormat.twoWeeks: 'Hai tuần',
                                      },
                                      headerStyle: const HeaderStyle(
                                        formatButtonVisible: false,
                                        titleCentered: true,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16.0),
                              // Daily Events Box
                              DailyEventBox(
                                selectedDay: _selectedDay ?? _focusedDay,
                                events: _getEventsForDay(_selectedDay ?? _focusedDay),
                                onEdit: _editEvent,
                                onDelete: _deleteEvent,
                              ),
                            ],
                          ),
                  ),
                );
              },
            ),
      floatingActionButton: (isSmallScreen || isMediumScreen)
          ? FloatingActionButton.small(
              onPressed: _addEvent,
              child: const Icon(Icons.add),
            )
          : FloatingActionButton(
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
