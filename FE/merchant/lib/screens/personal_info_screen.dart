import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:merchant/components/alert_modal.dart';
import 'package:merchant/constants/app_colors.dart';
import 'package:merchant/constants/app_fonts.dart';
import 'package:merchant/services/user_services.dart';
import 'package:merchant/utils/image_uploader.dart'; // Import tiện ích vừa tạo

// Class để chứa dữ liệu user
class UserData {
  String id;
  String phoneNumber;
  String fullname;
  String? image;
  String? dateOfBirth;

  UserData({
    required this.id,
    required this.phoneNumber,
    required this.fullname,
    this.image,
    this.dateOfBirth,
  });
}

class PersonalInfoScreen extends StatefulWidget {
  const PersonalInfoScreen({super.key});

  @override
  State<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends State<PersonalInfoScreen> {
  bool _isLoading = true;
  UserData? _userData;

  late TextEditingController _fullNameController;
  late TextEditingController _phoneController;

  // Biến tạm để lưu trạng thái gốc khi bắt đầu chỉnh sửa
  UserData? _originalUserData;

  bool _isEditing = false;
  bool _isUploading = false;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController();
    _phoneController = TextEditingController();
    _fetchUserData();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _fetchUserData() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');
      if (userId == null) throw Exception('Không tìm thấy User ID');

      final response = await UserServices.getUserByIdApi(id: userId);
      final data = response.data;
      
      _userData = UserData(
        id: data['id'],
        phoneNumber: data['phoneNumber'] ?? '',
        fullname: data['fullname'] ?? '',
        image: data['image'],
        dateOfBirth: data['dateOfBirth'],
      );
      
      // Gán dữ liệu vào controllers
      _fullNameController.text = _userData!.fullname;
      _phoneController.text = _userData!.phoneNumber;

    } catch (e) {
      _showErrorModal('Không thể tải thông tin. Vui lòng thử lại.');
    } finally {
      if(mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleImageUpload() async {
    setState(() => _isUploading = true);
    final imageUrl = await ImageUploader.uploadImage();
    if (imageUrl != null) {
      setState(() {
        _userData?.image = imageUrl;
      });
    } else {
      _showErrorModal('Tải ảnh lên thất bại.');
    }
    setState(() => _isUploading = false);
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _userData?.dateOfBirth != null ? DateTime.parse(_userData!.dateOfBirth!) : DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _userData?.dateOfBirth = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  // =================================================================
  // ===== CẬP NHẬT LOGIC VALIDATION TẠI ĐÂY =====
  // =================================================================
  Future<void> _handleUpdate() async {
    // 1. Kiểm tra họ tên có trống không
    if (_fullNameController.text.trim().isEmpty) {
      _showErrorModal('Vui lòng nhập họ và tên.');
      return;
    }
    
    // 2. Kiểm tra định dạng số điện thoại
    if (!RegExp(r'^\d{10}$').hasMatch(_phoneController.text)) {
      _showErrorModal('Số điện thoại phải có đúng 10 chữ số.');
      return;
    }

    // 3. Kiểm tra ngày sinh đã được chọn chưa
    if (_userData?.dateOfBirth == null) {
      _showErrorModal('Vui lòng chọn ngày sinh.');
      return;
    }

    setState(() => _isUpdating = true);
    try {
      final updatedData = UserData(
        id: _userData!.id,
        fullname: _fullNameController.text.trim(),
        phoneNumber: _phoneController.text,
        image: _userData!.image,
        dateOfBirth: _userData!.dateOfBirth,
      );
      
      await UserServices.updateUserApi(
          id: updatedData.id,
          phoneNumber: updatedData.phoneNumber,
          fullname: updatedData.fullname,
          image: updatedData.image ?? '',
          dateOfBirth: updatedData.dateOfBirth ?? '',
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_fullname', updatedData.fullname);

      setState(() {
        _isEditing = false;
        _userData = updatedData; // Cập nhật dữ liệu chính
      });

    } catch (e) {
      _showErrorModal('Cập nhật thất bại. Vui lòng thử lại.');
    } finally {
      if(mounted) setState(() => _isUpdating = false);
    }
  }
  
  void _showErrorModal(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertModal(
        visible: true,
        title: 'Thông báo',
        message: message,
        onConfirm: () => Navigator.of(ctx).pop(),
      ),
    );
  }

  // =================================================================
  // ===== THÊM HÀM MỚI VÀ CẬP NHẬT NÚT BẤM =====
  // =================================================================
  
  // Hàm để bật/tắt chế độ chỉnh sửa
  void _toggleEditMode(bool isEditing) {
    setState(() {
      _isEditing = isEditing;
      if (isEditing) {
        // Lưu lại trạng thái gốc khi bắt đầu sửa
        _originalUserData = UserData(
            id: _userData!.id,
            phoneNumber: _userData!.phoneNumber,
            fullname: _userData!.fullname,
            image: _userData!.image,
            dateOfBirth: _userData!.dateOfBirth,
        );
      }
    });
  }

  // Hàm để hủy bỏ chỉnh sửa và khôi phục dữ liệu gốc
  void _cancelEditing() {
    setState(() {
      if (_originalUserData != null) {
        _userData = _originalUserData; // Khôi phục dữ liệu
        _fullNameController.text = _originalUserData!.fullname;
        _phoneController.text = _originalUserData!.phoneNumber;
      }
      _isEditing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Thông tin cá nhân')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildForm(),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: GestureDetector(
              onTap: _isEditing ? _handleImageUpload : null,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.lightPrimaryText, style: BorderStyle.solid, width: 2),
                      borderRadius: BorderRadius.circular(60),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(60),
                      child: _userData?.image != null
                          ? Image.network(_userData!.image!, fit: BoxFit.cover, width: 120, height: 120,
                              errorBuilder: (context, error, stackTrace) => const Icon(Icons.person, size: 60, color: AppColors.lightIcon),)
                          : const Icon(Icons.person, size: 60, color: AppColors.lightIcon),
                    ),
                  ),
                  if (_isUploading) const CircularProgressIndicator(),
                  if (_isEditing) Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: AppColors.lightPrimaryText,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.edit, color: Colors.white, size: 20),
                    ),
                  )
                ],
              ),
            ),
          ),
          const SizedBox(height: 30),
          _buildTextField(label: 'Họ và Tên', controller: _fullNameController),
          _buildTextField(label: 'Số Điện Thoại', controller: _phoneController, keyboardType: TextInputType.phone, maxLength: 10),
          _buildDateField(),
          const SizedBox(height: 20),
          _buildButtons(),
        ],
      ),
    );
  }

  Widget _buildTextField({required String label, required TextEditingController controller, TextInputType? keyboardType, int? maxLength}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppFonts.comfortaaMedium.copyWith(fontSize: 16)),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            enabled: _isEditing,
            keyboardType: keyboardType,
            maxLength: maxLength,
            decoration: InputDecoration(
              filled: true,
              fillColor: _isEditing ? Colors.white : AppColors.lightGrayBackground,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              counterText: '',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateField() {
    final displayDate = _userData?.dateOfBirth != null
        ? DateFormat('dd/MM/yyyy').format(DateTime.parse(_userData!.dateOfBirth!))
        : 'Chưa có';

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Ngày Sinh', style: AppFonts.comfortaaMedium.copyWith(fontSize: 16)),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _isEditing ? _selectDate : null,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              decoration: BoxDecoration(
                color: _isEditing ? Colors.white : AppColors.lightGrayBackground,
                border: Border.all(color: Colors.grey.shade400),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                displayDate,
                style: TextStyle(
                  fontSize: 16,
                  color: _userData?.dateOfBirth != null ? Colors.black : Colors.grey.shade600,
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
  
  Widget _buildButtons() {
    final bool canInteract = !_isUpdating && !_isUploading;

    if (_isEditing) {
      return Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: canInteract ? _handleUpdate : null,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.lightPrimaryText, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14)),
              child: _isUpdating ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3,)) : const Text('Lưu thay đổi'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: OutlinedButton(
              onPressed: canInteract ? _cancelEditing : null, // Sử dụng hàm hủy mới
              style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
              child: const Text('Hủy'),
            ),
          ),
        ],
      );
    } else {
      return Center(
        child: ElevatedButton(
          onPressed: () => _toggleEditMode(true), // Sử dụng hàm bật/tắt mới
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.lightPrimaryText, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14)),
          child: const Text('Chỉnh Sửa Thông Tin'),
        ),
      );
    }
  }
}