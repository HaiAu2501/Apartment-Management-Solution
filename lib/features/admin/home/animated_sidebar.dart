// lib/widgets/animated_sidebar.dart
import 'package:flutter/material.dart';
import 'sidebar_item.dart';

class AnimatedSidebar extends StatefulWidget {
  final List<SidebarItem> items;
  final int selectedIndex;
  final Function(int) onItemSelected;
  final double minWidth;
  final double maxWidth;
  final Gradient? itemSelectedGradient;
  final EdgeInsets margin;
  final double itemMargin;

  const AnimatedSidebar({
    Key? key,
    required this.items,
    required this.selectedIndex,
    required this.onItemSelected,
    this.minWidth = 70,
    this.maxWidth = 250,
    this.itemSelectedGradient,
    this.margin = EdgeInsets.zero, // Giảm margin mặc định
    this.itemMargin = 8.0, // Giảm itemMargin mặc định
  }) : super(key: key);

  @override
  _AnimatedSidebarState createState() => _AnimatedSidebarState();
}

class _AnimatedSidebarState extends State<AnimatedSidebar>
    with SingleTickerProviderStateMixin {
  bool isExpanded = true;

  void toggleSidebar() {
    setState(() {
      isExpanded = !isExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    bool isDesktop = screenWidth >= 600;

    return AnimatedContainer(
      margin: widget.margin,
      width: isExpanded ? widget.maxWidth : widget.minWidth,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.horizontal(
          right: Radius.circular(isExpanded ? 20 : 0),
        ),
      ),
      child: Column(
        children: [
          // Header with toggle button (only on desktop)
          if (isDesktop)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20.0),
              child: IconButton(
                icon: Icon(
                  isExpanded ? Icons.arrow_back : Icons.arrow_forward,
                  color: Colors.black,
                ),
                onPressed: toggleSidebar,
                tooltip: isExpanded ? 'Thu nhỏ Sidebar' : 'Mở rộng Sidebar',
              ),
            ),
          // Divider
          if (isDesktop)
            const Divider(
              thickness: 1,
              color: Colors.grey,
            ),
          // Menu Items
          Expanded(
            child: ListView.builder(
              itemCount: widget.items.length,
              itemBuilder: (context, index) {
                bool isSelected = widget.selectedIndex == index;
                return GestureDetector(
                  onTap: () {
                    widget.onItemSelected(index);
                  },
                  child: Container(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    padding: isExpanded
                        ? const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12)
                        : const EdgeInsets.all(12),
                    decoration: isSelected
                        ? BoxDecoration(
                            gradient: widget.itemSelectedGradient ??
                                LinearGradient(
                                  colors: [
                                    Color.fromRGBO(161, 214, 178, 1),
                                    Color.fromRGBO(241, 243, 194, 1)
                                  ],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                            borderRadius: BorderRadius.circular(8),
                          )
                        : null,
                    child: Row(
                      mainAxisAlignment: isExpanded
                          ? MainAxisAlignment.start
                          : MainAxisAlignment.center,
                      children: [
                        Icon(
                          widget.items[index].icon,
                          color: Colors.black,
                          size: 24,
                        ),
                        if (isExpanded) ...[
                          const SizedBox(width: 16),
                          Flexible(
                            child: Text(
                              widget.items[index].text,
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 16,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
