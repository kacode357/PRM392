// lib/screens/payment_qr_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:merchant/models/payment_status.dart';
import 'package:merchant/models/premium_package.dart';
import 'package:merchant/models/user.dart';
import 'package:merchant/services/payment_services.dart';
import 'package:merchant/services/premium_package_services.dart';
import 'package:merchant/services/user_services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PaymentQrScreen extends StatefulWidget {
  final String qrCodeUrl;
  final String paymentId;
  final String premiumPackageId;
  final String paymentCode;

  const PaymentQrScreen({
    super.key,
    required this.qrCodeUrl,
    required this.paymentId,
    required this.premiumPackageId,
    required this.paymentCode,
  });

  @override
  State<PaymentQrScreen> createState() => _PaymentQrScreenState();
}

class _PaymentQrScreenState extends State<PaymentQrScreen> {
  PremiumPackage? _packageData;
  PaymentStatus? _paymentStatus;
  Timer? _pollingTimer;
  bool _isLoadingPackage = true;
  String? _error;
  bool _isPaymentConfirmed = false;

  @override
  void initState() {
    super.initState();
    _fetchPackageDetails();
    _startPolling();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel(); // Hủy timer khi màn hình bị đóng
    super.dispose();
  }

  Future<void> _fetchPackageDetails() async {
    setState(() { _isLoadingPackage = true; _error = null; });
    try {
      final response = await PremiumPackageServices.getPremiumPackageByIdApi(id: widget.premiumPackageId);
      if (mounted && response.status == 200 && response.data != null) {
        setState(() { _packageData = PremiumPackage.fromJson(response.data); });
      } else {
        throw Exception('Không thể tải thông tin gói.');
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); });
    } finally {
      if (mounted) setState(() { _isLoadingPackage = false; });
    }
  }

  void _startPolling() {
    // Gọi lần đầu ngay lập tức
    _pollPaymentStatus(); 
    // Sau đó gọi mỗi 3 giây
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _pollPaymentStatus();
    });
  }

  Future<void> _pollPaymentStatus() async {
    // Nếu đã thanh toán thành công thì không gọi API nữa
    if (_isPaymentConfirmed) {
      _pollingTimer?.cancel();
      return;
    }

    try {
      final response = await PaymentServices.checkPaymentStatusApi(paymentId: widget.paymentId);
      if (mounted && response.status == 200 && response.data != null) {
        final status = PaymentStatus.fromJson(response.data);
        setState(() { _paymentStatus = status; });

        if (status.paymentStatus) {
          setState(() { _isPaymentConfirmed = true; });
          _pollingTimer?.cancel();
          await _updateUserPackages(); // Cập nhật gói cho user
        }
      }
    } catch (e) {
      print('Lỗi kiểm tra thanh toán: $e');
      // Có thể set state lỗi ở đây nếu muốn
    }
  }

  Future<void> _updateUserPackages() async {
    try {
      final userResponse = await UserServices.getCurrentUserApi();
      if (userResponse.status == 200 && userResponse.data != null) {
        final user = User.fromJson(userResponse.data);
        final packageNames = user.userPackages.map((p) => p.packageName).toList();
        final prefs = await SharedPreferences.getInstance();
        await prefs.setStringList('packageNames', packageNames);
        print('Đã cập nhật các gói đã mua: $packageNames');
      }
    } catch (e) {
      print('Lỗi cập nhật gói người dùng: $e');
    }
  }

  Future<void> _copyToClipboard() async {
    await Clipboard.setData(ClipboardData(text: widget.paymentCode));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã sao chép mã giao dịch!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thanh Toán Gói'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoadingPackage) return const Center(child: CircularProgressIndicator());
    if (_error != null) return Center(child: Text(_error!));
    if (_packageData == null) return const Center(child: Text('Không có dữ liệu gói.'));

    final package = _packageData!;
    final priceFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'VND');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          Card(
            elevation: 8,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  Text(package.name, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor)),
                  const SizedBox(height: 10),
                  Text(priceFormatter.format(package.price), style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const Divider(height: 40),
                  const Text('Quét mã QR để hoàn tất thanh toán', textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, spreadRadius: 2)],
                    ),
                    child: Image.network(widget.qrCodeUrl, width: 220, height: 220),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Mã: ${widget.paymentCode}'),
                      IconButton(icon: const Icon(Icons.copy, size: 18), onPressed: _copyToClipboard),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildStatusMessage(),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
  style: ElevatedButton.styleFrom(
    minimumSize: const Size(double.infinity, 50),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
    backgroundColor: _isPaymentConfirmed ? Colors.green : Colors.grey,
    // Thêm style cho trạng thái disabled để nút trông "mờ" đi thật sự
    disabledForegroundColor: Colors.white70,
    disabledBackgroundColor: Colors.grey,
  ),
  // >>> SỬA Ở ĐÂY: Dùng pop(true) để trả kết quả về cho màn hình trước <<<
  onPressed: _isPaymentConfirmed 
    ? () => Navigator.of(context).pop(true) 
    : null,
  child: Text(
    _isPaymentConfirmed ? 'Hoàn Tất' : 'Đang Chờ Thanh Toán...',
    style: const TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
  ),
),
        ],
      ),
    );
  }

  Widget _buildStatusMessage() {
    IconData icon = Icons.hourglass_empty;
    Color color = Colors.orange;
    String text = 'Đang chờ thanh toán...';

    if (_isPaymentConfirmed) {
      icon = Icons.check_circle;
      color = Colors.green;
      text = _paymentStatus?.message ?? 'Thanh toán thành công!';
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: TextStyle(color: color, fontWeight: FontWeight.bold))),
        if (!_isPaymentConfirmed) const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
      ],
    );
  }
}