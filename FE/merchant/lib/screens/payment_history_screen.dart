// lib/screens/payment_history_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:merchant/constants/app_colors.dart';
import 'package:merchant/constants/app_fonts.dart';
import 'package:merchant/models/payment_history_item.dart';
import 'package:merchant/screens/payment_qr_screen.dart';
import 'package:merchant/services/payment_services.dart';
// import 'package:merchant/screens/payment_qr_screen.dart'; // Mày phải có màn này

class PaymentHistoryScreen extends StatefulWidget {
  const PaymentHistoryScreen({super.key});

  @override
  State<PaymentHistoryScreen> createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends State<PaymentHistoryScreen> {
  bool _isLoading = true;
  String? _error;
  List<PaymentHistoryItem> _historyData = [];
  String? _processingItemId; // ID của item đang được xử lý "Thanh toán lại"

  @override
  void initState() {
    super.initState();
    _fetchPaymentHistory();
  }

  // Hàm gọi API lấy lịch sử
  Future<void> _fetchPaymentHistory() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await PaymentServices.getPaymentHistoryApi();
      if (response.status == 200 && response.data != null) {
        final List<dynamic> rawData = response.data;
        final List<PaymentHistoryItem> items = rawData
            .map((itemJson) => PaymentHistoryItem.fromJson(itemJson))
            .toList();

        // Sắp xếp mới nhất lên đầu
        items.sort((a, b) => b.createdAt.compareTo(a.createdAt));

        setState(() {
          _historyData = items;
        });
      } else {
        setState(() {
          _error = response.message ?? "Không thể tải lịch sử giao dịch.";
        });
      }
    } catch (e) {
      setState(() {
        _error = "Lỗi kết nối. Vui lòng thử lại.";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Hàm xử lý "Thanh toán lại"
  Future<void> _handleContinuePayment(PaymentHistoryItem item) async {
    setState(() {
      _processingItemId = item.id;
    });

    try {
      final response = await PaymentServices.createPaymentApi(
       premiumPackageId: item.premiumPackageId,
      );

      if (response.status == 200 && response.data != null && context.mounted) {
        // Giả sử mày có màn PaymentQrScreen và nó nhận các params này
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PaymentQrScreen(
              qrCodeUrl: response.data['qrCodeUrl'],
              paymentId: response.data['id'],
              paymentCode: response.data['paymentCode'],
                  premiumPackageId: item.premiumPackageId.toString(),
            ),
          ),
        );
        
      } else {
         if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response.message ?? "Không thể tạo lại thanh toán.")),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Lỗi khi tiếp tục thanh toán.")),
          );
        }
    } finally {
      setState(() {
        _processingItemId = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch sử giao dịch'),
      ),
      backgroundColor: AppColors.lightGrayBackground,
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!, style: AppFonts.comfortaaRegular),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _fetchPaymentHistory,
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }
    if (_historyData.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.inbox_outlined, size: 80, color: AppColors.lightIcon),
            const SizedBox(height: 16),
            Text(
              'Chưa có giao dịch nào',
              style: AppFonts.comfortaaRegular.copyWith(color: AppColors.lightText),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _historyData.length,
      itemBuilder: (context, index) {
        return _buildHistoryCard(_historyData[index]);
      },
    );
  }

  Widget _buildHistoryCard(PaymentHistoryItem item) {
    final bool isProcessing = _processingItemId == item.id;
    final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'VND');
    final dateFormatter = DateFormat('dd/MM/yyyy HH:mm', 'vi_VN');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Tên gói và số tiền
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    item.premiumPackageName,
                    style: AppFonts.comfortaaBold.copyWith(fontSize: 18),
                  ),
                ),
                Text(
                  formatter.format(item.amount),
                  style: AppFonts.comfortaaBold.copyWith(
                      fontSize: 18, color: AppColors.lightPrimary),
                ),
              ],
            ),
            const Divider(height: 20),
            // Details: Mã GD, Ngày tạo, Trạng thái
            _buildDetailRow(
              label: 'Mã GD',
              value: item.paymentCode,
              isCopyable: true,
            ),
            _buildDetailRow(
              label: 'Ngày tạo',
              value: dateFormatter.format(item.createdAt),
            ),
            _buildDetailRow(
              label: 'Thanh toán lúc',
              value: item.paidAt != null
                  ? dateFormatter.format(item.paidAt!)
                  : 'N/A',
            ),
            Row(
              children: [
                Text('Trạng thái: ', style: AppFonts.comfortaaMedium.copyWith(fontSize: 14)),
                Text(
                  item.paymentStatus ? 'Thành công' : 'Đang chờ',
                  style: AppFonts.comfortaaBold.copyWith(
                    fontSize: 14,
                    color: item.paymentStatus ? AppColors.lightSuccess : AppColors.lightError,
                  ),
                ),
              ],
            ),
            // Nút Thanh toán lại
            if (!item.paymentStatus) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: isProcessing ? null : () => _handleContinuePayment(item),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.lightPrimary,
                    foregroundColor: Colors.white
                  ),
                  child: isProcessing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Thanh toán'),
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow({required String label, required String value, bool isCopyable = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text('$label:', style: AppFonts.comfortaaMedium.copyWith(fontSize: 14)),
          ),
          Expanded(
            child: Text(value, style: AppFonts.comfortaaRegular.copyWith(fontSize: 14)),
          ),
          if (isCopyable)
            GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(text: value));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đã sao chép mã giao dịch!')),
                );
              },
              child: const Icon(Icons.copy, size: 16, color: AppColors.lightIcon),
            )
        ],
      ),
    );
  }
}