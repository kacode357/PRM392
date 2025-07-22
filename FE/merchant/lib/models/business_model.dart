// lib/models/business_model.dart
class BusinessModel {
  final String id;
  final String name;

  BusinessModel({required this.id, required this.name});

  factory BusinessModel.fromJson(Map<String, dynamic> json) {
    return BusinessModel(
      id: json['id'],
      name: json['name'],
    );
  }
}