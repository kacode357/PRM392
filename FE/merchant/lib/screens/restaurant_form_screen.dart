// lib/screens/restaurant_form_screen.dart
import 'package:flutter/material.dart';
import 'package:merchant/config/dio_customize.dart';
import 'package:merchant/models/business_model.dart';
import 'package:merchant/screens/select_business_model_screen.dart';
import 'package:merchant/screens/select_attributes_screen.dart';
import 'package:merchant/services/snackplace_services.dart';
import 'package:merchant/utils/image_uploader.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RestaurantFormScreen extends StatefulWidget {
  final String? restaurantId;

  const RestaurantFormScreen({super.key, this.restaurantId});

  @override
  State<RestaurantFormScreen> createState() => _RestaurantFormScreenState();
}

class _RestaurantFormScreenState extends State<RestaurantFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final bool _isEditMode;
  bool _isLoading = false;
  bool _isUploading = false;

  // Controllers
  final _placeNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _averagePriceController = TextEditingController();
  final _mainDishController = TextEditingController();
  final _phoneController = TextEditingController();
  final _coordinatesController = TextEditingController();

  // State
  String? _userId;
  String _ownerName = '';
  String _email = '';
  String? _imageUrl;
  TimeOfDay? _openingTime;
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
    _isEditMode = widget.restaurantId != null;

    if (_isEditMode) {
      _loadRestaurantData();
    } else {
      _loadUserData();
    }
  }

  @override
  void dispose() {
    _placeNameController.dispose();
    _addressController.dispose();
    _descriptionController.dispose();
    _averagePriceController.dispose();
    _mainDishController.dispose();
    _phoneController.dispose();
    _coordinatesController.dispose();
    super.dispose();
  }

  Future<void> _loadRestaurantData() async {
    setState(() { _isLoading = true; });
    try {
      final response = await SnackPlaceServices.getSnackPlaceByIdApi(id: widget.restaurantId!);
      if (mounted && response.status == 200 && response.data != null) {
        final data = response.data;
        setState(() {
          _placeNameController.text = data['placeName'] ?? '';
          _addressController.text = data['address'] ?? '';
          _descriptionController.text = data['description'] ?? '';
          _averagePriceController.text = (data['averagePrice'] ?? 0).toString();
          _mainDishController.text = data['mainDish'] ?? '';
          _phoneController.text = data['phoneNumber'] ?? '';
          _coordinatesController.text = data['coordinates'] ?? '';
          _imageUrl = data['image'];
          _businessModelId = data['businessModelId'];
          _businessModelName = data['businessModelName'] ?? '';

          final timeParts = (data['openingHour'] ?? '00:00').split(':');
          _openingTime = TimeOfDay(hour: int.parse(timeParts[0]), minute: int.parse(timeParts[1]));

          final attributes = data['attributes'] as Map<String, dynamic>? ?? {};
          _tasteIds = List<String>.from(attributes['tastes']?.map((t) => t['tasteId']) ?? []);
          _dietIds = List<String>.from(attributes['diets']?.map((d) => d['dietId']) ?? []);
          _foodTypeIds = List<String>.from(attributes['foodTypes']?.map((f) => f['foodTypeId']) ?? []);
          _tasteNames = List<String>.from(attributes['tastes']?.map((t) => t['tasteName']) ?? []);
          _dietNames = List<String>.from(attributes['diets']?.map((d) => d['dietName']) ?? []);
          _foodTypeNames = List<String>.from(attributes['foodTypes']?.map((f) => f['foodTypeName']) ?? []);
        });
      }
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi tải dữ liệu quán: $e')));
    } finally {
      if(mounted) setState(() { _isLoading = false; });
    }
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userId = prefs.getString("user_id");
      _ownerName = prefs.getString("user_name") ?? '';
      _email = prefs.getString("user_email") ?? '';
    });
  }

  Future<void> _pickImage() async {
    setState(() { _isUploading = true; });
    final url = await ImageUploader.uploadImage();
    if (url != null) {
      setState(() { _imageUrl = url; });
    }
    setState(() { _isUploading = false; });
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(context: context, initialTime: _openingTime ?? TimeOfDay.now());
    if (picked != null) setState(() { _openingTime = picked; });
  }

  Future<void> _selectBusinessModel() async {
    final result = await Navigator.push<BusinessModel>(context, MaterialPageRoute(builder: (context) => const SelectBusinessModelScreen()));
    if (result != null) setState(() {
      _businessModelId = result.id;
      _businessModelName = result.name;
    });
  }

  Future<void> _selectAttributes() async {
    final result = await Navigator.push<Map<String, List>>(context, MaterialPageRoute(builder: (context) => SelectAttributesScreen(
      initialTasteIds: _tasteIds,
      initialDietIds: _dietIds,
      initialFoodTypeIds: _foodTypeIds,
    )));
    if (result != null) setState(() {
      _tasteIds = List<String>.from(result['tasteIds']!);
      _dietIds = List<String>.from(result['dietIds']!);
      _foodTypeIds = List<String>.from(result['foodTypeIds']!);
      _tasteNames = List<String>.from(result['tasteNames']!);
      _dietNames = List<String>.from(result['dietNames']!);
      _foodTypeNames = List<String>.from(result['foodTypeNames']!);
    });
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate() || _isLoading || _isUploading) return;
    if (_imageUrl == null || _businessModelId == null || _openingTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng điền đủ ảnh, giờ mở cửa và mô hình kinh doanh.')));
      return;
    }
    setState(() { _isLoading = true; });

    try {
      ApiResponse response;
      if (_isEditMode) {
        response = await SnackPlaceServices.updateSnackPlaceApi(
          snackPlaceId: widget.restaurantId!,
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
          description: _descriptionController.text,
        );
      } else {
        response = await SnackPlaceServices.createSnackPlaceApi(
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
          description: _descriptionController.text,
        );
      }

      if (mounted && (response.status == 200 || response.status == 201)) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      print('Error in _handleSubmit: $e');
    } finally {
      if(mounted) setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Sửa Quán Ăn' : 'Tạo Quán Ăn Mới'),
        actions: [ if (_isLoading) const Padding(padding: EdgeInsets.only(right: 16.0), child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)))) ],
      ),
      // THAY ĐỔI: Bọc toàn bộ body bằng SafeArea
      body: SafeArea(
        child: _isLoading && _placeNameController.text.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildImagePicker(),
                const SizedBox(height: 24),
                TextFormField(controller: _placeNameController, decoration: const InputDecoration(labelText: 'Tên quán ăn (*)', border: OutlineInputBorder()), validator: (v) => v!.isEmpty ? 'Không được bỏ trống' : null),
                const SizedBox(height: 16),
                TextFormField(controller: _addressController, decoration: const InputDecoration(labelText: 'Địa chỉ (*)', border: OutlineInputBorder()), validator: (v) => v!.isEmpty ? 'Không được bỏ trống' : null),
                const SizedBox(height: 16),
                TextFormField(controller: _descriptionController, decoration: const InputDecoration(labelText: 'Mô tả quán', border: OutlineInputBorder()), maxLines: 3),
                const SizedBox(height: 16),
                TextFormField(controller: _averagePriceController, decoration: const InputDecoration(labelText: 'Giá trung bình (*)', border: OutlineInputBorder()), keyboardType: TextInputType.number, validator: (v) => v!.isEmpty ? 'Không được bỏ trống' : null),
                const SizedBox(height: 16),
                TextFormField(controller: _mainDishController, decoration: const InputDecoration(labelText: 'Món chính (*)', border: OutlineInputBorder()), validator: (v) => v!.isEmpty ? 'Không được bỏ trống' : null),
                const SizedBox(height: 16),
                TextFormField(controller: _phoneController, decoration: const InputDecoration(labelText: 'Số điện thoại (*)', border: OutlineInputBorder()), keyboardType: TextInputType.phone, validator: (v) => v!.isEmpty ? 'Không được bỏ trống' : null),
                const SizedBox(height: 16),
                TextFormField(controller: _coordinatesController, decoration: const InputDecoration(labelText: 'Tọa độ (lat,lng)', border: OutlineInputBorder())),
                const SizedBox(height: 16),

                _buildPickerRow('Giờ mở cửa (*):', _openingTime?.format(context) ?? 'Chưa chọn', _selectTime),
                const Divider(),
                _buildPickerRow('Mô hình kinh doanh (*):', _businessModelName.isEmpty ? 'Chưa chọn' : _businessModelName, _selectBusinessModel),
                const Divider(),
                _buildPickerRow('Thuộc tính món ăn:', 'Đã chọn ${_tasteNames.length}, ${_dietNames.length}, ${_foodTypeNames.length} mục', _selectAttributes),

                if (_tasteNames.isNotEmpty || _dietNames.isNotEmpty || _foodTypeNames.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text('Đã chọn: ${_tasteNames.join(', ')}, ${_dietNames.join(', ')}, ${_foodTypeNames.join(', ')}'),
                  ),

                const SizedBox(height: 32),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                  onPressed: _isLoading || _isUploading ? null : _handleSubmit,
                  child: Text(_isEditMode ? 'Cập Nhật Quán Ăn' : 'Tạo Quán Ăn'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImagePicker() {
    return Center(
      child: Column(
        children: [
          Container(
            height: 150,
            width: double.infinity,
            decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(8)),
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (_imageUrl != null)
                  ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(_imageUrl!, width: double.infinity, height: 150, fit: BoxFit.cover))
                else
                  const Icon(Icons.image_search, size: 50, color: Colors.grey),
                if (_isUploading)
                  const CircularProgressIndicator(),
              ],
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: _isUploading || _isLoading ? null : _pickImage,
            icon: const Icon(Icons.upload_file),
            label: const Text('Tải ảnh lên'),
          ),
        ],
      ),
    );
  }

  Widget _buildPickerRow(String label, String value, VoidCallback onTap) {
    return InkWell(
      onTap: _isLoading || _isUploading ? null : onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Row(
              children: [
                Text(
                  value,
                  style: const TextStyle(fontSize: 16, color: Colors.blue),
                ),
                const Icon(Icons.chevron_right, color: Colors.grey),
              ],
            ),
          ],
        ),
      ),
    );
  }
}