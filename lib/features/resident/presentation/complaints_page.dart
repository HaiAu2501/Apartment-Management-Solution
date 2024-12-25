import 'package:flutter/material.dart';
import 'dart:math';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import '../domain/r_complaints.dart';
import 'package:intl/intl.dart';
import '../data/r_complaints_repository.dart';
import '../../.authentication/data/auth_service.dart';
// import 'package:firebase_auth/firebase_auth.dart';

class ComplaintsPage extends StatefulWidget {
  final AuthenticationService authService;
  const ComplaintsPage({super.key, required this.authService});

  @override
  State<ComplaintsPage> createState() => _ComplaintsPageState();
}

class _ComplaintsPageState extends State<ComplaintsPage> {
  List<Complaint> complaints = [];
  late List<Complaint> deletedComplaints;
  List<Complaint> allComplaints=[];
  late final ComplaintsRepository complaintsRepository;
  late final AuthenticationService authService;
  late final String? idToken;
  late final String? uid;
  late final Map<String, dynamic> residentInfo;
  bool _isLoading = true;
  Complaint? selectedComplaint;
  int? hoveredTileIndex;
  List<Complaint> chosenList = [];

  bool showInputField = false;
  final FocusNode inputFocusNode = FocusNode();
  final TextEditingController _commentController = TextEditingController();

  Future<void> getUidAndIdtoken() async {
    idToken = await authService.getIdToken();
    uid = await authService.getUserUid(idToken!);
    residentInfo = await complaintsRepository.getUserData(uid!, idToken!);
  }

  void addChosen(Complaint complaint) {
    setState(() {
      chosenList.add(complaint);
    });
  }

  void removeChosen(Complaint complaint) {
    setState(() {
      chosenList.remove(complaint);
    });
  }

  void toggleSelectAllButton() {
    if (chosenList.isEmpty) {
      for (Complaint c in complaints) {
        chosenList.add(c);
      }
    } else {
      chosenList.clear();
    }
    setState(() {});
  }

  void markAsUnread() {
    for (var x in chosenList) {
      x.status = 'Mới';
      _updateComplaint(x);
    }
    chosenList = [];
    setState(() {});
  }

  void sortComplaintsByDate({bool descending = true}) {
  complaints.sort((a, b) {
    if (descending) {
      return b.date.compareTo(a.date); // Mới nhất trước
    } else {
      return a.date.compareTo(b.date); // Cũ nhất trước
    }
  });
}


