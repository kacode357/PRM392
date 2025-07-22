import 'package:flutter/material.dart';

class EditRestaurantScreen extends StatelessWidget {
  final String restaurantId;
  const EditRestaurantScreen({super.key, required this.restaurantId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sửa Thông Tin Quán')),
      body: Center(child: Text('Sửa quán ăn ID: $restaurantId')),
    );
  }
}