// lib/models/payment_history_item.dart

class PaymentHistoryItem {
  final String id;
  final num amount;
  final bool paymentStatus;
  final DateTime createdAt;
  final DateTime? paidAt;
  final String paymentCode;
  final String? transactionId;
  final String premiumPackageName;
  // >>> SỬA DÒNG NÀY: Từ String thành int <<<
  final int premiumPackageId;

  PaymentHistoryItem({
    required this.id,
    required this.amount,
    required this.paymentStatus,
    required this.createdAt,
    this.paidAt,
    required this.paymentCode,
    this.transactionId,
    required this.premiumPackageName,
    required this.premiumPackageId,
  });

  factory PaymentHistoryItem.fromJson(Map<String, dynamic> json) {
    return PaymentHistoryItem(
      id: json['id'],
      amount: json['amount'],
      paymentStatus: json['paymentStatus'],
      createdAt: DateTime.parse(json['createdAt']),
      paidAt: json['paidAt'] != null ? DateTime.parse(json['paidAt']) : null,
      paymentCode: json['paymentCode'],
      transactionId: json['transactionId'],
      premiumPackageName: json['premiumPackageName'],
      // >>> DÒNG NÀY GIỜ SẼ CHẠY ĐÚNG <<<
      premiumPackageId: json['premiumPackageId'],
    );
  }
}