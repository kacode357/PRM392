// lib/screens/edit_dish_screen.dart
import 'package:flutter/material.dart';
import 'package:merchant/models/dish.dart';
import 'package:merchant/services/dish_services.dart';
import 'package:merchant/utils/image_uploader.dart';

class EditDishScreen extends StatefulWidget {
  final Dish dish;
  const EditDishScreen({super.key, required this.dish});

  @override
  State<EditDishScreen> createState() => _EditDishScreenState();
}

class _EditDishScreenState extends State<EditDishScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceController;

  String? _imageUrl;
  bool _isSubmitting = false;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.dish.name);
    _descriptionController = TextEditingController(text: widget.dish.description);
    _priceController = TextEditingController(text: widget.dish.price.toString());
    _imageUrl = widget.dish.image;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
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
    if (!_formKey.currentState!.validate() || _isUploading) return;
    if (_imageUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng chọn ảnh cho món ăn.')));
      return;
    }
    setState(() { _isSubmitting = true; });
    try {
      await DishServices.updateDishApi(
        dishId: widget.dish.dishId,
        name: _nameController.text,
        description: _descriptionController.text,
        image: _imageUrl!,
        price: num.parse(_priceController.text),
        snackPlaceId: widget.dish.snackPlaceId,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      // Interceptor đã xử lý toast
    } finally {
      if (mounted) setState(() { _isSubmitting = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Sửa Món Ăn: ${widget.dish.name}')),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextFormField(controller: _nameController, decoration: const InputDecoration(labelText: 'Tên món ăn'), validator: (v) => v!.isEmpty ? 'Không được bỏ trống' : null),
              TextFormField(controller: _descriptionController, decoration: const InputDecoration(labelText: 'Mô tả')),
              TextFormField(controller: _priceController, decoration: const InputDecoration(labelText: 'Giá (VND)'), keyboardType: TextInputType.number, validator: (v) => v!.isEmpty ? 'Không được bỏ trống' : null),
              const SizedBox(height: 16),
              Row(
                children: [
                  OutlinedButton.icon(onPressed: _isUploading || _isSubmitting ? null : _pickImage, icon: _isUploading ? const SizedBox(width:18, height:18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.image), label: const Text('Đổi ảnh')),
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
                          : const Text('Cập Nhật Món Ăn'),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}