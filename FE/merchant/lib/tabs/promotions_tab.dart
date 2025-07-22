// lib/tabs/promotions_tab.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:merchant/models/premium_package.dart';
import 'package:merchant/models/purchased_package.dart';
import 'package:merchant/services/payment_services.dart';
import 'package:merchant/services/premium_package_services.dart';
import 'package:merchant/screens/package_details_screen.dart';
import 'package:merchant/screens/ai_create_image_screen.dart';

class PromotionsTab extends StatefulWidget {
  const PromotionsTab({super.key});

  @override
  State<PromotionsTab> createState() => _PromotionsTabState();
}

class _PromotionsTabState extends State<PromotionsTab> {
  List<PremiumPackage> _packages = [];
  List<PurchasedPackage> _purchasedPackages = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      // Gọi cả 2 API cùng lúc để tăng tốc
      final responses = await Future.wait([
        PremiumPackageServices.searchPremiumPackagesApi(pageNum: 1, pageSize: 10, searchKeyword: '', status: true),
        PaymentServices.hasPackageApi(),
      ]);

      final premiumResponse = responses[0];
      final purchasedResponse = responses[1];
      
      // Xử lý kết quả các gói premium
      if (premiumResponse.status == 200 && premiumResponse.data != null) {
        _packages = (premiumResponse.data['pageData'] as List)
            .map((json) => PremiumPackage.fromJson(json)).toList();
      } else {
        throw Exception('Không thể tải danh sách gói dịch vụ.');
      }

      // Xử lý kết quả các gói đã mua
      if (purchasedResponse.status == 200 && purchasedResponse.data != null) {
        _purchasedPackages = (purchasedResponse.data as List)
            .map((json) => PurchasedPackage.fromJson(json)).toList();
      } else {
        // Có thể không phải lỗi, chỉ là user chưa mua gói nào
        _purchasedPackages = [];
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }
  
  /// Helper kiểm tra xem gói đã được mua và kích hoạt chưa
  bool _isPackageActive(int packageId) {
    return _purchasedPackages.any((pkg) => pkg.premiumPackageId == packageId && pkg.isActive);
  }
Future<void> _navigateAndRefresh(Widget screen) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );

    // Nếu màn hình con trả về true, tải lại dữ liệu
    if (result == true && mounted) {
      // Hiện loading indicator nhỏ ở AppBar cho mượt
      setState(() { _isLoading = true; }); 
      await _fetchData();
    }
  }
  /// Xử lý khi nhấn nút trên thẻ gói
  void _handlePackageTap(PremiumPackage package) {
    final bool isActive = _isPackageActive(package.id);
    
    // Nếu là gói Tiêu chuẩn và đã active thì không làm gì cả
    if (isActive && package.name.contains('Tiêu Chuẩn')) {
      return;
    }
    
    // Nếu đã active, chuyển đến màn hình sử dụng
    if (isActive) {
      if (package.name.contains('Cơ Bản')) {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const AiCreateImageScreen()));
      }
      // Thêm các trường hợp khác nếu có
    } else {
      // Nếu chưa active, chuyển đến màn hình chi tiết để mua
      Navigator.push(context, MaterialPageRoute(builder: (_) => PackageDetailsScreen(packageId: package.id.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quảng bá & Khuyến mãi'),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: _fetchData,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Text(_error!), ElevatedButton(onPressed: _fetchData, child: const Text('Thử lại'))]));
    }
    if (_packages.isEmpty) {
      return const Center(child: Text('Hiện không có gói dịch vụ nào.'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Quảng bá thương hiệu', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Quảng bá thương hiệu của bạn hiệu quả hơn thông qua các gói dịch vụ của chúng tôi.'),
          const SizedBox(height: 24),
          ..._packages.map((pkg) => _buildPackageCard(pkg)).toList(),
        ],
      ),
    );
  }

  Widget _buildPackageCard(PremiumPackage package) {
    final priceFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'VNĐ');
    final isActive = _isPackageActive(package.id);
    final isStandardAndActive = isActive && package.name.contains('Tiêu Chuẩn');
    
    String buttonText = 'Tìm hiểu thêm';
    if (isStandardAndActive) {
      buttonText = 'Đã kích hoạt';
    } else if (isActive) {
      buttonText = 'Sử dụng ngay';
    }

    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(package.name, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(priceFormatter.format(package.price), style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ...package.descriptions.map((desc) => Padding(
              padding: const EdgeInsets.only(bottom: 4.0),
              child: Row(children: [const Icon(Icons.check, size: 16, color: Colors.green), const SizedBox(width: 8), Expanded(child: Text(desc))]),
            )).toList(),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isStandardAndActive ? null : () => _handlePackageTap(package),
                child: Text(buttonText),
              ),
            ),
          ],
        ),
      ),
    );
  }
}