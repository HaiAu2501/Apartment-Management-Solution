// lib/features/admin/presentation/events_page.dart

import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../../admin/domain/events.dart';
import '../../.authentication/data/auth_service.dart';
import '../../admin/data/events_repository.dart';
import '../presentation/widgets/event_box.dart';
import '../presentation/widgets/daily_event_box.dart';

class EventsPage extends StatefulWidget {
  final AuthenticationService authService;
  const EventsPage({
    super.key,
    required this.authService,
  });

  @override
  _EventsPageState createState() => _EventsPageState();
}

class _EventsPageState extends State<EventsPage> with SingleTickerProviderStateMixin {
  late final EventsRepository eventsRepository;
  late final AuthenticationService authService;

  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;

  // Map để lưu trữ sự kiện lấy từ Firestore
  Map<DateTime, List<Event>> _events = {};

  bool _isLoading = true; // Biến chỉ thị đang tải sự kiện

  // Controller for TabBar
  late TabController _tabController;

  // Controllers for Add Event Tab
  final TextEditingController _addTitleController = TextEditingController();
  final TextEditingController _addContentController = TextEditingController();
  final TextEditingController _addOrganizerController = TextEditingController();
  final TextEditingController _addParticipantsController = TextEditingController();
  final TextEditingController _addLocationController = TextEditingController();

