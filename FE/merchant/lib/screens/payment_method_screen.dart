// lib/screens/payment_method_screen.dart
import 'package:flutter/material.dart';
import 'package:merchant/models/payment_creation_response.dart';
import 'package:merchant/services/payment_services.dart';
import 'package:merchant/screens/payment_qr_screen.dart';

class PaymentMethodScreen extends StatefulWidget {
  final String premiumPackageId;
  final String packageName;

  const PaymentMethodScreen({
    super.key,
    required this.premiumPackageId,
    required this.packageName,
  });

  @override
  State<PaymentMethodScreen> createState() => _PaymentMethodScreenState();
}

class _PaymentMethodScreenState extends State<PaymentMethodScreen> {
  bool _isLoading = false;
  String? _error;

  Future<void> _handlePaymentMethodSelect() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final packageIdInt = int.tryParse(widget.premiumPackageId);
      if (packageIdInt == null) {
        throw Exception('ID gói không hợp lệ.');
      }

      final response = await PaymentServices.createPaymentApi(
        premiumPackageId: packageIdInt,
      );

      if (mounted && response.status == 200 && response.data != null) {
        final paymentInfo = PaymentCreationResponse.fromJson(response.data);

        // >>> SỬA LẠI CHỖ NÀY <<<
        // Dùng push thay vì pushReplacement và chờ kết quả
        final result = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (_) => PaymentQrScreen(
              qrCodeUrl: paymentInfo.qrCodeUrl,
              paymentId: paymentInfo.paymentId,
              premiumPackageId: widget.premiumPackageId,
              paymentCode: paymentInfo.paymentCode,
            ),
          ),
        );
        // Nếu màn hình QR trả về true, thì mình cũng trả về true
        if (result == true && mounted) {
          Navigator.pop(context, true);
        }
      } else {
        throw Exception(
          response.message ?? 'Không thể tạo giao dịch thanh toán.',
        );
      }
    } catch (e) {
      if (mounted)
        setState(() {
          _error = e.toString();
        });
    } finally {
      if (mounted)
        setState(() {
          _isLoading = false;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thanh toán qua'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              ),

            Text(
              'Bạn đang thanh toán cho gói: ${widget.packageName}',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // VNPay
            _buildPaymentOption(
              logoAsset:
                  'assets/images/vnpay_logo.jpg', // Mày phải thêm ảnh này vào assets
              name: 'Thanh Toán Mã QR (VNPay)',
              onTap: _handlePaymentMethodSelect,
              isEnabled: !_isLoading,
            ),

            // Các phương thức khác (bị vô hiệu hóa)
            _buildPaymentOption(
              logoAsset: 'assets/images/momo_logo.png',
              name: 'Momo',
              isEnabled: false,
            ),
            _buildPaymentOption(
              logoAsset: 'assets/images/zalo_pay.png',
              name: 'Zalo Pay',
              isEnabled: false,
            ),
            _buildPaymentOption(
              logoAsset: 'assets/images/viettel_pay_logo.jpg',
              name: 'Viettel Money',
              isEnabled: false,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentOption({
    required String logoAsset,
    required String name,
    VoidCallback? onTap,
    bool isEnabled = true,
  }) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: isEnabled ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: Opacity(
          opacity: isEnabled ? 1.0 : 0.5,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
            child: Row(
              children: [
                Image.asset(logoAsset, width: 40, height: 40),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                if (isEnabled)
                  const Icon(Icons.arrow_forward_ios, color: Colors.grey),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
