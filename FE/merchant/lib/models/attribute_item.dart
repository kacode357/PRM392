// lib/models/attribute_item.dart
class AttributeItem {
  final String id;
  final String name;

  AttributeItem({required this.id, required this.name});

  factory AttributeItem.fromJson(Map<String, dynamic> json) {
    return AttributeItem(
      id: json['id'],
      // API của mày có lúc trả về 'tasteName', 'dietName',... nên ta phải check hết
      name: json['name'] ?? json['tasteName'] ?? json['dietName'] ?? json['foodTypeName'] ?? '',
    );
  }
}