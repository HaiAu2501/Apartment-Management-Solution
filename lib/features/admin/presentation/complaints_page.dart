import 'package:flutter/material.dart';
// import 'dart:math';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import '..//domain/complaints.dart';
import '..//data/complaints_repository.dart';
import '../../.authentication/data/auth_service.dart';

class ComplaintsPage extends StatefulWidget {
  final AuthenticationService authService;
  const ComplaintsPage({super.key, required this.authService});

  @override
  State<ComplaintsPage> createState() => _ComplaintsPageState();
}

class _ComplaintsPageState extends State<ComplaintsPage> {
   List<Complaint> complaints=[];
  late List<Complaint> deletedComplaints;
  late List<Complaint> allComplaints;
  late final ComplaintsRepository complaintsRepository;
  late final AuthenticationService authService;
  bool _isLoading=true;
  Complaint? selectedComplaint;
  int? hoveredTileIndex;
  Color _menuBackgroundColor = Colors.transparent;
  Color _binBackgroundColor = Colors.transparent;
  List<Complaint> chosenList = [];
  List<Complaint> updateQueue=[];

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


  @override
  void initState() {
    super.initState();
    authService = widget.authService;
    complaintsRepository = ComplaintsRepository(
      apiKey: authService.apiKey,
      projectId: authService.projectId,
    );
    _fetchComplaints();
    
    deletedComplaints=[];
  }

  @override
  void dispose(){
    super.dispose();
    _updateComplaints();
  }

