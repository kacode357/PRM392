class Attribute {
  final String id;
  final String name;

  Attribute({required this.id, required this.name});

  factory Attribute.fromJson(Map<String, dynamic> json) {
    return Attribute(
      id: json['id'] as String,
      name: json['name'] as String,
    );
  }
}