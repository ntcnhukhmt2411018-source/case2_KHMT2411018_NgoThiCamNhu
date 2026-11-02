
import 'package:flutter/material.dart';

// Các màn hình
import 'task_create_screen.dart';
import 'task_detail_screen.dart';

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

  // 4. CÁC TAB
  final List<String> danhSachTab = [
    'Tất cả',
    'Của tôi',
    'Được giao',
    'Được chia sẻ',
  ];

  // 5. DANH SÁCH TỪ MONGODB
  List<dynamic> danhSachCongViec = [];

  // 6. TRẠNG THÁI TẢI
  bool dangTai = false;
  String? loiTaiDuLieu;

  @override
  void initState() {
    super.initState();
    taiDanhSachCongViec();
  }

  @override
  void dispose() {
    timKiemController.dispose();
    super.dispose();
  }

  // 7. LẤY DANH SÁCH TỪ MONGODB
  Future<void> taiDanhSachCongViec() async {
    if (!mounted) return;

    setState(() {
      dangTai = true;
      loiTaiDuLieu = null;
    });

    try {
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

    if (ketQua == true) {
      await taiDanhSachCongViec();

      if (!mounted) return;

      if (loiTaiDuLieu == null) {
        thongBao('Tạo công việc thành công!');
      }
    }
  }

  // 9. MỞ MÀN HÌNH CHI TIẾT CÔNG VIỆC
  Future<void> moChiTietCongViec(dynamic congViec) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TaskDetailScreen(
          // Truyền token để chỉnh sửa công việc
          token: widget.token,

          // Truyền dữ liệu công việc
          task: Map<String, dynamic>.from(congViec),
        ),
      ),
    );

    // Tải lại danh sách sau khi quay về
    if (!mounted) return;

    await taiDanhSachCongViec();
  }

  // 10. HIỂN THỊ THÔNG BÁO
  void thongBao(String noiDung) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(noiDung),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // 11. TÌM KIẾM THEO TÊN CÔNG VIỆC
  List<dynamic> locCongViec() {
    final tuKhoa =
    timKiemController.text.trim().toLowerCase();

    return danhSachCongViec.where((congViec) {
      final ten = (congViec['title'] ?? '')
          .toString()
          .toLowerCase();

      return ten.contains(tuKhoa);
    }).toList();
  }

  // 12. ĐỊNH DẠNG NGÀY
  String hienThiNgay(dynamic ngay) {
    if (ngay == null) return 'Chưa có hạn';

    final date = DateTime.tryParse(ngay.toString());

    if (date == null) return 'Không hợp lệ';

    final localDate = date.toLocal();

    return '${localDate.day.toString().padLeft(2, '0')}/'
        '${localDate.month.toString().padLeft(2, '0')}/'
        '${localDate.year}';
  }

  // 13. MÀU CỦA MỨC ĐỘ ƯU TIÊN
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

  // 14. HIỂN THỊ MỘT CÔNG VIỆC
  Widget hienThiCongViec(dynamic congViec) {
    final ten =
        congViec['title']?.toString() ?? '';

    final moTa =
        congViec['description']?.toString() ?? '';

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

      // Nhấn để xem chi tiết
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          moChiTietCongViec(congViec);
        },

        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // TÊN CÔNG VIỆC
              Row(
                children: [
                  Expanded(
                    child: Text(
                      ten,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right,
                    color: Colors.grey,
                  ),
                ],
              ),

              // MÔ TẢ
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

              // MỨC ƯU TIÊN
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

              // TRẠNG THÁI
              Row(
                children: [
                  const Icon(
                    Icons.pending_actions,
                    size: 18,
                    color: mauTim,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Trạng thái: $trangThai',
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // HẠN HOÀN THÀNH
              Row(
                children: [
                  const Icon(
                    Icons.calendar_today,
                    size: 18,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Hạn hoàn thành: $hanHoanThanh',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 15. GIAO DIỆN DANH SÁCH
  @override
  Widget build(BuildContext context) {
    final danhSachHienThi = locCongViec();

    return Scaffold(
      backgroundColor: const Color(0xFFFAF8FF),

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
          // 16. CÁC TAB
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

          // 17. Ô TÌM KIẾM
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

          // 18. KHU VỰC HIỂN THỊ DANH SÁCH
          Expanded(
            child: dangTai
                ? const Center(
              child: CircularProgressIndicator(
                color: mauTim,
              ),
            )
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

      // 19. NÚT TẠO CÔNG VIỆC
      floatingActionButton: FloatingActionButton(
        backgroundColor: mauTim,
        foregroundColor: Colors.white,
        onPressed: moTaoCongViec,
        child: const Icon(Icons.add),
      ),
    );
  }
}
