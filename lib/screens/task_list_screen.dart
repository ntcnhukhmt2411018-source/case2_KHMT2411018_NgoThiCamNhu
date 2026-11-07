
import 'dart:convert';
import 'package:flutter/material.dart';

import 'task_create_screen.dart';
import 'task_detail_screen.dart';
import '../services/task_service.dart';

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

  List<dynamic> danhSachCongViec = [];
  bool dangTai = false;
  String? loiTaiDuLieu;
  String? userId;

  final timKiemController = TextEditingController();

  int tabDangChon = 0;

  final danhSachTab = [
    'Tất cả',
    'Của tôi',
    'Được giao',
    'Được chia sẻ',
  ];

  String locTrangThai = 'Tất cả';
  String locUuTien = 'Tất cả';
  String sapXep = 'Mới tạo nhất';

  final danhSachTrangThai = [
    'Tất cả',
    'Chưa thực hiện',
    'Đang thực hiện',
    'Đã hoàn thành',
  ];

  final danhSachUuTien = [
    'Tất cả',
    'Thấp',
    'Trung bình',
    'Cao',
  ];

  final danhSachSapXep = [
    'Mới tạo nhất',
    'Cũ nhất',
    'Hạn hoàn thành gần nhất',
    'Ưu tiên cao nhất',
  ];

  @override
  void initState() {
    super.initState();
    userId = layUserIdTuToken(widget.token);
    taiDanhSachCongViec();
  }

  @override
  void dispose() {
    timKiemController.dispose();
    super.dispose();
  }

  // 1. LẤY ID NGƯỜI ĐĂNG NHẬP
  String? layUserIdTuToken(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;

      final payload = utf8.decode(
        base64Url.decode(base64Url.normalize(parts[1])),
      );

      final data = jsonDecode(payload);
      if (data is! Map) return null;

      return (data['id'] ?? data['userId'])?.toString();
    } catch (error) {
      debugPrint('Lỗi đọc token: $error');
      return null;
    }
  }

  // 2. LẤY ID TỪ MONGODB
  String layId(dynamic giaTri) {
    if (giaTri == null) return '';

    if (giaTri is Map) {
      return (giaTri['_id'] ?? giaTri['id'] ?? '').toString();
    }

    return giaTri.toString();
  }

  // 3. KIỂM TRA NGƯỜI DÙNG TRONG DANH SÁCH
  bool coTrongDanhSach(dynamic danhSach, String id) {
    if (danhSach is! List) return false;

    return danhSach.any(
          (nguoiDung) => layId(nguoiDung) == id,
    );
  }

  // 4. TẢI DANH SÁCH CÔNG VIỆC
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
    } catch (error) {
      if (!mounted) return;

      setState(() {
        loiTaiDuLieu = error
            .toString()
            .replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() => dangTai = false);
      }
    }
  }

  // 5. TẠO CÔNG VIỆC
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

  // 6. XEM CHI TIẾT CÔNG VIỆC
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

    await taiDanhSachCongViec();

    if (!mounted) return;

    if (ketQua == true && loiTaiDuLieu == null) {
      thongBao('Xóa công việc thành công!');
    }
  }

  // 7. HIỂN THỊ THÔNG BÁO
  void thongBao(String noiDung) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(noiDung),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // 8. XỬ LÝ NGÀY
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

  // 9. GIÁ TRỊ MỨC ĐỘ ƯU TIÊN
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

  // 10. PHÂN LOẠI CÔNG VIỆC THEO VAI TRÒ
  bool dungTab(dynamic congViec) {
    if (tabDangChon == 0) return true;

    final idHienTai = userId;

    if (idHienTai == null || idHienTai.isEmpty) {
      return false;
    }

    final nguoiTao = layId(congViec['createdBy']);
    final nguoiPhuTrach = layId(congViec['assignedTo']);

    final nguoiDuocGiao = congViec['assignedUsers'];
    final nguoiDuocChiaSe = congViec['sharedWith'];

    final laNguoiPhuTrach =
        nguoiPhuTrach == idHienTai;

    final laNguoiDuocGiao = coTrongDanhSach(
      nguoiDuocGiao,
      idHienTai,
    );

    final laNguoiDuocChiaSe = coTrongDanhSach(
      nguoiDuocChiaSe,
      idHienTai,
    );

    switch (tabDangChon) {
      case 1:
        return nguoiTao == idHienTai;

      case 2:
        return nguoiTao != idHienTai &&
            (laNguoiPhuTrach || laNguoiDuocGiao);

      case 3:
        return nguoiTao != idHienTai &&
            laNguoiDuocChiaSe;

      default:
        return true;
    }
  }

  // 11. XÁC ĐỊNH VAI TRÒ TRONG CÔNG VIỆC
  String vaiTroTrongCongViec(dynamic congViec) {
    final id = userId;
    if (id == null || id.isEmpty) return '';

    if (layId(congViec['createdBy']) == id) {
      return 'Người tạo';
    }

    if (layId(congViec['assignedTo']) == id) {
      return 'Người phụ trách chính';
    }

    if (coTrongDanhSach(congViec['assignedUsers'], id)) {
      return 'Người được giao';
    }

    if (coTrongDanhSach(congViec['sharedWith'], id)) {
      return 'Người được chia sẻ';
    }

    return '';
  }

  // 12. TÌM KIẾM, LỌC VÀ SẮP XẾP
  List<dynamic> locCongViec() {
    final tuKhoa = timKiemController.text
        .trim()
        .toLowerCase();

    final ketQua = danhSachCongViec.where((congViec) {
      final ten = (congViec['title'] ?? '')
          .toString()
          .toLowerCase();

      final trangThai = (congViec['status'] ??
          'Chưa thực hiện')
          .toString();

      final uuTien = (congViec['priority'] ??
          'Trung bình')
          .toString();

      final hopTab = dungTab(congViec);
      final dungTen = ten.contains(tuKhoa);

      final dungTrangThai =
          locTrangThai == 'Tất cả' ||
              trangThai == locTrangThai;

      final dungUuTien =
          locUuTien == 'Tất cả' ||
              uuTien == locUuTien;

      return hopTab &&
          dungTen &&
          dungTrangThai &&
          dungUuTien;
    }).toList();

    ketQua.sort((a, b) {
      if (sapXep == 'Ưu tiên cao nhất') {
        final aUuTien = giaTriUuTien(
          (a['priority'] ?? '').toString(),
        );

        final bUuTien = giaTriUuTien(
          (b['priority'] ?? '').toString(),
        );

        return bUuTien.compareTo(aUuTien);
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

      return ngayB.compareTo(ngayA);
    });

    return ketQua;
  }

  // 13. C.7 - THỐNG KÊ TIẾN ĐỘ THEO VAI TRÒ
  Widget thongKeTienDo() {
    final congViecTheoVaiTro = danhSachCongViec
        .where((congViec) => dungTab(congViec))
        .toList();

    final tong = congViecTheoVaiTro.length;

    final chuaLam = congViecTheoVaiTro.where(
          (congViec) =>
      (congViec['status'] ?? 'Chưa thực hiện') ==
          'Chưa thực hiện',
    ).length;

    final dangLam = congViecTheoVaiTro.where(
          (congViec) =>
      congViec['status'] == 'Đang thực hiện',
    ).length;

    final hoanThanh = congViecTheoVaiTro.where(
          (congViec) =>
      congViec['status'] == 'Đã hoàn thành',
    ).length;

    final tiLe = tong == 0 ? 0.0 : hoanThanh / tong;

    Widget oThongKe(
        String nhan,
        int soLuong,
        Color mau,
        ) {
      return Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(
            vertical: 10,
            horizontal: 5,
          ),
          decoration: BoxDecoration(
            color: mau.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              Text(
                '$soLuong',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: mau,
                ),
              ),
              Text(
                nhan,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 11),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 4,
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Theo dõi tiến độ công việc',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 6),

            Text(
              'Vai trò: ${danhSachTab[tabDangChon]}',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                oThongKe('Tổng', tong, mauTim),
                const SizedBox(width: 6),
                oThongKe('Chưa làm', chuaLam, Colors.grey),
                const SizedBox(width: 6),
                oThongKe('Đang làm', dangLam, Colors.orange),
                const SizedBox(width: 6),
                oThongKe('Hoàn thành', hoanThanh, Colors.green),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Tỷ lệ hoàn thành',
                  style: TextStyle(fontSize: 13),
                ),
                Text(
                  '${(tiLe * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(
                    color: mauTim,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 6),

            LinearProgressIndicator(
              value: tiLe,
              minHeight: 9,
              borderRadius: BorderRadius.circular(8),
              backgroundColor: Colors.grey.shade200,
              color: Colors.green,
            ),
          ],
        ),
      ),
    );
  }

  // 14. XÓA BỘ LỌC
  void xoaBoLoc() {
    setState(() {
      locTrangThai = 'Tất cả';
      locUuTien = 'Tất cả';
      sapXep = 'Mới tạo nhất';
    });
  }

  // 15. HỘP THOẠI LỌC VÀ SẮP XẾP
  Future<void> moBoLoc() async {
    String trangThaiTam = locTrangThai;
    String uuTienTam = locUuTien;
    String sapXepTam = sapXep;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Lọc và sắp xếp'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Trạng thái'),
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
                    const Text('Mức độ ưu tiên'),
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
                    const Text('Sắp xếp theo'),
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

  // 16. MÀU MỨC ĐỘ ƯU TIÊN
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

  // 17. HIỂN THỊ MỘT CÔNG VIỆC
  Widget hienThiCongViec(dynamic congViec) {
    final ten = congViec['title']?.toString() ?? '';
    final moTa = congViec['description']?.toString() ?? '';

    final uuTien = congViec['priority']?.toString() ??
        'Trung bình';

    final trangThai = congViec['status']?.toString() ??
        'Chưa thực hiện';

    final hanHoanThanh = hienThiNgay(
      congViec['dueDate'],
    );

    final vaiTro = vaiTroTrongCongViec(congViec);

    return Card(
      color: Colors.white,
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => moChiTietCongViec(congViec),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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

              if (vaiTro.isNotEmpty) ...[
                const SizedBox(height: 6),
                Chip(
                  label: Text(vaiTro),
                  visualDensity: VisualDensity.compact,
                  backgroundColor: const Color(0xFFEDE9FA),
                  labelStyle: const TextStyle(
                    color: mauTim,
                    fontSize: 12,
                  ),
                ),
              ],

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

  // 18. GIAO DIỆN DANH SÁCH
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
          // 4 TAB PHÂN LOẠI THEO VAI TRÒ
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

          // C.7 - THỐNG KÊ TIẾN ĐỘ
          if (!dangTai &&
              loiTaiDuLieu == null &&
              userId != null)
            thongKeTienDo(),

          // TÌM KIẾM
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: timKiemController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Tìm kiếm công việc...',
                prefixIcon: const Icon(Icons.search),
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

          if (dangLoc)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.tune,
                    color: mauTim,
                    size: 18,
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

          // DANH SÁCH CÔNG VIỆC
          Expanded(
            child: dangTai
                ? const Center(
              child: CircularProgressIndicator(
                color: mauTim,
              ),
            )
                : loiTaiDuLieu != null
                ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Colors.red,
                    size: 45,
                  ),
                  const SizedBox(height: 12),
                  Text(loiTaiDuLieu!),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: taiDanhSachCongViec,
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            )
                : userId == null && tabDangChon != 0
                ? const Center(
              child: Text(
                'Không xác định được tài khoản đăng nhập.',
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
      floatingActionButton: FloatingActionButton(
        backgroundColor: mauTim,
        foregroundColor: Colors.white,
        onPressed: moTaoCongViec,
        child: const Icon(Icons.add),
      ),
    );
  }
}
