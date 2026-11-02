
import 'package:flutter/material.dart';

class TaskListScreen extends StatefulWidget {
  final String token;

  const TaskListScreen({
    super.key,
    required this.token,
  });

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  static const Color mauTim = Color(0xFF6554C0);

  // Tab đang chọn
  int tabDangChon = 0;

  // Controller tìm kiếm
  final timKiemController = TextEditingController();

  final List<String> danhSachTab = [
    'Tất cả',
    'Của tôi',
    'Được giao',
    'Được chia sẻ',
  ];

  @override
  void dispose() {
    timKiemController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF8FF),

      appBar: AppBar(
        title: const Text('Danh sách công việc'),
        centerTitle: true,
        backgroundColor: mauTim,
        foregroundColor: Colors.white,
      ),

      body: Column(
        children: [
          // 1. CÁC TAB DANH SÁCH
          SizedBox(
            height: 55,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: danhSachTab.length,
              itemBuilder: (context, index) {
                final dangChon = tabDangChon == index;

                return Padding(
                  padding: const EdgeInsets.all(5),
                  child: ChoiceChip(
                    label: Text(danhSachTab[index]),
                    selected: dangChon,
                    selectedColor: mauTim,
                    labelStyle: TextStyle(
                      color: dangChon
                          ? Colors.white
                          : Colors.black,
                    ),
                    onSelected: (_) {
                      setState(() {
                        tabDangChon = index;
                      });
                    },
                  ),
                );
              },
            ),
          ),

          // 2. Ô TÌM KIẾM
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: timKiemController,
              onChanged: (_) {
                setState(() {});
              },
              decoration: InputDecoration(
                hintText: 'Tìm kiếm công việc...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.filter_list),
                  onPressed: () {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Bộ lọc sẽ được bổ sung ở bước tiếp theo',
                        ),
                      ),
                    );
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          // 3. KHU VỰC DANH SÁCH
          const Expanded(
            child: Center(
              child: Text(
                'Chưa có công việc nào.\n'
                    'Nhấn + để tạo công việc mới.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
            ),
          ),
        ],
      ),

      // 4. NÚT THÊM CÔNG VIỆC
      floatingActionButton: FloatingActionButton(
        backgroundColor: mauTim,
        foregroundColor: Colors.white,
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Màn hình tạo công việc sẽ được bổ sung tiếp theo',
              ),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
