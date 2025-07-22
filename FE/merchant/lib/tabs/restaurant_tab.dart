// lib/tabs/restaurant_tab.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:merchant/models/restaurant.dart';
import 'package:merchant/services/merchant_services.dart';
import 'package:merchant/screens/restaurant_form_screen.dart'; 
import 'package:merchant/screens/add_dish_screen.dart';

class RestaurantTab extends StatefulWidget {
  const RestaurantTab({super.key});

  @override
  State<RestaurantTab> createState() => _RestaurantTabState();
}

class _RestaurantTabState extends State<RestaurantTab> {
  Restaurant? _restaurant;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchRestaurantStatus();
  }

  /// Tải trạng thái quán ăn từ API
  Future<void> _fetchRestaurantStatus() async {
    // Không cần setState isLoading ở đây nếu mày muốn refresh mượt hơn
    // setState(() { _isLoading = true; _error = null; });

    try {
      final response = await MerchantServices.checkCreatedSnackplaceApi();
      if (mounted) { // Luôn kiểm tra mounted trước khi gọi setState
        if (response.status == 200) {
          if (response.data != null && response.data is Map<String, dynamic>) {
            setState(() {
              _restaurant = Restaurant.fromJson(response.data);
              _isLoading = false;
              _error = null;
            });
          } else {
            // API trả về 200 nhưng không có data, nghĩa là chưa tạo quán
            setState(() {
              _restaurant = null;
              _isLoading = false;
              _error = null;
            });
          }
        } else {
          // API trả về lỗi (vd: 401, 500)
          setState(() {
            _error = response.message ?? "Lỗi không xác định từ máy chủ";
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      // Lỗi kết nối hoặc lỗi khi parse JSON
      print('Lỗi trong _fetchRestaurantStatus: $e'); // In lỗi ra console để debug
      if (mounted) {
        setState(() {
          _error = "Không thể kết nối đến máy chủ. Vui lòng thử lại.";
          _isLoading = false;
        });
      }
    }
  }

  /// Điều hướng đến màn hình khác và chờ kết quả để refresh
  Future<void> _navigateAndRefresh(Widget screen) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );

    if (result == true && mounted) {
      // Làm cho việc refresh trông mượt hơn bằng cách không bật lại loading indicator
      await _fetchRestaurantStatus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quán Ăn Của Tôi'),
        centerTitle: true,
        actions: [
          // Chỉ hiện nút refresh khi có lỗi, hoặc đang loading
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.only(right: 16.0),
              child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
            )
          else if (_error != null)
            IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchRestaurantStatus),
        ],
      ),
      body: _buildBody(),
    );
  }

  /// Quyết định hiển thị widget nào dựa trên state
  Widget _buildBody() {
    if (_isLoading && _restaurant == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return _buildErrorView();
    }
    
    if (_restaurant != null) {
      return _buildRestaurantDetails(_restaurant!);
    } else {
      return _buildEmptyView();
    }
  }
  
  /// Widget hiển thị khi có lỗi
  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 60),
            const SizedBox(height: 16),
            Text(_error!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
              onPressed: _fetchRestaurantStatus, 
            ),
          ],
        ),
      ),
    );
  }

  /// Widget hiển thị khi chưa có quán ăn
  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.store_mall_directory_outlined, size: 80, color: Colors.grey),
          const SizedBox(height: 16),
          const Text('Mày chưa có quán ăn nào.', style: TextStyle(fontSize: 18)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Tạo Quán Ăn Ngay'),
            onPressed: () => _navigateAndRefresh(const RestaurantFormScreen()),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          )
        ],
      ),
    );
  }

  /// Widget hiển thị chi tiết quán ăn
  Widget _buildRestaurantDetails(Restaurant restaurant) {
    final priceFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'VND');
    String formatTime(String time) {
      try {
        final parts = time.split(':');
        return '${parts[0]}:${parts[1]}';
      } catch (e) {
        return time;
      }
    }

    return RefreshIndicator(
      onRefresh: _fetchRestaurantStatus, // Cho phép kéo để làm mới
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(), // Luôn cho phép scroll để kích hoạt RefreshIndicator
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ảnh quán
            if (restaurant.image.isNotEmpty)
              Image.network(
                restaurant.image,
                width: double.infinity, height: 220, fit: BoxFit.cover,
                loadingBuilder: (context, child, progress) {
                  return progress == null ? child : const SizedBox(height: 220, child: Center(child: CircularProgressIndicator()));
                },
                errorBuilder: (context, error, stackTrace) {
                  return const SizedBox(height: 220, child: Center(child: Icon(Icons.broken_image)));
                },
              )
            else 
              Container(height: 220, color: Colors.grey[300], child: const Center(child: Text('Chưa có ảnh'))),
            
            // Thông tin chi tiết
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(restaurant.name, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  _buildInfoRow(Icons.location_on, 'Địa chỉ', restaurant.address),
                  _buildInfoRow(Icons.restaurant_menu, 'Món chính', restaurant.mainDish),
                  _buildInfoRow(Icons.price_change, 'Giá trung bình', priceFormatter.format(restaurant.averagePrice)),
                  _buildInfoRow(Icons.access_time, 'Mở cửa', formatTime(restaurant.openingHour)),
                  _buildInfoRow(Icons.business, 'Loại hình', restaurant.businessModelName),
                  _buildInfoRow(Icons.style, 'Hương vị', restaurant.tastes.join(', ')),
                  _buildInfoRow(Icons.eco, 'Chế độ ăn', restaurant.diets.join(', ')),
                  _buildInfoRow(Icons.category, 'Loại món', restaurant.foodTypes.join(', ')),
                  
                  const SizedBox(height: 24),
                  // Các nút hành động
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.edit),
                          label: const Text('Sửa Quán'),
                          onPressed: () => _navigateAndRefresh(RestaurantFormScreen(restaurantId: restaurant.id)),
                          style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12), side: BorderSide(color: Theme.of(context).primaryColor)),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.add),
                          label: const Text('Quản lý Món'),
                          onPressed: () {
                             // Điều hướng đến màn hình quản lý món ăn
                             Navigator.push(context, MaterialPageRoute(builder: (_) => AddDishScreen(restaurantId: restaurant.id)));
                          },
                          style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Helper để tạo một dòng thông tin cho gọn
  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Theme.of(context).primaryColor, size: 20),
          const SizedBox(width: 12),
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          Expanded(child: Text(value.isEmpty ? 'Chưa có thông tin' : value, style: const TextStyle(fontSize: 15))),
        ],
      ),
    );
  }
}