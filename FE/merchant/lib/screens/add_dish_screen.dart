// lib/screens/add_dish_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:merchant/models/dish.dart';
import 'package:merchant/screens/edit_dish_screen.dart';
import 'package:merchant/services/dish_services.dart';
import 'package:merchant/utils/image_uploader.dart';

class AddDishScreen extends StatefulWidget {
  final String restaurantId;
  const AddDishScreen({super.key, required this.restaurantId});

  @override
  State<AddDishScreen> createState() => _AddDishScreenState();
}

class _AddDishScreenState extends State<AddDishScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  
  String? _imageUrl;
  bool _isSubmitting = false;
  bool _isUploading = false;
  
  List<Dish> _dishes = [];
  bool _isLoadingDishes = true;

  @override
  void initState() {
    super.initState();
    _fetchDishes();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _fetchDishes() async {
    setState(() { _isLoadingDishes = true; });
    try {
      final response = await DishServices.getDishesBySnackPlaceApi(snackPlaceId: widget.restaurantId);
      if (response.status == 200 && response.data != null) {
        final List<dynamic> rawData = response.data;
        if (mounted) {
          setState(() {
            _dishes = rawData.map((json) => Dish.fromJson(json)).toList();
          });
        }
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi tải danh sách món ăn: $e')));
    } finally {
      if (mounted) setState(() { _isLoadingDishes = false; });
    }
  }

  Future<void> _pickImage() async {
    setState(() { _isUploading = true; });
    final url = await ImageUploader.uploadImage();
    if (url != null) {
      setState(() { _imageUrl = url; });
    }
    setState(() { _isUploading = false; });
  }

  Future<void> _handleSubmit() async {
    // Thêm check _isUploading ở đây để chắc chắn
    if (!_formKey.currentState!.validate() || _isUploading) return;
    if (_imageUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng chọn ảnh cho món ăn.')));
      return;
    }
    setState(() { _isSubmitting = true; });
    try {
      await DishServices.createDishApi(
        name: _nameController.text,
        description: _descriptionController.text,
        image: _imageUrl!,
        price: num.parse(_priceController.text),
        snackPlaceId: widget.restaurantId,
      );
      _formKey.currentState?.reset();
      _nameController.clear();
      _descriptionController.clear();
      _priceController.clear();
      setState(() { _imageUrl = null; });
      await _fetchDishes();
    } catch (e) {
      // Interceptor đã xử lý toast
    } finally {
      if (mounted) setState(() { _isSubmitting = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quản Lý Món Ăn')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDishForm(),
              const SizedBox(height: 24),
              const Text('Danh sách món ăn', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const Divider(),
              _buildDishesList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDishForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(controller: _nameController, decoration: const InputDecoration(labelText: 'Tên món ăn'), validator: (v) => v!.isEmpty ? 'Không được bỏ trống' : null),
          TextFormField(controller: _descriptionController, decoration: const InputDecoration(labelText: 'Mô tả')),
          TextFormField(controller: _priceController, decoration: const InputDecoration(labelText: 'Giá (VND)'), keyboardType: TextInputType.number, validator: (v) => v!.isEmpty ? 'Không được bỏ trống' : null),
          const SizedBox(height: 16),
          Row(
            children: [
              OutlinedButton.icon(onPressed: _isUploading || _isSubmitting ? null : _pickImage, icon: _isUploading ? const SizedBox(width:18, height:18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.image), label: const Text('Chọn ảnh')),
              const SizedBox(width: 16),
              if (_imageUrl != null) Image.network(_imageUrl!, width: 50, height: 50, fit: BoxFit.cover),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              // >>> SỬA Ở ĐÂY: Thêm điều kiện || _isUploading <<<
              onPressed: _isSubmitting || _isUploading ? null : _handleSubmit,
              child: _isSubmitting 
                  ? const SizedBox(width:20, height:20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                  : _isUploading 
                      ? const Text('Đang tải ảnh...') 
                      : const Text('Thêm Món'),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildDishesList() {
    if (_isLoadingDishes) return const Center(child: Padding(padding: EdgeInsets.all(32.0), child: CircularProgressIndicator()));
    if (_dishes.isEmpty) return const Center(child: Padding(padding: EdgeInsets.all(32.0), child: Text('Chưa có món ăn nào.')));

    final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'VND');

    return ListView.builder(
      itemCount: _dishes.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        final dish = _dishes[index];
        return Card(
          margin: const EdgeInsets.only(top: 8.0),
          child: ListTile(
            leading: dish.image.isNotEmpty ? Image.network(dish.image, width: 50, height: 50, fit: BoxFit.cover) : const SizedBox(width: 50, height: 50, child: Icon(Icons.no_photography)),
            title: Text(dish.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(dish.description),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(currencyFormatter.format(dish.price), style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4), 
                InkWell(
                  onTap: () async {
                    final result = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => EditDishScreen(dish: dish)));
                    if (result == true) { _fetchDishes(); }
                  },
                  child: const Icon(Icons.edit, size: 20, color: Colors.grey),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}