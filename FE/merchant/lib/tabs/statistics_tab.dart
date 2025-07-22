// lib/tabs/statistics_tab.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:merchant/screens/comment_reply_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';

// === TAO ĐÃ CẬP NHẬT CÁC IMPORT NÀY CHO ĐÚNG VỚI FILE CỦA MÀY ===
import '../services/merchant_services.dart';
import '../services/snackplace_services.dart';
import '../config/dio_customize.dart';
import '../constants/app_colors.dart'; // Dùng file màu của mày
import '../constants/app_fonts.dart';   // Dùng file font của mày

// Mày sẽ cần tạo file này để chứa màn hình trả lời bình luận
// import '../screens/comment_reply_screen.dart';


// === CÁC DATA MODEL (GIỮ NGUYÊN) ===
class SnackPlaceStats {
  final double averageRating;
  final int numOfComments;
  final double recommendPercent;
  final int numOfClicks;

  SnackPlaceStats({
    required this.averageRating,
    required this.numOfComments,
    required this.recommendPercent,
    required this.numOfClicks,
  });

  factory SnackPlaceStats.fromJson(Map<String, dynamic> json) {
    return SnackPlaceStats(
      averageRating: (json['averageRating'] as num).toDouble(),
      numOfComments: json['numOfComments'] as int,
      recommendPercent: (json['recommendPercent'] as num).toDouble(),
      numOfClicks: json['numOfClicks'] as int,
    );
  }
}

class ChartDayData {
  final String day;
  final int totalClicks;

  ChartDayData({required this.day, required this.totalClicks});
}

class ApiClickDay {
    final String day;
    final int totalClicks;
    final List<dynamic> dateGroup;

    ApiClickDay({required this.day, required this.totalClicks, required this.dateGroup});

    factory ApiClickDay.fromJson(Map<String, dynamic> json) {
        return ApiClickDay(
            day: json['day'],
            totalClicks: json['totalClicks'],
            dateGroup: json['dateGroup'],
        );
    }
}


// === WIDGET CHÍNH ===
class StatisticsTab extends StatefulWidget {
  const StatisticsTab({super.key});

  @override
  State<StatisticsTab> createState() => _StatisticsTabState();
}

class _StatisticsTabState extends State<StatisticsTab> {
  // === CÁC BIẾN TRẠNG THÁI (GIỮ NGUYÊN) ===
  bool _isLoading = true;
  String? _error;
  SnackPlaceStats? _stats;
  List<ChartDayData>? _clickData;
  bool _hasBasicPackage = false;
  String? _snackPlaceId;

