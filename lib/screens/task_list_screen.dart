
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
  static const Color mauTim = Color(0xFF6554C0);

  // 1. DANH SÁCH CÔNG VIỆC
  List<dynamic> danhSachCongViec = [];
  bool dangTai = false;
  String? loiTaiDuLieu;

  // 2. TÌM KIẾM
  final timKiemController = TextEditingController();

  // 3. CÁC TAB (SẼ HOÀN THIỆN KHI LÀM GIAO VIỆC)
  int tabDangChon = 0;

  final List<String> danhSachTab = [
    'Tất cả',
    'Của tôi',
    'Được giao',
    'Được chia sẻ',
  ];

  // 4. GIÁ TRỊ BỘ LỌC
  String locTrangThai = 'Tất cả';
  String locUuTien = 'Tất cả';
  String sapXep = 'Mới tạo nhất';

  final List<String> danhSachTrangThai = [
    'Tất cả',
    'Chưa thực hiện',
    'Đang thực hiện',
    'Đã hoàn thành',
  ];

  final List<String> danhSachUuTien = [
    'Tất cả',
    'Thấp',
    'Trung bình',
    'Cao',
  ];

  final List<String> danhSachSapXep = [
    'Mới tạo nhất',
    'Cũ nhất',
    'Hạn hoàn thành gần nhất',
    'Ưu tiên cao nhất',
  ];

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

  // 5. TẢI DANH SÁCH TỪ MONGODB
  Future<void> taiDanhSachCongViec() async {
    if (!mounted) return;

    setState(() {
      dangTai = true;
      loiTaiDuLieu = null;
    });

    try {
      final ketQua = await TaskService.getTasks(widget.token);

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

  // 6. MỞ MÀN HÌNH TẠO CÔNG VIỆC
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

  // 7. MỞ MÀN HÌNH CHI TIẾT
  Future<void> moChiTietCongViec(dynamic congViec) async {
    final ketQua = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => TaskDetailScreen(
          token: widget.token,
          task: Map<String, dynamic>.from(congViec),
        ),
      ),
    );

    if (!mounted) return;

    // Tải lại danh sách sau khi sửa hoặc xóa
    await taiDanhSachCongViec();

    if (!mounted) return;

    if (ketQua == true && loiTaiDuLieu == null) {
      thongBao('Xóa công việc thành công!');
    }
  }

  // 8. HIỂN THỊ THÔNG BÁO
  void thongBao(String noiDung) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(noiDung),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // 9. CHUYỂN NGÀY THÁNG
  DateTime? chuyenNgay(dynamic ngay) {
    if (ngay == null) return null;

    return DateTime.tryParse(ngay.toString());
  }

  String hienThiNgay(dynamic ngay) {
    final date = chuyenNgay(ngay);

    if (date == null) return 'Chưa có hạn';

    final localDate = date.toLocal();

    return '${localDate.day.toString().padLeft(2, '0')}/'
        '${localDate.month.toString().padLeft(2, '0')}/'
        '${localDate.year}';
  }

  // 10. CHUYỂN MỨC ƯU TIÊN THÀNH SỐ
  int giaTriUuTien(String uuTien) {
    switch (uuTien) {
      case 'Cao':
        return 3;
      case 'Trung bình':
        return 2;
      case 'Thấp':
        return 1;
      default:
        return 0;
    }
  }

  // 11. TÌM KIẾM, LỌC VÀ SẮP XẾP CÔNG VIỆC
  List<dynamic> locCongViec() {
    final tuKhoa =
    timKiemController.text.trim().toLowerCase();

    // Tạo danh sách mới để không thay đổi dữ liệu gốc
    final ketQua = danhSachCongViec.where((congViec) {
      final ten =
      (congViec['title'] ?? '').toString().toLowerCase();

      final trangThai =
      (congViec['status'] ?? 'Chưa thực hiện').toString();

      final uuTien =
      (congViec['priority'] ?? 'Trung bình').toString();

      // Lọc theo tên
      final dungTen = ten.contains(tuKhoa);

      // Lọc theo trạng thái
      final dungTrangThai =
          locTrangThai == 'Tất cả' ||
              trangThai == locTrangThai;

      // Lọc theo mức độ ưu tiên
      final dungUuTien =
          locUuTien == 'Tất cả' ||
              uuTien == locUuTien;

      return dungTen && dungTrangThai && dungUuTien;
    }).toList();

    // Sắp xếp danh sách
    ketQua.sort((a, b) {
      if (sapXep == 'Ưu tiên cao nhất') {
        final uuTienA =
        giaTriUuTien((a['priority'] ?? '').toString());

        final uuTienB =
        giaTriUuTien((b['priority'] ?? '').toString());

        return uuTienB.compareTo(uuTienA);
      }

      if (sapXep == 'Hạn hoàn thành gần nhất') {
        final ngayA = chuyenNgay(a['dueDate']);
        final ngayB = chuyenNgay(b['dueDate']);

        if (ngayA == null && ngayB == null) return 0;
        if (ngayA == null) return 1;
        if (ngayB == null) return -1;

        return ngayA.compareTo(ngayB);
      }

      final ngayA = chuyenNgay(a['createdAt']);
      final ngayB = chuyenNgay(b['createdAt']);

      if (ngayA == null && ngayB == null) return 0;
      if (ngayA == null) return 1;
      if (ngayB == null) return -1;

      if (sapXep == 'Cũ nhất') {
        return ngayA.compareTo(ngayB);
      }

      // Mặc định: mới tạo nhất
      return ngayB.compareTo(ngayA);
    });

    return ketQua;
  }

  // 12. XÓA BỘ LỌC
  void xoaBoLoc() {
    setState(() {
      locTrangThai = 'Tất cả';
      locUuTien = 'Tất cả';
      sapXep = 'Mới tạo nhất';
    });
  }

  // 13. HIỂN THỊ HỘP THOẠI LỌC VÀ SẮP XẾP
  Future<void> moBoLoc() async {
    // Giá trị tạm, chỉ áp dụng khi nhấn nút Áp dụng
    String trangThaiTam = locTrangThai;
    String uuTienTam = locUuTien;
    String sapXepTam = sapXep;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.filter_list, color: mauTim),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Lọc và sắp xếp',
                      style: TextStyle(fontSize: 20),
                    ),
                  ),
                ],
              ),

              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Lọc trạng thái
                    const Text(
                      'Trạng thái',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 8),

                    DropdownButtonFormField<String>(
                      key: ValueKey('status-$trangThaiTam'),
                      initialValue: trangThaiTam,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                      items: danhSachTrangThai.map((item) {
                        return DropdownMenuItem(
                          value: item,
                          child: Text(item),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() {
                            trangThaiTam = value;
                          });
                        }
                      },
                    ),

                    const SizedBox(height: 20),

                    // Lọc mức độ ưu tiên
                    const Text(
                      'Mức độ ưu tiên',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 8),

                    DropdownButtonFormField<String>(
                      key: ValueKey('priority-$uuTienTam'),
                      initialValue: uuTienTam,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                      items: danhSachUuTien.map((item) {
                        return DropdownMenuItem(
                          value: item,
                          child: Text(item),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() {
                            uuTienTam = value;
                          });
                        }
                      },
                    ),

                    const SizedBox(height: 20),

                    // Sắp xếp
                    const Text(
                      'Sắp xếp theo',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 8),

                    DropdownButtonFormField<String>(
                      key: ValueKey('sort-$sapXepTam'),
                      initialValue: sapXepTam,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                      items: danhSachSapXep.map((item) {
                        return DropdownMenuItem(
                          value: item,
                          child: Text(
                            item,
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() {
                            sapXepTam = value;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),

              actions: [
                TextButton(
                  onPressed: () {
                    xoaBoLoc();
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('Xóa lọc'),
                ),

                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: mauTim,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    setState(() {
                      locTrangThai = trangThaiTam;
                      locUuTien = uuTienTam;
                      sapXep = sapXepTam;
                    });

                    Navigator.pop(dialogContext);
                  },
                  child: const Text('Áp dụng'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // 14. MÀU CỦA MỨC ĐỘ ƯU TIÊN
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

  // 15. HIỂN THỊ MỘT CÔNG VIỆC
  Widget hienThiCongViec(dynamic congViec) {
    final ten = congViec['title']?.toString() ?? '';

    final moTa =
        congViec['description']?.toString() ?? '';

    final uuTien =
        congViec['priority']?.toString() ?? 'Trung bình';

    final trangThai =
        congViec['status']?.toString() ?? 'Chưa thực hiện';

    final hanHoanThanh =
    hienThiNgay(congViec['dueDate']);

    return Card(
      color: Colors.white,
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),

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
              // Tên công việc
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

              // Mô tả
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
                  Expanded(
                    child: Text(
                      'Trạng thái: $trangThai',
                    ),
                  ),
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

  // 16. GIAO DIỆN DANH SÁCH
  @override
  Widget build(BuildContext context) {
    final danhSachHienThi = locCongViec();

    final dangLoc =
        locTrangThai != 'Tất cả' ||
            locUuTien != 'Tất cả' ||
            sapXep != 'Mới tạo nhất';

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
          // Các tab hiện tại
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

          // Ô tìm kiếm và nút bộ lọc
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

                // Nhấn để mở bộ lọc
                suffixIcon: IconButton(
                  tooltip: 'Lọc và sắp xếp',
                  icon: Icon(
                    Icons.filter_list,
                    color: dangLoc ? mauTim : Colors.grey,
                  ),
                  onPressed: moBoLoc,
                ),

                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          // Thông tin bộ lọc đang áp dụng
          if (dangLoc)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.tune,
                    size: 18,
                    color: mauTim,
                  ),
                  const SizedBox(width: 6),
                  const Expanded(
                    child: Text(
                      'Đang áp dụng bộ lọc / sắp xếp',
                      style: TextStyle(
                        color: mauTim,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: xoaBoLoc,
                    child: const Text('Xóa lọc'),
                  ),
                ],
              ),
            ),

          // Số lượng kết quả
          if (!dangTai && loiTaiDuLieu == null)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 4,
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Tìm thấy ${danhSachHienThi.length} công việc',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 13,
                  ),
                ),
              ),
            ),

          // Danh sách công việc
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
                ? Center(
              child: Text(
                danhSachCongViec.isEmpty
                    ? 'Chưa có công việc nào.\n'
                    'Nhấn + để tạo công việc mới.'
                    : 'Không tìm thấy công việc phù hợp.',
                textAlign: TextAlign.center,
                style: const TextStyle(
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

      // Nút tạo công việc
      floatingActionButton: FloatingActionButton(
        backgroundColor: mauTim,
        foregroundColor: Colors.white,
        onPressed: moTaoCongViec,
        child: const Icon(Icons.add),
      ),
    );
  }
}
