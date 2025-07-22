// lib/screens/package_details_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:merchant/models/premium_package.dart';
import 'package:merchant/services/premium_package_services.dart';
import 'package:merchant/screens/payment_method_screen.dart';

class PackageDetailsScreen extends StatefulWidget {
  final String packageId;
  const PackageDetailsScreen({super.key, required this.packageId});

  @override
  State<PackageDetailsScreen> createState() => _PackageDetailsScreenState();
}

class _PackageDetailsScreenState extends State<PackageDetailsScreen> {
  PremiumPackage? _packageData;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchPackageDetails();
  }

  Future<void> _fetchPackageDetails() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final response = await PremiumPackageServices.getPremiumPackageByIdApi(id: widget.packageId);
      if (mounted && response.status == 200 && response.data != null) {
        setState(() {
          _packageData = PremiumPackage.fromJson(response.data);
        });
      } else {
        throw Exception(response.message ?? 'Không thể tải dữ liệu gói.');
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); });
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  void _handleUpgradePress() async { // << Thêm async
  if (_packageData != null) {
    // >>> THÊM AWAIT VÀ XỬ LÝ KẾT QUẢ <<<
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentMethodScreen(
          premiumPackageId: _packageData!.id.toString(),
          packageName: _packageData!.name,
        ),
      ),
    );
    // Nếu màn hình thanh toán trả về true, thì mình cũng trả về true cho PromotionsTab
    if (result == true && mounted) {
      Navigator.pop(context, true);
    }
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Để trong suốt cho đẹp
      backgroundColor: Colors.grey[200], 
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Text(_error!), ElevatedButton(onPressed: _fetchPackageDetails, child: const Text('Thử lại'))]));
    }
    if (_packageData == null) {
      return const Center(child: Text('Không tìm thấy thông tin gói dịch vụ.'));
    }

    final package = _packageData!;
    final priceFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'VND');

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Nút close
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                icon: const Icon(Icons.close, size: 30),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            const SizedBox(height: 10),

            // Header
            Text(package.name, style: Theme.of(context).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              'Vạn sự khó đầu nan, gian nan không thể nan với ${package.name} của Măm Mặp',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey[700]),
            ),
            const SizedBox(height: 40),

            // Card chi tiết
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        // Giá
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(priceFormatter.format(package.price).replaceAll('VND', ''), style: Theme.of(context).textTheme.displayMedium?.copyWith(fontWeight: FontWeight.bold)),
                            const SizedBox(width: 4),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: Text('VND /tháng', style: Theme.of(context).textTheme.titleMedium),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        
                        // Các quyền lợi
                        ...package.descriptions.map((desc) => Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: Row(
                            children: [
                              const Icon(Icons.check_circle, color: Colors.green, size: 20),
                              const SizedBox(width: 12),
                              Expanded(child: Text(desc, style: const TextStyle(fontSize: 16))),
                            ],
                          ),
                        )).toList(),
                        const SizedBox(height: 24),

                        // Nút nâng cấp
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                            ),
                            onPressed: _handleUpgradePress,
                            child: const Text('Nâng cấp ngay', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}