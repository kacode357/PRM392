// lib/models/premium_package.dart

class PremiumPackage {
  final int id;
  final String name;
  final num price;
  final List<String> descriptions;
  final bool status;

  PremiumPackage({
    required this.id,
    required this.name,
    required this.price,
    required this.descriptions,
    required this.status,
  });

  factory PremiumPackage.fromJson(Map<String, dynamic> json) {
    return PremiumPackage(
      id: json['id'],
      name: json['name'] ?? 'Không có tên',
      price: json['price'] ?? 0,
      // API trả về descriptions là một mảng các string
      descriptions: List<String>.from(json['descriptions'] ?? []),
      status: json['status'] ?? false,
    );
  }
}