  Future<void> _fetchComplaints() async {
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
      List<dynamic> allDocuments =
          await complaintsRepository.fetchAllComplaints(idToken);
     List<Complaint> complaintsFetched = allDocuments.map((doc) {
        return Complaint.fromFirestore(doc['fields'], doc['name']);
      }).toList();
      if (mounted) {
        setState(() {
            complaints=complaintsFetched;
            
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        complaints=[];
      });
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching events: $e')),
        );
      }
    } finally{
      sortByDate();
    allComplaints=complaints;
    }
  }

  //update func
   Future<void> _updateComplaints() async {
    
    try {
      String? idToken = await authService.getIdToken(); // Lấy ID token
      if (idToken == null) {
        throw Exception('User not authenticated');
      }
      for(var complaint in updateQueue){
        Map<String, dynamic> updatedData = complaint.toFirestore();
        print('khang check di:${complaint.id}');
        await complaintsRepository.updateComplaint(
          complaint.id,
          updatedData,
          idToken,
        );
      }
      
    } catch (e) {
      print('Error updating complaint: $e');
    } 
  }

  void _addUpdateQueue(Complaint complaint) {
    setState(() {
      if (!updateQueue.contains(complaint)) {
        updateQueue.add(complaint);
      }
    });
  }

  // Hàm sắp xếp theo ngày (từ mới đến cũ)
  void sortByDate() {
    setState(() {
      complaints.sort((a,b) => b.date.compareTo(a.date));
    });
  }

  String getNumberCharacters(int number, String name) {
    if (name.length > number) {
      return '${name.substring(0, number)}...';
    }
    return name;
  }

  static String getAvatarName(String name) {
    if(name=='') {return 'error';}
    String result = name[0];
    for (int i = name.length - 1; i >= 0; i--) {
      if (name[i] == ' ') {
        result += name[i + 1];
        return result;
      }
    }
    return result;
  }

  // Hàm sắp xếp theo trạng thái
  void sortByStatus() {
    setState(() {
      complaints.sort((a, b) {
        const statusOrder = ['Mới', 'Đang xử lý', 'Hoàn tất'];
        return statusOrder
            .indexOf(a.status!)
            .compareTo(statusOrder.indexOf(b.status!));
      });
    });
  }

  void _handleMenuTap() {
    setState(() {
      complaints = allComplaints;
    });
  }

  void _handleBinTap() {
    setState(() {
      complaints = deletedComplaints;
    });
  }

  void sortByStarred() {
    setState(() {
      complaints.sort((a, b) {
        const starredOrder = [true, false];
        return starredOrder
            .indexOf(a.isFlagged)
            .compareTo(starredOrder.indexOf(b.isFlagged));
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý khiếu nại'),
      ),
      backgroundColor: const Color.fromARGB(255, 238, 240, 242),
      body: _isLoading
      ? const Center(child: CircularProgressIndicator(),)
      :
      
      Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/bgimage/complaintbg.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: Row(
          children: [
            if (MediaQuery.of(context).size.width > 1300)
              Expanded(
                  flex: 25,
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(0, 12, 0, 0),
                    decoration:
                        BoxDecoration(color: Colors.white.withOpacity(0.5)),
                    child: Column(
                      children: [
                        const SizedBox(
                          height: 4,
                        ),
                        const Row(
                          children: [
                            SizedBox(
                              width: 14,
                            ),
                            Text(
                              'Quan trọng',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(
                          height: 20,
                        ),
                        //here
                        MouseRegion(
                          onEnter: (_) {
                            setState(() {
                              _menuBackgroundColor = Colors.grey;
                            });
                          },
                          onExit: (_) {
                            setState(() {
                              _menuBackgroundColor = Colors.transparent;
                            });
                          },
                          child: GestureDetector(
                            onTap: _handleMenuTap,
                            child: Container(
                              color: _menuBackgroundColor,
                              padding: const EdgeInsets.fromLTRB(15, 8, 15, 8),
                              child: Row(
                                children: [
                                  const Expanded(
                                    child: Row(
                                      children: [
                                        Icon(FluentIcons.send_24_regular,
                                            color:
                                                Color.fromARGB(200, 56, 56, 53),
                                            size: 22),
                                        SizedBox(
                                          width: 12,
                                        ),
                                        Text(
                                          'Message',
                                          style: TextStyle(
                                              fontWeight: FontWeight.w500),
                                        )
                                      ],
                                    ),
                                  ),
                                  Text(
                                    allComplaints.length.toString(),
                                    style: const TextStyle(
                                        color:
                                            Color.fromARGB(255, 48, 89, 171)),
                                  ),
                                  const SizedBox(
                                    width: 8,
                                  )
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(
                          height: 8,
                        ),
                        MouseRegion(
                          onEnter: (_) {
                            setState(() {
                              _binBackgroundColor = Colors.grey;
                            });
                          },
                          onExit: (_) {
                            setState(() {
                              _binBackgroundColor = Colors.transparent;
                            });
                          },
                          child: GestureDetector(
                            onTap: _handleBinTap,
                            child: Container(
                              color: _binBackgroundColor,
                              padding: const EdgeInsets.fromLTRB(15, 8, 15, 8),
                              child: const Row(
                                children: [
                                  Expanded(
                                    child: Row(
                                      children: [
                                        Icon(FluentIcons.delete_20_regular,
                                            color:
                                                Color.fromARGB(200, 56, 56, 53),
                                            size: 22),
                                        SizedBox(
                                          width: 12,
                                        ),
                                        Text(
                                          'Bin',
                                          style: TextStyle(
                                              fontWeight: FontWeight.w500),
                                        )
                                      ],
                                    ),
                                  ),
                                  Text(
                                    '0',
                                    style: TextStyle(
                                        color: Color.fromARGB(255, 13, 24, 45)),
                                  ),
                                  SizedBox(
                                    width: 8,
                                  )
                                ],
                              ),
                            ),
                          ),
                        )
                      ],
                    ),
                  )),
            Expanded(
              flex: 36,
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
                margin: const EdgeInsets.fromLTRB(0, 12, 12, 0),
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
                                    color: Color.fromARGB(255, 42, 101, 149)),
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
                            IconButton(
                              icon: const Icon(FluentIcons.search_24_regular),
                              onPressed: () {
                                // Xử lý sự kiện tìm kiếm
                              },
                            ),
                            PopupMenuButton<String>(
                              icon: const Icon(
                                FluentIcons.filter_24_regular,
                                color: Color.fromARGB(255, 21, 17, 3),
                              ),
                              onSelected: (value) {
                                // Xử lý tùy chọn được chọn
                                switch (value) {
                                  case 'Sắp xếp theo ngày':
                                    sortByDate();
                                    break;
                                  case 'Sắp xếp theo trạng thái':
                                    sortByStatus();
                                    break;
                                  case 'Sắp xếp theo khiếu nại đã đánh dấu':
                                    sortByStarred();
                                    break;
                                }
                              },
                              itemBuilder: (BuildContext context) {
                                return [
                                  'Sắp xếp theo ngày',
                                  'Sắp xếp theo trạng thái',
                                  'Sắp xếp theo khiếu nại đã đánh dấu',
                                ].map((String choice) {
                                  return PopupMenuItem<String>(
                                    value: choice,
                                    child: Text(choice),
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
                          child: _contentWidget(complaints, selectedComplaint)),
                    ],
                  )),
          ],
        ),
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
              complaint.status = 'Đang xử lý';

              setState(() {
                selectedComplaint = complaint;
                _addUpdateQueue(complaint);
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
                        _addUpdateQueue(complaint);
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
                  complaint.date, // Hiển thị ngày tháng ở đây
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
        margin: const EdgeInsets.fromLTRB(5, 12, 25, 15),
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

  Widget _contentWidget(List<Complaint> complaints, Complaint? complaint) {
    int getTotalComplaints() => complaints.length;
    int getStarredComplaints() => complaints.where((c) => c.isFlagged).length;
    int getUnreadComplaints() =>
        complaints.where((c) => c.status == 'Mới').length;
    int getSolvingComplaints() =>
        complaints.where((c) => c.status == 'Đang xử lý').length;
    int getDoneComplaints() =>
        complaints.where((c) => c.status == 'Đã hoàn thành').length;
    if (complaint != null) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 40),
        width: double.infinity,
        margin: const EdgeInsets.fromLTRB(5, 0, 25, 0),
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
                          style: const TextStyle(fontSize: 16)),
                      subtitle: const Text('Tới: (Tên admin ở đây)'),
                      dense: true,
                      trailing: IconButton(
                          icon: const Icon(FluentIcons.arrow_reply_16_regular),
                          onPressed: () {
                            setState(() {
                              selectedComplaint = null;
                            });
                          }),
                    ),
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(15, 5, 5, 25),
                      child: Text(
                        complaint.description,
                        style: const TextStyle(
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        ElevatedButton.icon(
                            label: const Text('Reply',
                                style: TextStyle(
                                    color: Color.fromARGB(255, 90, 90, 92))),
                            onPressed: () {},
                            icon: const Icon(FluentIcons.arrow_reply_16_regular,
                                color: Color.fromARGB(255, 153, 39, 176)),
                            style: ElevatedButton.styleFrom(
                              shadowColor: Colors.grey,
                              elevation: 3,
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
                    // if (complaint.comments != null)
                    //   Column(
                    //     children: complaint.comments!
                    //         .map(
                    //             (comment) => _CommentWidget(complaint, comment))
                    //         .toList(),
                    //   ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 30),
        width: double.infinity,
        margin: const EdgeInsets.fromLTRB(5, 0, 25, 0),
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
                      label: 'Khiếu nại đã xử lý xong',
                      count: getDoneComplaints(),
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

// Widget _CommentWidget(Complaint complaint, String comment) {
//   return Card(
//     elevation: 2,
//     child: ListTile(
//       leading: CircleAvatar(
//         radius: 17,
//         backgroundColor: complaint.bgColor,
//         child: Text(_ComplaintsPageState.getAvatarName(complaint.senter)),
//       ),
//       title: Text(complaint.senter, style: const TextStyle(fontSize: 16)),
//       subtitle: Text(comment),
//       dense: true,
//     ),
//   );
// }

class StatisticCard extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const StatisticCard({super.key, 
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
