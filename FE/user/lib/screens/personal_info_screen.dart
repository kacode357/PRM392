import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:user/components/alert_modal.dart';
import 'package:user/constants/app_colors.dart';
import 'package:user/constants/app_fonts.dart';
import 'package:user/services/user_services.dart';
import 'package:user/utils/image_uploader.dart';

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
  // BƯỚC 1: Thêm GlobalKey cho Form
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = true;
  UserData? _userData;

  late TextEditingController _fullNameController;
  late TextEditingController _phoneController;

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

  // BƯỚC 5: Cập nhật hàm _handleUpdate để dùng Form validation
  Future<void> _handleUpdate() async {
    // Chạy tất cả các validator trong Form.
    // Nếu có bất kỳ lỗi nào, `validate()` trả về false và tự động hiển thị lỗi trên UI.
    final bool isFormValid = _formKey.currentState!.validate();

    // Kiểm tra các trường không nằm trong Form (ví dụ: Ngày sinh)
    if (_userData?.dateOfBirth == null) {
      _showErrorModal('Vui lòng chọn Ngày Sinh của bạn.');
      return;
    }

    // Nếu form hoặc các trường khác không hợp lệ, dừng lại.
    if (!isFormValid) {
      return;
    }

    // Nếu tất cả đều hợp lệ, tiến hành cập nhật
    setState(() => _isUpdating = true);
    try {
      final updatedData = UserData(
        id: _userData!.id,
        fullname: _fullNameController.text.trim(), // Dùng trim() để xóa khoảng trắng thừa
        phoneNumber: _phoneController.text.trim(),
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
        _userData = updatedData;
      });

    } catch (e) {
      _showErrorModal('Cập nhật thất bại. Vui lòng thử lại.');
    } finally {
      if(mounted) setState(() => _isUpdating = false);
    }
  }

  void _showErrorModal(String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertModal(
        visible: true,
        title: 'Lỗi',
        message: message,
        onConfirm: () => Navigator.of(ctx).pop(),
      ),
    );
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
      // BƯỚC 2: Bọc các trường nhập liệu trong Form widget
      child: Form(
        key: _formKey,
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
                            ? Image.network(_userData!.image!, fit: BoxFit.cover, width: 120, height: 120)
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
            // BƯỚC 4: Thêm validator cho từng trường
            _buildTextField(
              label: 'Họ và Tên',
              controller: _fullNameController,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Họ và Tên không được để trống';
                }
                return null;
              },
            ),
            _buildTextField(
              label: 'Số Điện Thoại',
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              maxLength: 10,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Số điện thoại không được để trống';
                }
                if (!RegExp(r'^\d{10}$').hasMatch(value)) {
                  return 'Số điện thoại phải chứa đúng 10 chữ số.';
                }
                return null;
              },
            ),
            _buildDateField(),
            const SizedBox(height: 20),
            _buildButtons(),
          ],
        ),
      ),
    );
  }

  // BƯỚC 3: Chuyển TextField thành TextFormField và thêm tham số validator
  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    TextInputType? keyboardType,
    int? maxLength,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppFonts.comfortaaMedium.copyWith(fontSize: 16)),
          const SizedBox(height: 8),
          TextFormField( // Đổi thành TextFormField
            controller: controller,
            enabled: _isEditing,
            keyboardType: keyboardType,
            maxLength: maxLength,
            validator: validator, // Gán validator
            autovalidateMode: AutovalidateMode.onUserInteraction, // Tự động validate khi người dùng tương tác
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
        : 'Vui lòng chọn ngày sinh'; // Thay đổi text gợi ý

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
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _isEditing ? Colors.white : AppColors.lightGrayBackground,
                border: Border.all(color: Colors.grey),
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
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.lightPrimaryText, foregroundColor: Colors.white),
              child: _isUpdating ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white)) : const Text('Lưu'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: OutlinedButton(
              onPressed: canInteract ? () {
                setState(() {
                  _isEditing = false;
                  // Reset lại dữ liệu ban đầu khi hủy
                  _fullNameController.text = _userData!.fullname;
                  _phoneController.text = _userData!.phoneNumber;
                  _formKey.currentState?.reset();
                });
              } : null,
              child: const Text('Hủy'),
            ),
          ),
        ],
      );
    } else {
      return Center(
        child: ElevatedButton(
          onPressed: () => setState(() => _isEditing = true),
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.lightPrimaryText, foregroundColor: Colors.white),
          child: const Text('Chỉnh Sửa'),
        ),
      );
    }
  }
}