  void showAddComplaintWidget(BuildContext context) {
    String convertTime() {
      DateTime now = DateTime.now();
      String formattedDate = DateFormat('yyyy-MM-dd HH:mm').format(now);
      return formattedDate;
    }



    TextEditingController titleAddController = TextEditingController();
    TextEditingController descriptionController = TextEditingController();
    showDialog(
      context: context,
      barrierDismissible: true, // Cho phép bấm ra ngoài để đóng
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          title: const Text('Khiếu nại mới'),
          content: Container(
            width: MediaQuery.of(context).size.width *
                0.5, // Chiếm 70% chiều rộng màn hình
            height: MediaQuery.of(context).size.height *
                0.6, // Chiếm 70% chiều cao màn hình
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 20),
                Row(
                  children: [
                    Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                              color: Colors.grey,
                              width: 1), // Viền màu xám, độ dày 1
                          borderRadius: BorderRadius.circular(4), // Bo góc viền
                        ),
                        padding: const EdgeInsets.fromLTRB(16,6,16,6),
                        child: const Text('Fr')),
                        const SizedBox(width: 8,),
                    Expanded(
                      child: TextField(
                        readOnly: true,
                        decoration: InputDecoration(labelText:residentInfo['fields']['email']['stringValue'] ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8,),
                Row(
                  children: [
                    Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                              color: Colors.grey,
                              width: 1), // Viền màu xám, độ dày 1
                          borderRadius: BorderRadius.circular(4), // Bo góc viền
                        ),
                        padding: const EdgeInsets.fromLTRB(16,6,16,6),
                        child: const Text('To')),
                        const SizedBox(width: 8,),
                    const Expanded(
                      child: TextField(
                        readOnly: true,
                        decoration: InputDecoration(labelText: 'admin'),
                      ),
                    ),
                  ],
                ),
                TextField(
                  controller: titleAddController,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    labelStyle: TextStyle(color: Colors.black54),
                    border: UnderlineInputBorder(),
                  ),
                ),
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    labelStyle: TextStyle(color: Colors.black54),
                    border: InputBorder.none,
                  ),
                  controller: descriptionController,
                  // decoration: const InputDecoration(hintText: 'Mô tả'),
                  maxLines: null, // Cho phép xuống dòng không giới hạn
                  keyboardType: TextInputType
                      .multiline, // Loại bàn phím hỗ trợ nhập nhiều dòng
                  textInputAction: TextInputAction
                      .newline, // Cho phép thêm dòng mới khi nhấn Enter
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Đóng dialog
              },
              child: const Text('Hủy'),
            ),
            TextButton(
              onPressed: () async {
                String title = titleAddController.text;
                String description = descriptionController.text;
                List<Map<dynamic, dynamic>> comments = [];
                String userName = 'Lỗi khi lấy tên người dùng';
                if (residentInfo != null) {
                  userName = residentInfo['fields']['fullName']['stringValue'];
                }
                Map<String, dynamic> complaintData = {
                  'uid': uid,
                  'title': title,
                  'senter': userName,
                  'description': description,
                  'status': 'Mới',
                  'date': convertTime(),
                  'isFlagged': false,
                  'comments': comments,
                };

                Complaint newComplaint = Complaint(
                    uid: uid ?? '',
                    senter: userName,
                    title: title,
                    description: description,
                    date: convertTime(),
                    id: '123',
                    isFlagged: false,
                    bgColor:complaints.isEmpty?generateRandomColor(): complaints[0].bgColor);
                _addComplaint(complaintData, newComplaint);
                Navigator.pop(context); // Thực hiện logic, rồi đóng dialog
              },
              child: const Text('Gửi'),
            ),
          ],
        );
      },
    );
  }
  final List<Color> colorPalette = [
        const Color(0xffd69ca5),
        const Color(0xff94c8d4),
        const Color(0xffd696c0),
        const Color(0xffa6e9ed),
        const Color(0xff9ad29a),
        const Color(0xffcecccb)
      ];
  Color generateRandomColor() {    
        final randomColor = colorPalette[Random().nextInt(colorPalette.length)];
        return randomColor;
      }

  @override
  void initState() {
    super.initState();
    authService = widget.authService;
    complaintsRepository = ComplaintsRepository(
      apiKey: authService.apiKey,
      projectId: authService.projectId,
    );
    getUidAndIdtoken();
    _fetchComplaints();

  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
    inputFocusNode.dispose();
  }

  Future<void> _fetchComplaints() async {
    String? idToken;
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }
    try {
      idToken = await authService.getIdToken(); // Get ID token
      if (idToken == null) {
        throw Exception('User not authenticated');
      }
      List<dynamic> allDocuments =
          await complaintsRepository.fetchAllComplaints(idToken);
      List<Complaint> complaintsFetched = allDocuments.map((doc) {
        return Complaint.fromFirestore(doc['fields'], doc['name']);
      }).toList();
      if (mounted) {
        String? usid = await authService.getUserUid(idToken);

        setState(() {
          allComplaints = complaintsFetched;
          complaints = allComplaints.where((x) => x.uid == usid!).toList();
          sortComplaintsByDate();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          complaints = [];
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching complaints: $e')),
        );
      }
    } finally {
      allComplaints = complaints;
    }
  }

  Future<void> _deleteComplaint(Complaint complaint) async {
    try {
      if (idToken == null) {
        throw Exception('User not authenticated');
      }
      complaintsRepository.deleteComplaint(complaint.id, idToken!);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error delete complaint: $e')),
        );
      }
    } finally {
      setState(() {
        complaints = complaints.where((x) => x.id != complaint.id).toList();
      });
    }
  }

  Future<void> _addComplaint(
      Map<String, dynamic> complaintData, Complaint newComplaint) async {
    try {
      await complaintsRepository.addComplaint(
          complaintData, idToken!, newComplaint);
      print(newComplaint.id);
      setState(() {
        complaints.insert(0,newComplaint);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error add complaint: $e')),
        );
      }
    }
  }

  Future<void> _updateComplaint(Complaint complaint) async {
    try {
      if (idToken == null) {
        throw Exception('User not authenticated');
      }
      Map<String, dynamic> updatedData = complaint.toFirestore();
      print(complaint.id);
      complaintsRepository.updateComplaint(
        complaint.id,
        updatedData,
        idToken!,
      );
    } catch (e) {
      print('Error updating complaint: $e');
    }
  }

  String splitTextIntoLines(String inputText, int maxLineLength) {
    List<String> resultLines = [];
    List<String> words = inputText.split(' '); // Chia chuỗi thành các từ
    String currentLine = '';

    for (String word in words) {
      // Nếu thêm từ này vào dòng hiện tại không vượt quá độ dài tối đa
      if ((currentLine + word).length <= maxLineLength) {
        currentLine += (currentLine.isEmpty ? '' : ' ') +
            word; // Thêm từ vào dòng hiện tại
      } else {
        // Nếu vượt quá, thêm dòng hiện tại vào kết quả và bắt đầu một dòng mới
        resultLines.add(currentLine);
        currentLine = word;
      }
    }

    // Thêm dòng cuối cùng vào kết quả nếu có
    if (currentLine.isNotEmpty) {
      resultLines.add(currentLine);
    }

    // Trả về chuỗi đã tách thành các dòng
    return resultLines.join('\n');
  }

  void _addComment(Complaint complaint) {
    String commentContent = _commentController.text.trim();
    commentContent = splitTextIntoLines(commentContent, 100);
    if (commentContent.isNotEmpty) {
      final newComment = {
        'user': 'Khang tester',
        'content': commentContent,
      };

      setState(() {
        complaint.comments.add(newComment);
      });
      _updateComplaint(complaint);
    }

    _commentController.clear();
  }

  void showAllComplaints() {
    setState(() {
      complaints = allComplaints;
    });
  }

  static String getAvatarName(String name) {
    if (name == '') {
      return 'error';
    }
    String result = name[0];
    for (int i = name.length - 1; i >= 0; i--) {
      if (name[i] == ' ') {
        result += name[i + 1];
        return result;
      }
    }
    return result;
  }

  void showUnreadComplaints() {
    setState(() {
      complaints = allComplaints
          .where((complaint) => complaint.status == 'Mới')
          .toList();
    });
  }

  void showFlaggedComplaints() {
    setState(() {
      setState(() {
        complaints = allComplaints
            .where((complaint) => complaint.isFlagged == true)
            .toList();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 238, 240, 242),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : Row(
              children: [
                Expanded(
                  flex: 28,
                  child: Container(
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: const Color.fromARGB(255, 52, 46, 46).withOpacity(
                              0.5), // Màu bóng, bạn có thể điều chỉnh độ mờ ở đây
                          blurRadius: 8.0, // Độ mờ của bóng
                          spreadRadius: 2.0, // Độ lan tỏa của bóng
                          offset: const Offset(0, 2), // Vị trí bóng
                        ),
                      ],
                      color: const Color(0xfff5f5f5),
                    ),
                    margin: const EdgeInsets.fromLTRB(20, 12, 12, 0),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(children: [
                              IconButton(
                                onPressed: toggleSelectAllButton,
                                icon: chosenList.isEmpty
                                    ? const Icon(
                                        FluentIcons.select_all_off_16_regular)
                                    : const Icon(
                                        FluentIcons.select_all_on_16_filled,
                                        color:
                                            Color.fromARGB(255, 42, 101, 149)),
                              ),
                              const SizedBox(width: 22),
                              const Text(
                                'Khiếu nại',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ]),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                chosenList.isNotEmpty
                                    ? Row(
                                        children: [
                                          IconButton(
                                              onPressed: () {
                                                for (var x in chosenList) {
                                                  _deleteComplaint(x);
                                                }
                                                chosenList = [];
                                                setState(() {});
                                              },
                                              icon: const Icon(
                                                  FluentIcons.delete_20_regular,
                                                  size: 20,
                                                  color: Color.fromARGB(
                                                      255, 59, 111, 163))),
                                          IconButton(
                                            tooltip: 'Mark as unread',
                                            icon: const Icon(
                                                FluentIcons.mail_20_regular,
                                                color: Color.fromARGB(
                                                    255, 59, 111, 163)),
                                            onPressed: () {
                                              markAsUnread();
                                            },
                                          ),
                                        ],
                                      )
                                    : IconButton(
                                        onPressed: () {
                                          showAddComplaintWidget(context);
                                        },
                                        icon: const Icon(
                                          FluentIcons.edit_24_filled,
                                          color: Color.fromARGB(164, 3, 33, 62),
                                          size: 20,
                                        ),
                                        tooltip: 'New Complaint',
                                      ),
                                PopupMenuButton<String>(
                                  surfaceTintColor:
                                      const Color.fromARGB(255, 69, 138, 195),
                                  tooltip: 'Filter',
                                  icon: const Icon(
                                    FluentIcons.filter_24_regular,
                                    color: Color.fromARGB(255, 21, 17, 3),
                                  ),
                                  color:
                                      const Color.fromARGB(255, 249, 244, 244),
                                  offset: const Offset(0, 40),
                                  onSelected: (value) {
                                    // Xử lý tùy chọn được chọn
                                    switch (value) {
                                      case 'All':
                                        showAllComplaints();
                                        break;
                                      case 'Unread':
                                        showUnreadComplaints();
                                        break;
                                      case 'Flagged':
                                        showFlaggedComplaints();
                                        break;
                                    }
                                  },
                                  itemBuilder: (BuildContext context) {
                                    return [
                                      {
                                        'icon': FluentIcons.mail_24_regular,
                                        'text': 'All'
                                      },
                                      {
                                        'icon':
                                            FluentIcons.mail_unread_24_regular,
                                        'text': 'Unread'
                                      },
                                      {
                                        'icon': FluentIcons.flag_24_regular,
                                        'text': 'Flagged'
                                      },
                                    ].map((item) {
                                      return PopupMenuItem<String>(
                                        value: item['text'] as String,
                                        child: Row(
                                          children: [
                                            Icon(
                                              item['icon'] as IconData,
                                            ), // Icon
                                            const SizedBox(
                                                width:
                                                    10), // Khoảng cách giữa Icon và Text
                                            Text(item['text'] as String),
                                            const SizedBox(
                                              width: 8,
                                            ) // Text
                                          ],
                                        ),
                                      );
                                    }).toList();
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                        Container(
                          height: 0.6, // Thickness of the line
                          color: const Color.fromARGB(
                              255, 119, 119, 119), // Color of the line
                          margin: const EdgeInsets.symmetric(
                              horizontal: 0.0), // Optional: padding on sides
                        ),
                        Expanded(
                          child: ListView.builder(
                            itemCount: complaints.length,
                            itemBuilder: (context, index) {
                              final complaint = complaints[index];

                              return Card(
                                key: ValueKey(complaint.id),
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.zero,
                                  // Loại bỏ border radius
                                ),
                                margin: const EdgeInsets.symmetric(
                                    horizontal: 1, vertical: 1),
                                child: Container(
                                  decoration: BoxDecoration(
                                    // color: complaint.status == 'Mới' ? const Color.fromARGB(255, 216, 218, 222) : const Color.fromARGB(255, 235, 235, 240), // Màu nền
                                    borderRadius: BorderRadius.circular(0),
                                    // BorderRadius
                                  ),
                                  child: _complaintTile(complaint, index),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (MediaQuery.of(context).size.width > 800)
                  Expanded(
                      flex: 85,
                      child: Column(
                        children: [
                          _titleWidget(),
                          Expanded(
                              child: _contentWidget(complaints,
                                  selectedComplaint, _commentController)),
                        ],
                      )),
              ],
            ),
    );
  }

  Widget _complaintTile(Complaint complaint, int index) {
    IconData flagIcon;
    flagIcon = complaint.isFlagged
        ? FluentIcons.flag_16_filled
        : FluentIcons.flag_16_regular;
    IconData chosenIcon;
    chosenIcon = chosenList.contains(complaint)
        ? FluentIcons.checkbox_checked_20_filled
        : FluentIcons.checkbox_unchecked_20_regular;
    Color backgroundColor = const Color(0xffffffff);
    backgroundColor = index == hoveredTileIndex
        ? const Color.fromARGB(255, 230, 231, 232)
        : backgroundColor;
    backgroundColor = complaint.isFlagged
        ? const Color.fromARGB(255, 252, 249, 212)
        : backgroundColor;
    backgroundColor = complaint == selectedComplaint
        ? const Color.fromARGB(255, 200, 224, 248)
        : backgroundColor;
    backgroundColor = chosenList.contains(complaint)
        ? const Color.fromARGB(255, 200, 224, 248)
        : backgroundColor;
    void toggleStar(Complaint complaint) {
      setState(() {
        complaint.isFlagged = complaint.isFlagged ? false : true;
      });
    }

    void updateHoveredTileIndex(int? index) {
      setState(() {
        hoveredTileIndex = index;
      });
    }

    String getDate(String time){
      return time.substring(0,10);
    }

    

    return Container(
      padding: const EdgeInsets.fromLTRB(0, 0, 5, 0),
      decoration: BoxDecoration(
        // color: backgroundColor,
        border: Border(
          left: BorderSide(
            color: complaint.status == 'Mới'
                ? const Color.fromARGB(255, 120, 177, 223)
                : complaint == selectedComplaint
                    ? const Color.fromARGB(255, 109, 178, 235)
                    : backgroundColor, // Màu xanh nếu là "Mới", màu trong suốt nếu không
            width: index == hoveredTileIndex ? 6 : 4, // Độ dày của đường viền
          ),
        ),
      ),
      child: MouseRegion(
        onEnter: (e) {
          updateHoveredTileIndex(index);
        },
        onExit: (e) {
          updateHoveredTileIndex(null);
        },
        child: ListTile(
            tileColor: backgroundColor,
            onTap: () {
              if (complaint.status == 'Mới') {
                complaint.status = 'Đang xử lý';
                _updateComplaint(complaint);
              }
              setState(() {
                selectedComplaint = complaint;
                showInputField = false;
              });
            },
            leading: (index != hoveredTileIndex &&
                    complaint != selectedComplaint &&
                    !chosenList.contains(complaint))
                ? CircleAvatar(
                    radius: 17,
                    backgroundColor: complaint.bgColor,
                    child: Text(getAvatarName(complaint.senter)),
                  )
                : CircleAvatar(
                    radius: 17,
                    backgroundColor: Colors.transparent,
                    child: IconButton(
                        onPressed: () {
                          if (chosenList.contains(complaint)) {
                            removeChosen(complaint);
                            complaint.chosen = false;
                          } else {
                            addChosen(complaint);
                            complaint.chosen = true;
                          }
                        },
                        icon: Icon(chosenIcon,
                            color: const Color.fromARGB(255, 42, 101, 149)))),
            title: Text(
              complaint.senter,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: complaint.status == 'Mới'
                  ? const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500, // Đậm hơn
                      color: Colors.black, // Màu chữ có thể thay đổi
                    )
                  : const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Colors.black,
                    ), // Dùng mặc định nếu không phải "Mới"
            ),
            subtitle: Container(
              margin: const EdgeInsets.only(top: 1),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    complaint.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: complaint.status == 'Mới'
                        ? const TextStyle(
                            fontWeight: FontWeight.w500, // Đậm hơn
                            color: Color.fromARGB(
                                255, 48, 89, 171), // Màu chữ có thể thay đổi
                          )
                        : const TextStyle(
                            fontWeight: FontWeight.w400,
                            color: Colors
                                .black), // Dùng mặc định nếu không phải "Mới"
                  ),
                  Text(
                    complaint.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style:
                        const TextStyle(color: Color.fromARGB(255, 92, 91, 91)),
                  ),
                ],
              ),
            ),
            trailing: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (index == hoveredTileIndex || complaint.isFlagged)
                  IconButton(
                      icon: Icon(flagIcon,
                          color: complaint.isFlagged
                              ? const Color(0xffbc2f32)
                              : const Color.fromARGB(255, 84, 84, 84)),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () {
                        toggleStar(complaint);
                        _updateComplaint(complaint);
                      }),
                if (index != hoveredTileIndex && !complaint.isFlagged)
                  IconButton(
                      icon: const Icon(null,
                          color: Color.fromARGB(255, 137, 133, 133)),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () {
                        toggleStar(complaint);
                      }),
                Text(
                  getDate(complaint.date), // Hiển thị ngày tháng ở đây
                  style: complaint.status == 'Mới'
                      ? const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500, // Đậm hơn
                          color: Color(0xee3138cb), // Màu chữ có thể thay đổi
                        )
                      : const TextStyle(
                          fontSize: 13,
                          color: Colors.grey,
                        ),
                ),
              ],
            )),
      ),
    );
  }

  Widget _titleWidget() {
    return Container(
        padding: const EdgeInsets.fromLTRB(15, 10, 15, 8),
        width: double.infinity,
        margin: const EdgeInsets.fromLTRB(25, 12, 25, 15),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2), // Màu bóng
                offset: const Offset(0, 4), // Độ dịch chuyển bóng (x, y)
                blurRadius: 10, // Độ mờ của bóng
                spreadRadius: 2, // Độ lan tỏa của bóng
              ),
            ]),
        child: Text(
          selectedComplaint != null
              ? selectedComplaint!.title
              : 'Chọn một khiếu nại để xem chi tiết',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            shadows: [
              Shadow(
                offset: const Offset(4.0, 4.0), // Position of the shadow
                blurRadius: 10.0, // Softness of the shadow
                color: const Color.fromARGB(255, 99, 96, 96)
                    .withOpacity(0.5), // Shadow color with transparency
              ),
            ],
          ),
        ));
  }

  Widget _contentWidget(List<Complaint> complaints, Complaint? complaint,
      TextEditingController commentController) {
    int getTotalComplaints() => complaints.length;
    int getStarredComplaints() => complaints.where((c) => c.isFlagged).length;
    int getUnreadComplaints() =>
        complaints.where((c) => c.status == 'Mới').length;
    int getSolvingComplaints() =>
        complaints.where((c) => c.status == 'Đang xử lý').length;

    if (complaint != null) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 30),
        width: double.infinity,
        margin: const EdgeInsets.fromLTRB(25, 0, 25, 0),
        decoration: BoxDecoration(
            color: const Color(0xfffaf9f8),
            borderRadius: BorderRadius.circular(6),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2), // Màu bóng
                offset: const Offset(0, 4), // Độ dịch chuyển bóng (x, y)
                blurRadius: 10, // Độ mờ của bóng
                spreadRadius: 2, // Độ lan tỏa của bóng
              ),
            ]),
        child: ListView(
          children: [
            Card(
              elevation: 4,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 15, horizontal: 15),
                decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 255, 255, 255),
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2), // Màu bóng
                        offset:
                            const Offset(0, 4), // Độ dịch chuyển bóng (x, y)
                        blurRadius: 10, // Độ mờ của bóng
                        spreadRadius: 2, // Độ lan tỏa của bóng
                      ),
                    ]),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ListTile(
                      shape: const Border(
                        bottom: BorderSide(
                            color: Color.fromARGB(255, 101, 10, 10),
                            width: 1.0),
                      ),
                      leading: CircleAvatar(
                        radius: 17,
                        backgroundColor: complaint.bgColor,
                        child: Text(getAvatarName(complaint.senter)),
                      ),
                      title: Text(complaint.senter,
                          style: const TextStyle(fontSize: 16,fontWeight: FontWeight.w500)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Tới: Quản lý',style: TextStyle(fontSize: 13),),
                          Text(selectedComplaint==null?'': selectedComplaint!.date.substring(11),
                            style: TextStyle(color: const Color.fromARGB(255, 75, 75, 133)
                                        .withOpacity(0.8),
                                        fontStyle: FontStyle.italic),
                            ),
                        ],
                      ),
                      dense: true,
                      trailing: 
                          IconButton(
                              icon: const Icon(FluentIcons.arrow_reply_16_regular),
                              onPressed: () {
                                setState(() {
                                  selectedComplaint = null;
                                });
                              }),
                              
                      
                    ),
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(15, 5, 5, 25),
                      child: Text(
                        complaint.description,
                        style: const TextStyle(
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        
                        ElevatedButton.icon(
                            label: Text('Reply',
                                style: TextStyle(
                                    color: const Color.fromARGB(255, 90, 90, 92)
                                        .withOpacity(0.8),
                                        
                                        )
                                        ),
                            onPressed: () {
                              setState(() {
                                if (!showInputField) {
                                  showInputField = true;
                                }
                              });
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if (context.mounted) {
                                  FocusScope.of(context)
                                      .requestFocus(inputFocusNode);
                                }
                              });
                            },
                            icon: Icon(FluentIcons.arrow_reply_16_regular,
                                color: const Color.fromARGB(255, 153, 39, 176)
                                    .withOpacity(0.8)),
                            style: ElevatedButton.styleFrom(
                              shadowColor: Colors.grey,
                              elevation: 2,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16, // Padding horizontally
                                vertical: 8, // Padding vertically
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                    14), // Bo tròn các góc
                              ),
                            )),
                        const SizedBox(width: 10),
                        
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      height: 1,
                      color: const Color.fromARGB(255, 204, 203, 203),
                    ),
                    const SizedBox(height: 10),
                    if (complaint.comments != [])
                      Column(
                        children: complaint.comments
                            .map((comment) => commentWidget(complaint, comment))
                            .toList(),
                      ),
                    if (showInputField)
                      TextField(
                        focusNode: inputFocusNode,
                        style: const TextStyle(
                          fontSize: 14, // Cỡ chữ của input text
                        ),
                        controller: commentController,
                        decoration: InputDecoration(
                          hintText: 'Nhập bình luận...',
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15), // Bo góc
                            borderSide: BorderSide(
                              color: Colors.grey
                                  .withOpacity(0.5), // Màu xám với opacity
                              width: 1, // Độ dày viền
                            ),
                          ),
                          // Đường viền khi focus
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16), // Bo góc
                            borderSide: BorderSide(
                              color: const Color.fromARGB(255, 174, 116, 186)
                                  .withOpacity(0.6), // Màu xanh với opacity
                              width: 2, // Độ dày viền
                            ),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          suffixIcon: IconButton(
                            icon: const Icon(
                              FluentIcons.send_24_regular,
                            ),
                            hoverColor: Colors.transparent,
                            highlightColor:
                                const Color.fromARGB(255, 241, 198, 241)
                                    .withOpacity(0.6),
                            onPressed: () {
                              _addComment(complaint);
                            },
                          ),
                        ),
                        maxLines: null,
                        textInputAction: TextInputAction.newline,
                        onSubmitted: (value) {
                          _addComment(complaint);
                        },
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 30),
        width: double.infinity,
        margin: const EdgeInsets.fromLTRB(25, 0, 25, 0),
        decoration: BoxDecoration(
            color: const Color(0xfffaf9f8),
            borderRadius: BorderRadius.circular(6),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2), // Màu bóng
                offset: const Offset(0, 4), // Độ dịch chuyển bóng (x, y)
                blurRadius: 10, // Độ mờ của bóng
                spreadRadius: 2, // Độ lan tỏa của bóng
              ),
            ]),
        child: Column(mainAxisAlignment: MainAxisAlignment.start, children: [
          Card(
              elevation: 10,
              color: Colors.white,
              child: Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text(
                      'Thống kê',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 20,
                      ),
                    ),
                    const SizedBox(
                      height: 18,
                    ),
                    StatisticCard(
                      label: 'Tổng số khiếu nại',
                      count: getTotalComplaints(),
                      color: Colors.black,
                    ),
                   
                    StatisticCard(
                      label: 'Khiếu nại chưa đọc',
                      count: getUnreadComplaints(),
                      color: Colors.red,
                    ),
                    StatisticCard(
                      label: 'Đã đánh dấu',
                      count: getStarredComplaints(),
                      color: Colors.black,
                    ),
                    StatisticCard(
                      label: 'Đang xử lý',
                      count: getSolvingComplaints(),
                      color: Colors.black,
                    ),
                  ],
                ),
              ))
        ]),
      );
    }
  }
}

