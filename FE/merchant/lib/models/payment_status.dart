// lib/models/payment_status.dart

class PaymentStatus {
  final String paymentId;
  final bool paymentStatus; // true nếu đã thanh toán, false nếu chưa
  final String message;

  PaymentStatus({
    required this.paymentId,
    required this.paymentStatus,
    required this.message,
  });

  factory PaymentStatus.fromJson(Map<String, dynamic> json) {
    return PaymentStatus(
      paymentId: json['paymentId'] ?? '',
      paymentStatus: json['paymentStatus'] ?? false,
      message: json['message'] ?? 'Đang chờ thanh toán...',
    );
  }
}