  @override
  void initState() {
    super.initState();
    authService = widget.authService; // Initialize local authService
    eventsRepository = EventsRepository(
      apiKey: authService.apiKey, // Sử dụng authService đã được định nghĩa
      projectId: authService.projectId,
    );
    _fetchEvents(); // Lấy sự kiện khi trang khởi tạo

    // Initialize TabController with 2 tabs
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose(); // Dispose TabController
    // Dispose Add Event Controllers
    _addTitleController.dispose();
    _addContentController.dispose();
    _addOrganizerController.dispose();
    _addParticipantsController.dispose();
    _addLocationController.dispose();
    super.dispose();
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
      _tabController.animateTo(0); // Switch to Event List tab when a new day is selected
    }
  }

  /// Thêm một sự kiện mới
  Future<void> _addEvent() async {
    // Validate input fields
    if (_addTitleController.text.isEmpty || _addContentController.text.isEmpty || _addOrganizerController.text.isEmpty || _addParticipantsController.text.isEmpty || _addLocationController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng điền đầy đủ các trường.')),
      );
      return;
    }

    DateTime selectedDate = _selectedDay ?? _focusedDay;

    // Tạo dữ liệu sự kiện
    Map<String, dynamic> eventData = {
      'title': _addTitleController.text,
      'content': _addContentController.text,
      'organizer': _addOrganizerController.text,
      'participants': _addParticipantsController.text,
      'location': _addLocationController.text,
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

      // Clear the input fields
      _addTitleController.clear();
      _addContentController.clear();
      _addOrganizerController.clear();
      _addParticipantsController.clear();
      _addLocationController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Thêm sự kiện thành công!')),
      );
    } catch (e) {
      print('Error adding event: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding event: $e')),
      );
    }
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
    // Lấy kích thước màn hình
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    List<EventWithDate> upcomingEvents = _getUpcomingEvents();
    List<EventWithDate> pastEvents = _getPastEvents();

    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  // Cột bên trái: Sự kiện sắp tới và Sự kiện đã qua
                  Expanded(
                    flex: 35,
                    child: Column(
                      children: [
                        // Sự kiện sắp tới
                        Expanded(
                          child: Container(
                            margin: const EdgeInsets.only(right: 10),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              children: [
                                // Nội dung sự kiện sắp tới
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 0),
                                    child: EventBox(
                                      title: 'Sự kiện sắp tới',
                                      countMessage: 'Trong 30 ngày sắp tới: $upcomingEventCount sự kiện',
                                      events: upcomingEvents,
                                      emptyMessage: 'Không có sự kiện sắp tới.',
                                      onEventTap: (event) {
                                        // Thêm chức năng xem chi tiết sự kiện tại đây nếu cần
                                      },
                                      onEdit: _editEvent,
                                      onDelete: _deleteEvent,
                                      screenSize: 'small',
                                      scrollable: true,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Sự kiện đã qua
                        Expanded(
                          child: Container(
                            margin: const EdgeInsets.only(top: 10, right: 10),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              children: [
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 0),
                                    child: EventBox(
                                      title: 'Sự kiện đã qua',
                                      countMessage: 'Trong 30 ngày đã qua: $pastEventCount sự kiện',
                                      events: pastEvents,
                                      emptyMessage: 'Không có sự kiện đã qua.',
                                      onEventTap: (event) {
                                        // Thêm chức năng xem chi tiết sự kiện tại đây nếu cần
                                      },
                                      onEdit: _editEvent,
                                      onDelete: _deleteEvent,
                                      screenSize: 'small',
                                      scrollable: true,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Cột bên phải: Lịch và Sự kiện trong ngày
                  Expanded(
                    flex: 65,
                    child: Column(
                      children: [
                        // Lịch
                        Expanded(
                          child: Container(
                            margin: const EdgeInsets.only(left: 10, bottom: 8, top: 2),
                            decoration: BoxDecoration(
                              color: Colors.green[50],
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              children: [
                                // Nội dung lịch
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.all(0.0),
                                    child: TableCalendar<Event>(
                                      locale: 'vi_VN', // Ensure locale is correctly set to 'vi_VN'
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
                                      calendarStyle: CalendarStyle(
                                        todayDecoration: BoxDecoration(
                                          color: Colors.blueAccent,
                                          shape: BoxShape.circle,
                                        ),
                                        selectedDecoration: BoxDecoration(
                                          color: Colors.orangeAccent,
                                          shape: BoxShape.circle,
                                        ),
                                        defaultTextStyle: const TextStyle(fontSize: 12),
                                        todayTextStyle: const TextStyle(fontSize: 12, color: Colors.white),
                                        selectedTextStyle: const TextStyle(fontSize: 12, color: Colors.white),
                                      ),
                                      headerStyle: HeaderStyle(
                                        formatButtonVisible: false,
                                        titleCentered: true,
                                        leftChevronIcon: const Icon(Icons.chevron_left, size: 16),
                                        rightChevronIcon: const Icon(Icons.chevron_right, size: 16),
                                        titleTextStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                        leftChevronMargin: const EdgeInsets.only(left: 8.0),
                                        rightChevronMargin: const EdgeInsets.only(right: 8.0),
                                        titleTextFormatter: (date, locale) => DateFormat.yMMMM(locale).format(date).toUpperCase(), // Format title with uppercase 'THÁNG'
                                      ),
                                      eventLoader: _getEventsForDay,
                                      availableCalendarFormats: const {
                                        CalendarFormat.month: 'Tháng',
                                        CalendarFormat.twoWeeks: 'Hai tuần',
                                      },
                                    ),
                                  ),
                                )
                              ],
                            ),
                          ),
                        ),
                        // Sự kiện trong ngày
                        Expanded(
                          child: Container(
                            margin: const EdgeInsets.only(left: 10, top: 10, bottom: 4),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              color: Colors.yellow[50],
                            ),
                            child: Row(
                              children: [
                                // Left Side: Event List with Title
                                Expanded(
                                  flex: 50,
                                  child: Padding(
                                    padding: const EdgeInsets.fromLTRB(0, 10, 0, 0),
                                    child: LayoutBuilder(
                                      builder: (context, constraints) {
                                        return SizedBox(
                                          height: constraints.maxHeight,
                                          child: SingleChildScrollView(
                                            child: Column(
                                              children: [
                                                // Title Text
                                                const Text(
                                                  'Danh sách sự kiện trong ngày',
                                                  style: TextStyle(
                                                    fontSize: 18, // Increased font size for prominence
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.black87, // Optional: Set a specific color
                                                  ),
                                                ),
                                                const SizedBox(height: 10), // Space between title and event list

                                                // Existing DailyEventBox
                                                DailyEventBox(
                                                  selectedDay: _selectedDay ?? _focusedDay,
                                                  events: _getEventsForDay(_selectedDay ?? _focusedDay),
                                                  onEdit: _editEvent,
                                                  onDelete: _deleteEvent,
                                                  scrollable: true,
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  /// Lấy các sự kiện cho một ngày cụ thể
  List<Event> _getEventsForDay(DateTime day) {
    return _events.entries.where((entry) => isSameDay(entry.key, day)).map((entry) => entry.value).expand((events) => events).toList();
  }
}
