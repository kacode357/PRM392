// lib/screens/select_attributes_screen.dart
import 'package:flutter/material.dart';
import 'package:merchant/models/attribute_item.dart';
import 'package:merchant/services/diet_services.dart';
import 'package:merchant/services/food_type_services.dart';
import 'package:merchant/services/taste_services.dart'; // Mày phải có service này

class SelectAttributesScreen extends StatefulWidget {
  final List<String> initialTasteIds;
  final List<String> initialDietIds;
  final List<String> initialFoodTypeIds;

  const SelectAttributesScreen({
    super.key,
    required this.initialTasteIds,
    required this.initialDietIds,
    required this.initialFoodTypeIds,
  });

  @override
  State<SelectAttributesScreen> createState() => _SelectAttributesScreenState();
}

class _SelectAttributesScreenState extends State<SelectAttributesScreen> {
  // Dữ liệu từ API
  List<AttributeItem> _tastes = [];
  List<AttributeItem> _diets = [];
  List<AttributeItem> _foodTypes = [];

  // Các ID đang được chọn
  late Set<String> _selectedTasteIds;
  late Set<String> _selectedDietIds;
  late Set<String> _selectedFoodTypeIds;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Khởi tạo các set chứa ID đã chọn từ màn hình trước
    _selectedTasteIds = widget.initialTasteIds.toSet();
    _selectedDietIds = widget.initialDietIds.toSet();
    _selectedFoodTypeIds = widget.initialFoodTypeIds.toSet();
    _fetchAllAttributes();
  }

  Future<void> _fetchAllAttributes() async {
    try {
      // Gọi cả 3 API cùng lúc cho nhanh
      final responses = await Future.wait([
        TasteServices.searchTastesApi(pageNum: 1, pageSize: 100, searchKeyword: '', status: true),
        DietServices.searchDietsApi(pageNum: 1, pageSize: 100, searchKeyword: '', status: true),
        FoodTypeServices.searchFoodTypesApi(pageNum: 1, pageSize: 100, searchKeyword: '', status: true),
      ]);

      setState(() {
        _tastes = (responses[0].data['pageData'] as List).map((json) => AttributeItem.fromJson(json)).toList();
        _diets = (responses[1].data['pageData'] as List).map((json) => AttributeItem.fromJson(json)).toList();
        _foodTypes = (responses[2].data['pageData'] as List).map((json) => AttributeItem.fromJson(json)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() { _isLoading = false; });
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi tải dữ liệu thuộc tính: $e')));
    }
  }

  void _handleConfirm() {
    // Tạo map kết quả trả về
    final result = {
      'tasteIds': _selectedTasteIds.toList(),
      'dietIds': _selectedDietIds.toList(),
      'foodTypeIds': _selectedFoodTypeIds.toList(),
      // Lấy cả tên để hiển thị lại bên màn hình Create
      'tasteNames': _tastes.where((t) => _selectedTasteIds.contains(t.id)).map((t) => t.name).toList(),
      'dietNames': _diets.where((d) => _selectedDietIds.contains(d.id)).map((d) => d.name).toList(),
      'foodTypeNames': _foodTypes.where((f) => _selectedFoodTypeIds.contains(f.id)).map((f) => f.name).toList(),
    };
    Navigator.pop(context, result);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chọn Thuộc Tính')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSection('Khẩu vị', _tastes, _selectedTasteIds),
                  _buildSection('Chế độ ăn', _diets, _selectedDietIds),
                  _buildSection('Loại món ăn', _foodTypes, _selectedFoodTypeIds),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _handleConfirm,
        label: const Text('Xác nhận'),
        icon: const Icon(Icons.check),
      ),
    );
  }
  
  // Helper để build mỗi section (Khẩu vị, Chế độ ăn,...)
  Widget _buildSection(String title, List<AttributeItem> items, Set<String> selectedIds) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8.0,
          runSpacing: 4.0,
          children: items.map((item) {
            final isSelected = selectedIds.contains(item.id);
            return FilterChip(
              label: Text(item.name),
              selected: isSelected,
              onSelected: (bool selected) {
                setState(() {
                  if (selected) {
                    selectedIds.add(item.id);
                  } else {
                    selectedIds.remove(item.id);
                  }
                });
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}