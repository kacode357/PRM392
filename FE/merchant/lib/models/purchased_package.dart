// lib/models/purchased_package.dart

class PurchasedPackage {
  final int premiumPackageId;
  final bool isActive;

  PurchasedPackage({
    required this.premiumPackageId,
    required this.isActive,
  });

  factory PurchasedPackage.fromJson(Map<String, dynamic> json) {
    return PurchasedPackage(
      premiumPackageId: json['premiumPackageId'],
      isActive: json['isActive'] ?? false,
    );
  }
}