// lib/models/payment_creation_response.dart

class PaymentCreationResponse {
  final String qrCodeUrl;
  final String paymentId;
  final String paymentCode;

  PaymentCreationResponse({
    required this.qrCodeUrl,
    required this.paymentId,
    required this.paymentCode,
  });

  factory PaymentCreationResponse.fromJson(Map<String, dynamic> json) {
    return PaymentCreationResponse(
      qrCodeUrl: json['qrCodeUrl'] ?? '',
      paymentId: json['id']?.toString() ?? '', // API trả về là 'id'
      paymentCode: json['paymentCode'] ?? '',
    );
  }
}