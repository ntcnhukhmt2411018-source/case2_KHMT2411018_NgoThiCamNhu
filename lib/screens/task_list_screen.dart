
import 'package:flutter/material.dart';

// Màn hình tạo công việc
import 'task_create_screen.dart';

// Service kết nối MongoDB
import '../services/task_service.dart';

class TaskListScreen extends StatefulWidget {
  final String token;

  const TaskListScreen({
    super.key,
    required this.token,
  });

  @override
  State<TaskListScreen> createState() =>
      _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  // 1. MÀU CHỦ ĐẠO
  static const Color mauTim = Color(0xFF6554C0);

  // 2. TAB ĐANG CHỌN
  int tabDangChon = 0;

  // 3. CONTROLLER TÌM KIẾM
  final timKiemController = TextEditingController();

  // 4. DANH SÁCH CÁC TAB
  final List<String> danhSachTab = [
    'Tất cả',
    'Của tôi',
    'Được giao',
    'Được chia sẻ',
  ];

  // 5. DANH SÁCH CÔNG VIỆC TỪ MONGODB
  List<dynamic> danhSachCongViec = [];

  // 6. TRẠNG THÁI TẢI DỮ LIỆU
  bool dangTai = false;
  String? loiTaiDuLieu;

  @override
  void initState() {
    super.initState();

    // Tự động tải công việc khi mở màn hình
    taiDanhSachCongViec();
  }

  @override
  void dispose() {
    timKiemController.dispose();
    super.dispose();
  }

  // 7. LẤY CÔNG VIỆC TỪ MONGODB
  Future<void> taiDanhSachCongViec() async {
    if (!mounted) return;

    setState(() {
      dangTai = true;
      loiTaiDuLieu = null;
    });

    try {
      // Gọi API GET /api/tasks
      final ketQua = await TaskService.getTasks(
        widget.token,
      );

      if (!mounted) return;

      setState(() {
        danhSachCongViec = ketQua;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        loiTaiDuLieu =
            e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          dangTai = false;
        });
      }
    }
  }

  // 8. MỞ MÀN HÌNH TẠO CÔNG VIỆC
  Future<void> moTaoCongViec() async {
    final ketQua = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => TaskCreateScreen(
          token: widget.token,
        ),
      ),
    );

    if (!mounted) return;

    // Nếu tạo thành công thì tải lại danh sách
    if (ketQua == true) {
      await taiDanhSachCongViec();

      if (!mounted) return;

      if (loiTaiDuLieu == null) {
        thongBao('Tạo công việc thành công!');
      }
    }
  }

  // 9. HIỂN THỊ THÔNG BÁO
  void thongBao(String noiDung) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(noiDung),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // 10. LỌC DANH SÁCH THEO TÊN CÔNG VIỆC
  List<dynamic> locCongViec() {
    final tuKhoa = timKiemController.text
        .trim()
        .toLowerCase();

    return danhSachCongViec.where((congViec) {
      final ten = (congViec['title'] ?? '')
          .toString()
          .toLowerCase();

      return ten.contains(tuKhoa);
    }).toList();
  }

  // 11. ĐỊNH DẠNG NGÀY
  String hienThiNgay(dynamic ngay) {
    if (ngay == null) return 'Chưa có hạn';

    final date = DateTime.tryParse(ngay.toString());

    if (date == null) return 'Không hợp lệ';

    final localDate = date.toLocal();

    return '${localDate.day.toString().padLeft(2, '0')}/'
        '${localDate.month.toString().padLeft(2, '0')}/'
        '${localDate.year}';
  }

  // 12. MÀU CỦA MỨC ĐỘ ƯU TIÊN
  Color mauUuTien(String mucUuTien) {
    switch (mucUuTien) {
      case 'Cao':
        return Colors.red;
      case 'Trung bình':
        return Colors.orange;
      case 'Thấp':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  // 13. HIỂN THỊ MỘT CÔNG VIỆC
  Widget hienThiCongViec(dynamic congViec) {
    final ten = congViec['title']?.toString() ?? '';
    final moTa = congViec['description']?.toString() ?? '';

    final uuTien =
        congViec['priority']?.toString() ?? 'Trung bình';

    final trangThai =
        congViec['status']?.toString() ?? 'Chưa thực hiện';

    final hanHoanThanh = hienThiNgay(
      congViec['dueDate'],
    );

    return Card(
      color: Colors.white,
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tên công việc
            Text(
              ten,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),

            if (moTa.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                moTa,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.grey.shade700,
                ),
              ),
            ],

            const SizedBox(height: 12),

            // Mức ưu tiên
            Row(
              children: [
                Icon(
                  Icons.flag,
                  color: mauUuTien(uuTien),
                  size: 18,
                ),
                const SizedBox(width: 6),
                Text(
                  'Ưu tiên: $uuTien',
                  style: TextStyle(
                    color: mauUuTien(uuTien),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Trạng thái
            Row(
              children: [
                const Icon(
                  Icons.pending_actions,
                  size: 18,
                  color: mauTim,
                ),
                const SizedBox(width: 6),
                Text('Trạng thái: $trangThai'),
              ],
            ),

            const SizedBox(height: 8),

            // Hạn hoàn thành
            Row(
              children: [
                const Icon(
                  Icons.calendar_today,
                  size: 18,
                  color: Colors.grey,
                ),
                const SizedBox(width: 6),
                Text('Hạn hoàn thành: $hanHoanThanh'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 14. GIAO DIỆN DANH SÁCH CÔNG VIỆC
  @override
  Widget build(BuildContext context) {
    final danhSachHienThi = locCongViec();

    return Scaffold(
      backgroundColor: const Color(0xFFFAF8FF),

      // THANH TIÊU ĐỀ
      appBar: AppBar(
        title: const Text('Danh sách công việc'),
        centerTitle: true,
        backgroundColor: mauTim,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: taiDanhSachCongViec,
          ),
        ],
      ),

      body: Column(
        children: [
          // 15. CÁC TAB DANH SÁCH
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

          // 16. Ô TÌM KIẾM
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

                // NÚT BỘ LỌC
                suffixIcon: IconButton(
                  icon: const Icon(Icons.filter_list),
                  onPressed: () {
                    thongBao(
                      'Bộ lọc sẽ được bổ sung ở bước tiếp theo',
                    );
                  },
                ),

                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          // 17. KHU VỰC DANH SÁCH
          Expanded(
            child: dangTai
            // Đang tải dữ liệu
                ? const Center(
              child: CircularProgressIndicator(
                color: mauTim,
              ),
            )

            // Có lỗi API
                : loiTaiDuLieu != null
                ? Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 45,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      loiTaiDuLieu!,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: taiDanhSachCongViec,
                      child: const Text('Thử lại'),
                    ),
                  ],
                ),
              ),
            )

            // Danh sách trống
                : danhSachHienThi.isEmpty
                ? const Center(
              child: Text(
                'Chưa có công việc nào.\n'
                    'Nhấn + để tạo công việc mới.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
            )

            // Hiển thị công việc từ MongoDB
                : RefreshIndicator(
              onRefresh: taiDanhSachCongViec,
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: danhSachHienThi.length,
                itemBuilder: (context, index) {
                  return hienThiCongViec(
                    danhSachHienThi[index],
                  );
                },
              ),
            ),
          ),
        ],
      ),

      // 18. NÚT + TẠO CÔNG VIỆC
      floatingActionButton: FloatingActionButton(
        backgroundColor: mauTim,
        foregroundColor: Colors.white,
        onPressed: moTaoCongViec,
        child: const Icon(Icons.add),
      ),
    );
  }
}
