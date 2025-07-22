import 'dart:async';
import 'dart:convert';
// Không cần import 'dart:ui' nếu không dùng lerpDouble hay Color.lerp
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:user/config/dio_customize.dart';
import 'package:user/models/dish_model.dart';
import 'package:user/models/rating_summary_model.dart';
import 'package:user/models/snack_place_model.dart';
import 'package:user/screens/auth/signin_screen.dart';
import 'package:user/services/dish_services.dart';
import 'package:user/services/review_services.dart';
import 'package:user/services/snackplace_services.dart';
import 'package:user/widgets/detail/dish_list_item.dart';
import 'package:user/screens/review/review_screen.dart';
import 'package:user/screens/review/comments_screen.dart';
import 'package:user/constants/app_fonts.dart';
import 'package:intl/intl.dart';
import 'package:user/widgets/detail/snack_place_detail_skeleton.dart';

class SnackPlaceDetailScreen extends StatefulWidget {
  final String snackPlaceId;
  const SnackPlaceDetailScreen({super.key, required this.snackPlaceId});

  @override
  State<SnackPlaceDetailScreen> createState() => _SnackPlaceDetailScreenState();
}

class _SnackPlaceDetailScreenState extends State<SnackPlaceDetailScreen>
    with SingleTickerProviderStateMixin {
  SnackPlace? _snackPlace;
  bool _isLoading = true;
  List<Dish> _dishes = [];
  bool _isLoadingDishes = true;
  RatingSummary? _ratingSummary;
  bool _isLoadingRatings = true;
  late TabController _tabController;

  // CÁC BIẾN CHO ANIMATION OPACITY
  final ScrollController _scrollController = ScrollController();
  final ValueNotifier<double> _infoSectionTitleOpacity = ValueNotifier(1.0); // Opacity cho title màu đen trong info section

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchData();
    _scrollController.addListener(_updateTitleOpacity); // Thêm listener cho scroll
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.removeListener(_updateTitleOpacity); // Xóa listener
    _scrollController.dispose(); // Dispose controller
    _infoSectionTitleOpacity.dispose();
    super.dispose();
  }

  // LOGIC CẬP NHẬT OPACITY
  void _updateTitleOpacity() {
    const double appBarExpandedHeight = 500.0;
    const double minFlexibleSpaceHeight = kToolbarHeight; // Chiều cao thanh AppBar khi ghim

    // Khoảng cách cuộn mà animation xảy ra
    final double animationRange = appBarExpandedHeight - minFlexibleSpaceHeight;
    final double scrollOffset = _scrollController.offset;

    // Tính toán tỷ lệ cuộn từ 0.0 đến 1.0
    // Khi cuộn từ đầu đến khi AppBar bắt đầu thu nhỏ, shrinkFactor = 0
    // Khi cuộn đến khi AppBar thu nhỏ hoàn toàn, shrinkFactor = 1
    final double shrinkFactor = (scrollOffset / animationRange).clamp(0.0, 1.0);

    // Opacity cho tiêu đề trong _buildInfoSection(): Giảm từ 1.0 về 0.0
    // Nó sẽ mờ nhanh hơn một chút để nhường chỗ cho tiêu đề trong AppBar
    _infoSectionTitleOpacity.value = (1.0 - shrinkFactor * 2).clamp(0.0, 1.0);
  }

  Future<void> _fetchData() async {
    try {
      await Future.wait([
        _fetchSnackPlaceDetails(),
        _fetchDishes(),
        _fetchRatings(),
      ]);
    } catch (e) {
      debugPrint("Lỗi tải dữ liệu: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        // Cập nhật opacity ban đầu sau khi dữ liệu được tải
        _updateTitleOpacity();
      }
    }
  }

  Future<void> _fetchSnackPlaceDetails() async {
    try {
      final ApiResponse detailResponse = await SnackPlaceServices.getSnackPlaceByIdSkipAllApi(
          id: widget.snackPlaceId);
      if (detailResponse.status == 200 && detailResponse.data != null) {
        if (mounted) {
          setState(() {
            _snackPlace = SnackPlace.fromJson(detailResponse.data);
          });
        }
      }
    } catch (e) {
      debugPrint("Lỗi lấy chi tiết quán: $e");
    }
  }

  Future<void> _fetchDishes() async {
    try {
      final ApiResponse dishesResponse = await DishServices.getNoNotiDishesBySnackPlaceApi(
          snackPlaceId: widget.snackPlaceId);
      if (dishesResponse.status == 200 && dishesResponse.data != null) {
        final List<dynamic> dishData = dishesResponse.data ?? [];
        if (mounted) {
          setState(() {
            _dishes = dishData.map((json) => Dish.fromJson(json)).toList();
          });
        }
      }
    } catch (e) {
      debugPrint("Lỗi lấy danh sách món ăn: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingDishes = false;
        });
      }
    }
  }

  Future<void> _fetchRatings() async {
    setState(() => _isLoadingRatings = true);
    try {
      final ApiResponse ratingResponse =
      await ReviewServices.getAverageRateApi(snackPlaceId: widget.snackPlaceId);
      if (ratingResponse.status == 200 && ratingResponse.data != null) {
        if (mounted) {
          setState(() {
            _ratingSummary = RatingSummary.fromJson(ratingResponse.data);
          });
        }
      }
    } catch (e) {
      debugPrint("Lỗi lấy đánh giá: $e");
      if (mounted) setState(() => _ratingSummary = null);
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingRatings = false;
        });
      }
    }
  }

  Future<void> _handleCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      _showErrorDialog('Không thể thực hiện cuộc gọi.');
    }
  }

  Future<void> _handleCopyAddress(String address) async {
    await Clipboard.setData(ClipboardData(text: address));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã sao chép địa chỉ!')),
      );
    }
  }

  Future<void> _navigateToReview() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id');

    if (userId == null) {
      _showLoginDialog();
    } else {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ReviewScreen(snackPlaceId: widget.snackPlaceId),
        ),
      );

      if (result == true && mounted) {
        _fetchRatings();
      }
    }
  }

  void _navigateToComments() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CommentsScreen(snackPlaceId: widget.snackPlaceId),
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Lỗi', style: AppFonts.comfortaaBold),
        content: Text(message, style: AppFonts.comfortaaRegular),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('OK', style: AppFonts.comfortaaMedium),
          ),
        ],
      ),
    );
  }

  void _showLoginDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Yêu cầu đăng nhập', style: AppFonts.comfortaaBold),
          content: Text('Bạn cần đăng nhập để có thể thực hiện đánh giá.', style: AppFonts.comfortaaRegular),
          actions: <Widget>[
            TextButton(
              child: Text('Để sau', style: AppFonts.comfortaaMedium),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Đăng nhập', style: AppFonts.comfortaaBold),
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SignInScreen()),
                );
              },
            ),
          ],
        );
      },
    );
  }

  String _formatTime(String time) {
    try {
      final parts = time.split(':');
      if (parts.length < 2) return 'Không xác định';

      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);

      final DateTime now = DateTime.now();
      final DateTime dateTime = DateTime(now.year, now.month, now.day, hour, minute);

      final DateFormat formatter = DateFormat('hh:mm a', 'vi_VN');
      return formatter.format(dateTime);
    } catch (e) {
      debugPrint('Error formatting time: $e');
      return 'Không xác định';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const SnackPlaceDetailSkeleton()
          : _snackPlace == null
          ? Center(child: Text('Không thể tải dữ liệu quán.', style: AppFonts.comfortaaRegular))
          : _buildBody(),
    );
  }

  Widget _buildBody() {
    return RefreshIndicator(
      onRefresh: _fetchData,
      child: CustomScrollView(
        controller: _scrollController, // Gán ScrollController vào CustomScrollView
        slivers: <Widget>[
          _buildSliverAppBar(),
          SliverToBoxAdapter(
            child: _buildInfoSection(),
          ),
          _buildTabBar(),
          _buildTabBarView(),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    const double appBarExpandedHeight = 300.0;

    return SliverAppBar(
      expandedHeight: appBarExpandedHeight,
      floating: false,
      pinned: true,
      snap: false,
      leading: Container(
        margin: const EdgeInsets.all(8),

        child: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      elevation: 1,

      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 60, bottom: 16), // Padding cho title khi pinned
        // Sử dụng ValueListenableBuilder để điều khiển opacity của title khi pinned
        title: ValueListenableBuilder<double>(
          valueListenable: _infoSectionTitleOpacity,
          builder: (context, opacity, child) {
            // Tiêu đề pinned trên AppBar sẽ hiện ra khi opacity của tiêu đề info section giảm.
            // Khi opacity của info section là 1.0 (cuộn ở đầu), tiêu đề này là 0.0 (ẩn).
            // Khi opacity của info section là 0.0 (cuộn hết animation), tiêu đề này là 1.0 (hiện hoàn toàn).
            final double pinnedTitleDisplayOpacity = (1.0 - opacity).clamp(0.0, 1.0);

            return Opacity(
              opacity: pinnedTitleDisplayOpacity,
              child: Text(
                _snackPlace!.placeName,
                style: AppFonts.comfortaaBold.copyWith(
                  fontSize: 20, // Kích thước font cố định khi ghim
                  color: Colors.black, // Màu trắng khi ghim


                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            );
          },
        ),
        centerTitle: false,
        background: Stack(
          fit: StackFit.expand,
          children: [
            Hero(
              tag: 'snackPlaceImage-${widget.snackPlaceId}',
              child: CachedNetworkImage(
                imageUrl: _snackPlace!.image,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                placeholder: (context, url) => Container(
                  color: Colors.grey[200],
                  child: const Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey[200],
                  child: const Icon(Icons.broken_image, color: Colors.grey),
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.3),
                    Colors.transparent,
                    Colors.black.withOpacity(0.3),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // ĐÂY LÀ PLACENAME BAN ĐẦU, SẼ MỜ DẦN KHI SCROLL LÊN
          ValueListenableBuilder<double>(
            valueListenable: _infoSectionTitleOpacity,
            builder: (context, opacity, child) {
              return Opacity(
                opacity: opacity,
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        _snackPlace!.placeName,
                        style: AppFonts.baloo2ExtraBold.copyWith(fontSize: 28, color: Colors.black), // Font size và màu ban đầu
                      ),
                    ),
                    if (_snackPlace!.premiumPackage?.isActive == true)
                      const Padding(
                        padding: EdgeInsets.only(left: 8.0),
                        child: Icon(Icons.workspace_premium, color: Colors.amber, size: 24),
                      ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          _buildRatingSummary(),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _navigateToReview,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              backgroundColor: Colors.orange.shade700,
            ),
            child: Text('Đánh giá ngay', style: AppFonts.comfortaaBold.copyWith(fontSize: 18, color: Colors.white)),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: _navigateToComments,
            style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: Text('Xem bình luận', style: AppFonts.comfortaaMedium.copyWith(fontSize: 18)),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingSummary() {
    if (_isLoadingRatings) {
      return const CircularProgressIndicator(strokeWidth: 2.0);
    }
    if (_ratingSummary == null) {
      return Text('Chưa có đánh giá.', style: AppFonts.comfortaaRegular.copyWith(color: Colors.grey));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            const Icon(Icons.star, color: Colors.amber),
            const SizedBox(width: 4),
            Text('${_ratingSummary!.averageRating.toStringAsFixed(1)} ', style: AppFonts.comfortaaBold.copyWith(fontSize: 16)),
            Text('(${_ratingSummary!.totalRatingsCount} đánh giá)', style: AppFonts.comfortaaRegular.copyWith(color: Colors.grey)),
            const SizedBox(width: 8),
            Text('${_ratingSummary!.recommendPercent.toStringAsFixed(0)}% khuyên dùng', style: AppFonts.comfortaaMedium.copyWith(color: Colors.green)),
          ],
        ),
        const SizedBox(height: 10),
        _buildRatingDistribution(),
      ],
    );
  }

  Widget _buildRatingDistribution() {
    return Column(
      children: List.generate(5, (index) {
        final star = 5 - index;
        final percent = _ratingSummary!.ratingDistributionPercent[star.toString()] ?? 0.0;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Row(
            children: [
              Text('$star sao', style: AppFonts.comfortaaRegular.copyWith(fontSize: 14, color: Colors.grey[700])),
              const SizedBox(width: 8),
              Expanded(
                child: LinearProgressIndicator(
                  value: percent / 100,
                  backgroundColor: Colors.grey[300],
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 8),
              Text('${percent.toStringAsFixed(0)}%', style: AppFonts.comfortaaRegular.copyWith(fontSize: 14, color: Colors.grey[700])),
            ],
          ),
        );
      }),
    );
  }

  SliverPersistentHeader _buildTabBar() {
    return SliverPersistentHeader(
      delegate: _SliverAppBarDelegate(
        TabBar(
          controller: _tabController,
          labelColor: Theme.of(context).primaryColor,
          unselectedLabelColor: Colors.grey[600],
          indicatorColor: Theme.of(context).primaryColor,
          indicatorSize: TabBarIndicatorSize.tab,
          labelStyle: AppFonts.comfortaaBold.copyWith(fontSize: 15),
          unselectedLabelStyle: AppFonts.comfortaaMedium.copyWith(fontSize: 15),
          tabs: const [
            Tab(text: 'Tổng quan', icon: Icon(Icons.info_outline)),
            Tab(text: 'Món ăn', icon: Icon(Icons.restaurant_menu)),
          ],
        ),
      ),
      pinned: true,
    );
  }

  Widget _buildTabBarView() {
    return SliverFillRemaining(
      child: TabBarView(
        controller: _tabController,
        children: <Widget>[
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Giới thiệu', style: AppFonts.baloo2Bold.copyWith(fontSize: 22)),
                const SizedBox(height: 10),
                Text(
                  _snackPlace!.description ?? 'Không có mô tả chi tiết.',
                  style: AppFonts.comfortaaRegular.copyWith(fontSize: 16, color: Colors.grey[800]),
                ),
                const SizedBox(height: 24),
                Text('Thông tin liên hệ', style: AppFonts.baloo2Bold.copyWith(fontSize: 22)),
                const SizedBox(height: 10),
                _buildDetailRow(Icons.location_on_outlined, _snackPlace!.address, isAddress: true),
                if (_snackPlace!.phoneNumber != null &&
                    _snackPlace!.phoneNumber!.isNotEmpty)
                  _buildDetailRow(Icons.call_outlined, _snackPlace!.phoneNumber!,
                      isPhone: true),
                _buildDetailRow(
                    Icons.access_time_outlined, _snackPlace!.openingHour),
                // PHẦN BẢN ĐỒ ĐÃ BỊ XÓA
              ],
            ),
          ),
          _buildDishesTab(),
        ],
      ),
    );
  }

  Widget _buildDishesTab() {
    if (_isLoadingDishes) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_dishes.isEmpty) {
      return Center(
        child: Text(
          'Quán chưa có món ăn nào.',
          style: AppFonts.comfortaaRegular.copyWith(fontSize: 16, color: Colors.grey),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _dishes.length,
      separatorBuilder: (BuildContext context, int index) => const Divider(height: 20),
      itemBuilder: (context, index) {
        final dish = _dishes[index];
        return DishListItem(dish: dish);
      },
    );
  }

  Widget _buildDetailRow(IconData icon, String text,
      {bool isAddress = false, bool isPhone = false}) {
    Widget textWidget = Text(text, style: AppFonts.comfortaaRegular.copyWith(fontSize: 16));
    if (isPhone) {
      textWidget = InkWell(
        onTap: () => _handleCall(text),
        child: Text(
          text,
          style: AppFonts.comfortaaMedium.copyWith(
            fontSize: 16,
            color: Colors.blue,
            decoration: TextDecoration.underline,
          ),
        ),
      );
    } else if (isAddress) {
      textWidget = InkWell(
        onTap: () => _handleCopyAddress(text),
        child: Row(
          children: [
            Expanded(child: Text(text, style: AppFonts.comfortaaRegular.copyWith(fontSize: 16))),
            const SizedBox(width: 8),
            const Icon(Icons.copy_outlined, size: 20, color: Colors.grey),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22, color: Colors.grey[700]),
          const SizedBox(width: 16),
          Expanded(child: textWidget),
        ],
      ),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);

  final TabBar _tabBar;

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}