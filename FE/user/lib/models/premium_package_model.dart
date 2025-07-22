class PremiumPackage {
  final bool isActive;
  final int packageId;
  final String packageName;
  final String purchaseDate;

  PremiumPackage({
    required this.isActive,
    required this.packageId,
    required this.packageName,
    required this.purchaseDate,
  });

  factory PremiumPackage.fromJson(Map<String, dynamic> json) {
    return PremiumPackage(
      isActive: json['isActive'] ?? false,
      packageId: json['packageId'] ?? 0,
      packageName: json['packageName'] ?? '',
      purchaseDate: json['purchaseDate'] ?? '',
    );
  }
}