Widget commentWidget(Complaint complaint, Map<String, dynamic> comment) {
  if (comment['user'] != 'admin') {
    return Column(
      children: [
        Row(
          children: [
            IntrinsicWidth(
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                      18), // Chỉnh sửa bán kính bo góc ở đây
                ),
                elevation: 2,
                child: ListTile(
                  leading: CircleAvatar(
                    radius: 17,
                    backgroundColor: complaint.bgColor,
                    child: Text(
                        _ComplaintsPageState.getAvatarName(complaint.senter)),
                  ),
                  title: Text(complaint.senter,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w400)),
                  subtitle: Text(comment['content'],
                      style: const TextStyle(fontSize: 14)),
                  dense: true,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(
          height: 8,
        )
      ],
    );
  } else {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            IntrinsicWidth(
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                      15), // Chỉnh sửa bán kính bo góc ở đây
                ),
                elevation: 2,
                child: ListTile(
                  leading: const CircleAvatar(
                    radius: 17,
                    backgroundColor: Color.fromARGB(255, 91, 203, 145),
                    child: Text('AD'),
                  ),
                  title: const Row(
                    children: [
                      Text('Quản lý',
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w400)),
                      SizedBox(
                        width: 4,
                      ),
                      Icon(
                        FluentIcons.shield_16_regular,
                        color: Colors.green,
                      ),
                    ],
                  ),
                  subtitle: Text(
                    comment['content'],
                    style: const TextStyle(fontSize: 14),
                    softWrap: true,
                  ),
                  dense: true,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(
          height: 8,
        )
      ],
    );
  }
}

class StatisticCard extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const StatisticCard({
    super.key,
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          const SizedBox(
            width: 8,
          ),
          Text(
            '$label :  ',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
