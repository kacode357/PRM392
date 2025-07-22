import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:user/models/snack_place_model.dart';
import 'package:user/screens/snack_place_detail_screen.dart';
import 'package:user/services/snackplace_services.dart';
import 'package:user/widgets/home/snack_place_card.dart';

class SnackPlaceList extends StatefulWidget {
  final ScrollController scrollController;
  const SnackPlaceList({super.key, required this.scrollController});

  @override
  State<SnackPlaceList> createState() => _SnackPlaceListState();
}

class _SnackPlaceListState extends State<SnackPlaceList> {
  final List<SnackPlace> _snackPlaces = [];
  bool _isLoading = true;
  bool _hasMore = true;
  bool _isFetchingMore = false;
  int _pageNum = 1;
  final int _pageSize = 10;

  // Biến cờ để chống spam click ở UI
  bool _isProcessingClick = false;

  @override
  void initState() {
    super.initState();
    _fetchSnackPlaces(reset: true);
    widget.scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    widget.scrollController.removeListener(_onScroll);
    super.dispose();
  }

  void _onScroll() {
    if (widget.scrollController.position.pixels >= widget.scrollController.position.maxScrollExtent - 200 &&
        !_isFetchingMore &&
        _hasMore) {
      _fetchSnackPlaces();
    }
  }

  Future<void> _fetchSnackPlaces({bool reset = false}) async {
    if (_isFetchingMore || (!reset && !_hasMore)) return;

    setState(() {
      _isFetchingMore = true;
      if (reset) {
        _isLoading = true;
      }
    });

    if (reset) {
      _pageNum = 1;
      _snackPlaces.clear();
      _hasMore = true;
    }

    try {
      debugPrint('[SnackPlaceList] Fetching page: $_pageNum');

      final response = await SnackPlaceServices.searchSnackPlacesApi(
        pageNum: _pageNum,
        pageSize: _pageSize,
        searchKeyword: '',
        status: true,
      );

      if (response.status == 200 && response.data != null) {
        final List<dynamic> pageData = response.data['pageData'] ?? [];
        final List<SnackPlace> newData =
        pageData.map((json) => SnackPlace.fromJson(json)).toList();

        debugPrint('[SnackPlaceList] Fetched ${newData.length} items.');

        final bool hasMoreData = newData.length >= _pageSize;

        setState(() {
          _snackPlaces.addAll(newData);
          _hasMore = hasMoreData;
          if (newData.isNotEmpty) {
            _pageNum++;
          }
        });
      } else {
        debugPrint('[SnackPlaceList] API error: status ${response.status}');
        setState(() {
          _hasMore = false;
        });
      }
    } catch (e) {
      debugPrint('[SnackPlaceList] Exception fetching snack places: $e');
      setState(() {
        _hasMore = false;
      });
    } finally {
      setState(() {
        _isFetchingMore = false;
        _isLoading = false;
      });
    }
  }

  // HÀM MỚI: Dùng để gọi API trong nền
  Future<void> _recordClickInBackground(String snackPlaceId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');
      if (userId != null) {
        // Gọi API nhưng không cần đợi kết quả, và tự xử lý lỗi nếu có
        await SnackPlaceServices.recordSnackPlaceClickApi(
            userId: userId, snackPlaceId: snackPlaceId);
        debugPrint('[Background] Click recorded for $snackPlaceId');
      }
    } catch (e) {
      // Lỗi từ API sẽ chỉ được in ra ở đây và không ảnh hưởng đến UI
      debugPrint('[Background] API Error recording click: $e');
    }
  }

  // HÀM ĐƯỢC CẬP NHẬT: Chỉ tập trung vào việc chặn UI
  Future<void> _handleCardPress(String snackPlaceId) async {
    // 1. Chặn UI nếu đang trong quá trình xử lý một lần nhấn khác
    if (_isProcessingClick) return;

    // 2. Khóa UI lại
    _isProcessingClick = true;

    // 3. Điều hướng người dùng ngay lập tức
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SnackPlaceDetailScreen(snackPlaceId: snackPlaceId),
        ),
      );
    }

    // 4. Gọi hàm ghi nhận click trong nền (không cần await)
    _recordClickInBackground(snackPlaceId);

    // 5. Mở khóa UI sau một khoảng trễ ngắn để tránh spam trong lúc chuyển màn hình
    await Future.delayed(const Duration(milliseconds: 500));
    _isProcessingClick = false;
  }


  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 5,
        itemBuilder: (context, index) {
          return const SnackPlaceCard(isLoading: true);
        },
      );
    }

    if (_snackPlaces.isEmpty && !_hasMore) {
      return const Center(child: Text('Không tìm thấy quán ăn nào.'));
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _snackPlaces.length + (_hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _snackPlaces.length) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final item = _snackPlaces[index];
        return SnackPlaceCard(
          item: item,
          onTap: () => _handleCardPress(item.snackPlaceId),
          isLoading: false,
        );
      },
    );
  }
}