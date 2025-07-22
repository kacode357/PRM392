// lib/models/restaurant.dart

class Restaurant {
  final String id;
  final String name;
  final String rating;
  final String address;
  final String mainDish;
  final num averagePrice;
  final String openingHour;
  final String businessModelName;
  final List<String> tastes;
  final List<String> diets;
  final List<String> foodTypes;
  final String image;

  Restaurant({
    required this.id,
    required this.name,
    required this.rating,
    required this.address,
    required this.mainDish,
    required this.averagePrice,
    required this.openingHour,
    required this.businessModelName,
    required this.tastes,
    required this.diets,
    required this.foodTypes,
    required this.image,
  });

  // Hàm factory để map từ JSON của API CheckCreatedSnackplaceApi
  factory Restaurant.fromJson(Map<String, dynamic> json) {
    // Lấy ra object attributes bên trong, nếu không có thì dùng map rỗng
    final attributes = json['attributes'] as Map<String, dynamic>? ?? {};
    
    // Helper để map các list con, tránh lỗi null
    List<String> mapAttribute(dynamic list, String keyName) {
      if (list is List) {
        return list.map((item) => item[keyName] as String).toList();
      }
      return [];
    }

    return Restaurant(
      id: json['snackPlaceId'] ?? '',
      name: json['placeName'] ?? 'Chưa có tên',
      rating: json['rating']?.toString() ?? 'N/A',
      address: json['address'] ?? 'Chưa có địa chỉ',
      mainDish: json['mainDish']?.trim() ?? 'Chưa có món chính',
      averagePrice: json['averagePrice'] ?? 0,
      openingHour: json['openingHour'] ?? '00:00:00',
      businessModelName: json['businessModelName'] ?? 'Chưa xác định',
      image: json['image'] ?? '',
      tastes: mapAttribute(attributes['tastes'], 'tasteName'),
      diets: mapAttribute(attributes['diets'], 'dietName'),
      foodTypes: mapAttribute(attributes['foodTypes'], 'foodTypeName'),
    );
  }
}