  final Map<String, String> _vietnameseDays = {
    'Sunday': 'Chủ nhật', 'Monday': 'Thứ 2', 'Tuesday': 'Thứ 3',
    'Wednesday': 'Thứ 4', 'Thursday': 'Thứ 5', 'Friday': 'Thứ 6', 'Saturday': 'Thứ 7',
  };

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  // === HÀM LẤY DỮ LIỆU (LOGIC GIỮ NGUYÊN) ===
  Future<void> _fetchData() async {
    if (mounted) {
      setState(() {
        _error = null;
        if (_stats == null) _isLoading = true;
      });
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final packageNamesJson = prefs.getString('packageNames');
      if (packageNamesJson != null) {
        final packageNames = List<String>.from(jsonDecode(packageNamesJson));
        print('DEBUG: packageNames = $packageNames');
        _hasBasicPackage = packageNames.contains("Gói Cơ Bản");
      }

      // Gọi API từ merchant_services.dart của mày
      final snackplaceResponse = await MerchantServices.checkCreatedSnackplaceApi();
      final currentSnackPlaceId = snackplaceResponse.data?['snackPlaceId'] as String?;

      if (currentSnackPlaceId == null) {
        throw Exception("Không tìm thấy thông tin quán ăn của bạn.");
      }
      _snackPlaceId = currentSnackPlaceId;

      final today = DateTime.now();
      final endDate = DateFormat('yyyy-MM-dd').format(today);
      final startDate = DateFormat('yyyy-MM-dd').format(today.subtract(const Duration(days: 5)));

      final results = await Future.wait([
        SnackPlaceServices.getSnackPlaceStatsApi(id: currentSnackPlaceId),
        SnackPlaceServices.getSnackPlaceClicksApi(startDate: startDate, endDate: endDate),
      ]);

      final statsResponse = results[0] as ApiResponse;
      final clicksResponse = results[1] as ApiResponse;

      if (statsResponse.status != 200 || clicksResponse.status != 200) {
          throw Exception("Lấy dữ liệu thất bại. Vui lòng thử lại.");
      }

      final newStats = SnackPlaceStats.fromJson(statsResponse.data);

      final clicksByApi = (clicksResponse.data['clicksByDayOfWeek'] as List)
          .map((item) => ApiClickDay.fromJson(item))
          .toList();

      final clicksByDate = <String, int>{};
      for (var dayData in clicksByApi) {
          if (dayData.dateGroup.isNotEmpty) {
              final date = DateTime.parse(dayData.dateGroup[0]['clickedAt']);
              final dateString = DateFormat('yyyy-MM-dd').format(date);
              clicksByDate[dateString] = dayData.totalClicks;
          }
      }

      final last6Days = List.generate(6, (i) => DateTime.now().subtract(Duration(days: i))).reversed.toList();

      final formattedClickData = last6Days.map((date) {
          final dateString = DateFormat('yyyy-MM-dd').format(date);
          final dayName = DateFormat('EEEE').format(date);
          return ChartDayData(
              day: _vietnameseDays[dayName] ?? 'N/A',
              totalClicks: clicksByDate[dateString] ?? 0,
          );
      }).toList();

      if (mounted) {
        setState(() {
          _stats = newStats;
          _clickData = formattedClickData;
        });
      }

    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceAll('Exception: ', '');
          _stats = null;
          _clickData = null;
          _snackPlaceId = null;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // === HÀM XỬ LÝ NÚT BẤM (ĐÃ SỬA LẠI NAVIGATION) ===
  void _handleReplyPress() {
    // 3. KIỂM TRA KẾT QUẢ ĐÃ LƯU
    if (_hasBasicPackage) {
      // Nếu có gói, chuyển màn hình
      Navigator.push(
        context,
        MaterialPageRoute(
          // Màn hình này tao đã code cho mày ở câu trả lời trước
          builder: (context) => const CommentReplyScreen(),
        ),
      );
    } else {
      // Nếu không có gói, hiện thông báo
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Yêu cầu nâng cấp"),
          content: const Text("Tính năng này chỉ dành cho tài khoản đã đăng ký Gói Cơ Bản."),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Đã hiểu"),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Dùng font và màu của mày
        title: Text('Báo cáo số liệu', style: AppFonts.baloo2Bold.copyWith(color: AppColors.lightPrimaryText, fontSize: 24)),
        centerTitle: true,
        backgroundColor: AppColors.lightBackground,
        elevation: 0,
      ),
      backgroundColor: AppColors.lightBackground,
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.lightPrimaryText));
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_error!, style: AppFonts.comfortaaRegular.copyWith(color: AppColors.lightError, fontSize: 16), textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _fetchData,
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.lightPrimaryText),
                child: Text('Thử lại', style: AppFonts.comfortaaMedium.copyWith(color: AppColors.lightWhiteText)),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchData,
      color: AppColors.lightPrimaryText,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Số liệu tổng quan', style: AppFonts.baloo2Bold.copyWith(fontSize: 18, color: AppColors.lightBlackText)),
            const SizedBox(height: 12),
            _buildStatsGrid(),
            const SizedBox(height: 24),
            Text('Lượt click theo ngày', style: AppFonts.baloo2Bold.copyWith(fontSize: 18, color: AppColors.lightBlackText)),
            const SizedBox(height: 16),
            _buildBarChart(),
            const SizedBox(height: 24),
            _buildReplyButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid() {
    if (_stats == null) return const SizedBox.shrink();

    final cardData = [
      {'id': 'rating', 'value': '${_stats!.averageRating.toStringAsFixed(1)}/5', 'label': 'Đánh giá sao', 'icon': Icons.star},
      {'id': 'reviews', 'value': _stats!.numOfComments.toString(), 'label': 'Lượt đánh giá', 'icon': Icons.rate_review},
      {'id': 'recommend', 'value': '${_stats!.recommendPercent.toStringAsFixed(0)}%', 'label': 'Đề xuất', 'icon': Icons.lightbulb},
      {'id': 'clicks', 'value': _stats!.numOfClicks.toString(), 'label': 'Lượt truy cập', 'icon': Icons.visibility},
    ];

    return GridView.builder(

      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: cardData.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.4,
      ),
      itemBuilder: (context, index) {
        final item = cardData[index];
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.lightGrayBackground.withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Row(
                children: [
                  Icon(item['icon'] as IconData, size: 24, color: AppColors.lightIcon),
                  const SizedBox(width: 8),
                  Expanded(child: Text(item['label'] as String, style: AppFonts.comfortaaRegular.copyWith(color: AppColors.lightBlackText, fontSize: 16),)),
                ],
              ),
              Text(
                item['value'] as String,
                style: AppFonts.baloo2Bold.copyWith(color: AppColors.lightPrimaryText, fontSize: 36),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBarChart() {
      if (_clickData == null || _clickData!.isEmpty || _clickData!.every((d) => d.totalClicks == 0)) {
          return Container(
              height: 250,
              alignment: Alignment.center,
              child: Text("Không có dữ liệu để hiển thị", style: AppFonts.comfortaaRegular),
          );
      }

      final maxClicks = _clickData!.map((d) => d.totalClicks).reduce((a, b) => a > b ? a : b).toDouble();
      final yAxisMax = (maxClicks * 1.2).ceil().toDouble();
      final yAxisInterval = (yAxisMax > 5) ? (yAxisMax / 5).ceil().toDouble() : 1.0;

      return SizedBox(
          height: 250,
          child: BarChart(
              BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: yAxisMax,
                  barTouchData: BarTouchData(
                      touchTooltipData: BarTouchTooltipData(
                          getTooltipColor: (_) => AppColors.lightBlackText,
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                              return BarTooltipItem(
                                  '${_clickData![group.x.toInt()].day}\n',
                                  AppFonts.comfortaaMedium.copyWith(color: AppColors.lightWhiteText, fontSize: 14),
                                  children: <TextSpan>[
                                      TextSpan(
                                          text: rod.toY.round().toString(),
                                          style: AppFonts.baloo2Bold.copyWith(color: AppColors.lightWhiteText, fontSize: 14),
                                      ),
                                  ],
                              );
                          },
                      ),
                  ),
                  titlesData: FlTitlesData(
                      show: true,
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (double value, TitleMeta meta) {
                                  final index = value.toInt();
                                  if (index >= 0 && index < _clickData!.length) {
                                      return SideTitleWidget(

                                          meta: meta,
                                          space: 4,
                                          child: Text(_clickData![index].day, style: AppFonts.comfortaaRegular.copyWith(fontSize: 12)),
                                      );
                                  }
                                  return const Text('');
                              },
                              reservedSize: 30,
                          ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 28,
                            interval: yAxisInterval,
                            getTitlesWidget: (value, meta) {
                                if (value == 0 || value > maxClicks) return const Text('');
                                return Text(value.toInt().toString(), style: AppFonts.comfortaaRegular.copyWith(fontSize: 12, color: AppColors.lightBlackText), textAlign: TextAlign.left);
                            },
                        ),
                      ),
                  ),
                  borderData: FlBorderData(show: false),
                  gridData: const FlGridData(show: false),
                  barGroups: _clickData!.asMap().entries.map((entry) {
                      final index = entry.key;
                      final data = entry.value;
                      return BarChartGroupData(
                          x: index,
                          barRods: [
                              BarChartRodData(
                                  toY: data.totalClicks.toDouble(),
                                  color: AppColors.lightPrimaryText,
                                  width: 22,
                                  borderRadius: const BorderRadius.all(Radius.circular(4)),
                              ),
                          ],
                      );
                  }).toList(),
              ),
          ),
      );
  }

  Widget _buildReplyButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _handleReplyPress,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.lightPrimaryText,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          'Trả lời bình luận của khách hàng',
          style: AppFonts.comfortaaMedium.copyWith(color: AppColors.lightWhiteText, fontSize: 16),
        ),
      ),
    );
  }
}