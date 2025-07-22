// lib/screens/create_restaurant_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:merchant/models/business_model.dart';
import 'package:merchant/screens/select_business_model_screen.dart';
import 'package:merchant/screens/select_attributes_screen.dart';
import 'package:merchant/services/snackplace_services.dart';
import 'package:merchant/utils/image_uploader.dart'; // Import uploader của mày
import 'package:shared_preferences/shared_preferences.dart';

class CreateRestaurantScreen extends StatefulWidget {
  const CreateRestaurantScreen({super.key});

  @override
  State<CreateRestaurantScreen> createState() => _CreateRestaurantScreenState();
}

class _CreateRestaurantScreenState extends State<CreateRestaurantScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers cho các text field
  final _placeNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _averagePriceController = TextEditingController();
  final _mainDishController = TextEditingController();
  final _phoneController = TextEditingController();
  final _coordinatesController = TextEditingController(); // Tạm thời nhập tay
  
  // State cho các giá trị khác
  String? _userId;
  String _ownerName = '';
  String _email = '';
  String? _imageUrl;
  bool _isUploading = false;
  TimeOfDay? _openingTime;
  
  // State cho các lựa chọn từ màn hình khác
  String? _businessModelId;
  String _businessModelName = '';
  List<String> _tasteIds = [];
  List<String> _dietIds = [];
  List<String> _foodTypeIds = [];
  List<String> _tasteNames = [];
  List<String> _dietNames = [];
  List<String> _foodTypeNames = [];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userId = prefs.getString("user_id");
      _ownerName = prefs.getString("user_name") ?? '';
      _email = prefs.getString("user_email") ?? '';
    });
  }

  @override
  void dispose() {
    _placeNameController.dispose();
    _addressController.dispose();
    // ... dispose các controller khác
    super.dispose();
  }

  Future<void> _pickImage() async {
    setState(() { _isUploading = true; });
    final url = await ImageUploader.uploadImage();
    setState(() {
      if (url != null) {
        _imageUrl = url;
      }
      _isUploading = false;
    });
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _openingTime ?? TimeOfDay.now(),
    );
    if (picked != null && picked != _openingTime) {
      setState(() {
        _openingTime = picked;
      });
    }
  }

  Future<void> _selectBusinessModel() async {
    // Chờ kết quả trả về từ màn hình chọn
    final result = await Navigator.push<BusinessModel>(
      context,
      MaterialPageRoute(builder: (context) => const SelectBusinessModelScreen()),
    );
    if (result != null) {
      setState(() {
        _businessModelId = result.id;
        _businessModelName = result.name;
      });
    }
  }
  
  Future<void> _selectAttributes() async {
    final result = await Navigator.push<Map<String, List>>(
      context,
      MaterialPageRoute(builder: (context) => SelectAttributesScreen(
        initialTasteIds: _tasteIds,
        initialDietIds: _dietIds,
        initialFoodTypeIds: _foodTypeIds,
      )),
    );
    if (result != null) {
      setState(() {
        _tasteIds = List<String>.from(result['tasteIds']!);
        _dietIds = List<String>.from(result['dietIds']!);
        _foodTypeIds = List<String>.from(result['foodTypeIds']!);
        _tasteNames = List<String>.from(result['tasteNames']!);
        _dietNames = List<String>.from(result['dietNames']!);
        _foodTypeNames = List<String>.from(result['foodTypeNames']!);
      });
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lỗi: không tìm thấy user id.')));
      return;
    }
     if (_imageUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng chọn ảnh cho quán.')));
      return;
    }

    try {
      final response = await SnackPlaceServices.createSnackPlaceApi(
        userId: _userId!,
        placeName: _placeNameController.text,
        ownerName: _ownerName,
        address: _addressController.text,
        email: _email,
        coordinates: _coordinatesController.text,
        openingHour: '${_openingTime!.hour.toString().padLeft(2, '0')}:${_openingTime!.minute.toString().padLeft(2, '0')}:00',
        averagePrice: num.parse(_averagePriceController.text),
        image: _imageUrl!,
        mainDish: _mainDishController.text,
        phoneNumber: _phoneController.text,
        businessModelId: _businessModelId!,
        tasteIds: _tasteIds,
        dietIds: _dietIds,
        foodTypeIds: _foodTypeIds,
        // description: _descriptionController.text, // API của mày chưa có trường này
      );
      
      if (mounted && response.status == 201) { // Thường thì create thành công trả về 201
        Navigator.of(context).pop(); // Quay về trang trước
      }
    } catch (e) {
      // Toast lỗi đã được Interceptor xử lý
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tạo Quán Ăn Mới')),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image Picker
              _buildImagePicker(),
              const SizedBox(height: 16),
              // Các trường text
              TextFormField(controller: _placeNameController, decoration: const InputDecoration(labelText: 'Tên quán ăn'), validator: (v) => v!.isEmpty ? 'Không được bỏ trống' : null),
              TextFormField(controller: _addressController, decoration: const InputDecoration(labelText: 'Địa chỉ'), validator: (v) => v!.isEmpty ? 'Không được bỏ trống' : null),
              TextFormField(controller: _descriptionController, decoration: const InputDecoration(labelText: 'Mô tả'), maxLines: 3),
              TextFormField(controller: _averagePriceController, decoration: const InputDecoration(labelText: 'Giá trung bình'), keyboardType: TextInputType.number, validator: (v) => v!.isEmpty ? 'Không được bỏ trống' : null),
              TextFormField(controller: _mainDishController, decoration: const InputDecoration(labelText: 'Món chính'), validator: (v) => v!.isEmpty ? 'Không được bỏ trống' : null),
              TextFormField(controller: _phoneController, decoration: const InputDecoration(labelText: 'Số điện thoại'), keyboardType: TextInputType.phone, validator: (v) => v!.isEmpty ? 'Không được bỏ trống' : null),
              TextFormField(controller: _coordinatesController, decoration: const InputDecoration(labelText: 'Tọa độ (lat,lng)')),
              const SizedBox(height: 16),
              // Các nút chọn
              _buildPickerRow('Giờ mở cửa:', _openingTime?.format(context) ?? 'Chưa chọn', _selectTime),
              const Divider(),
              _buildPickerRow('Mô hình kinh doanh:', _businessModelName.isEmpty ? 'Chưa chọn' : _businessModelName, _selectBusinessModel),
              const Divider(),
              _buildPickerRow('Thuộc tính món ăn:', 'Đã chọn ${_tasteIds.length + _dietIds.length + _foodTypeIds.length} mục', _selectAttributes),
              // Hiển thị các thuộc tính đã chọn
              if (_tasteNames.isNotEmpty) Text('Khẩu vị: ${_tasteNames.join(', ')}'),
              if (_dietNames.isNotEmpty) Text('Chế độ ăn: ${_dietNames.join(', ')}'),
              if (_foodTypeNames.isNotEmpty) Text('Loại món: ${_foodTypeNames.join(', ')}'),

              const SizedBox(height: 32),
              SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _handleSubmit, child: const Text('Tạo Quán Ăn'))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePicker() => Center(
    child: Column(
      children: [
        Container(
          height: 150,
          width: 150,
          decoration: BoxDecoration(border: Border.all(color: Colors.grey)),
          child: _imageUrl != null ? Image.network(_imageUrl!, fit: BoxFit.cover) : const Icon(Icons.image, size: 50, color: Colors.grey),
        ),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          onPressed: _pickImage,
          icon: _isUploading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.upload_file),
          label: const Text('Tải ảnh lên'),
        ),
      ],
    ),
  );
  
  Widget _buildPickerRow(String label, String value, VoidCallback onTap) => InkWell(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16)),
          Row(
            children: [
              Text(value, style: const TextStyle(fontSize: 16, color: Colors.grey)),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ],
      ),
    ),
  );
}