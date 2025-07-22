// lib/models/dish.dart

class Dish {
  final String dishId;
  final String name;
  final String description;
  final String image;
  final num price;
  final String snackPlaceId;

  Dish({
    required this.dishId,
    required this.name,
    required this.description,
    required this.image,
    required this.price,
    required this.snackPlaceId,
  });

  factory Dish.fromJson(Map<String, dynamic> json) {
    return Dish(
      dishId: json['dishId'], // API của mày trả về là dishId
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      image: json['image'] ?? '',
      price: json['price'] ?? 0,
      snackPlaceId: json['snackPlaceId'] ?? '',
    );
  }
}