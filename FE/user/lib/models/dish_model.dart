class Dish {
  final String dishId;
  final String name;
  final num price;
  final String description;
  final String? image;

  Dish({
    required this.dishId,
    required this.name,
    required this.price,
    required this.description,
    this.image,
  });

  factory Dish.fromJson(Map<String, dynamic> json) {
    return Dish(
      dishId: json['dishId'] ?? '',
      name: json['name'] ?? 'N/A',
      price: json['price'] ?? 0,
      description: json['description'] ?? '',
      image: json['image'],
    );
  }
}