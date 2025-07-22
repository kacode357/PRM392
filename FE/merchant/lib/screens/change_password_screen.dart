import 'package:flutter/material.dart';
import 'package:merchant/components/alert_modal.dart';
import 'package:merchant/constants/app_colors.dart';
import 'package:merchant/constants/app_fonts.dart';
import 'package:merchant/services/user_services.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _showCurrentPassword = false;
  bool _showNewPassword = false;
  bool _showConfirmPassword = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _showModal({required String title, required String message, bool isSuccess = false}) {
    showDialog(
      context: context,
      builder: (ctx) => AlertModal(
        visible: true,
        title: title,
        message: message,
        isSuccess: isSuccess,
        onConfirm: () => Navigator.of(ctx).pop(),
      ),
    );
  }

  Future<void> _handleChangePassword() async {
    final currentPassword = _currentPasswordController.text;
    final newPassword = _newPasswordController.text;
    final confirmPassword = _confirmPasswordController.text;

    // --- Validation ---
    if (currentPassword.isEmpty || newPassword.isEmpty || confirmPassword.isEmpty) {
      _showModal(title: 'Lỗi', message: 'Vui lòng điền đầy đủ tất cả các thông tin');
      return;
    }
    if (newPassword != confirmPassword) {
      _showModal(title: 'Lỗi', message: 'Mật khẩu mới và xác nhận mật khẩu không khớp');
      return;
    }
    if (newPassword.length < 8) {
      _showModal(title: 'Lỗi', message: 'Mật khẩu mới phải có ít nhất 8 ký tự');
      return;
    }
    if (!RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&;])[A-Za-z\d@$!%*?&;]+$').hasMatch(newPassword)) {
      _showModal(
        title: 'Lỗi',
        message: 'Mật khẩu mới phải chứa ít nhất một chữ cái viết hoa, một chữ cái viết thường, một số và một ký tự đặc biệt',
      );
      return;
    }
    // --- End Validation ---

    setState(() => _isLoading = true);
    try {
      await UserServices.changePasswordApi(
        oldPassword: currentPassword,
        newPassword: newPassword,
      );
      // Đổi mật khẩu thành công
      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();
      _showModal(
        title: 'Thành công',
        message: 'Bạn đã đổi mật khẩu thành công!',
        isSuccess: true,
      );
    } catch (e) {
      // Lỗi sẽ được interceptor xử lý và hiển thị toast
      debugPrint('Lỗi đổi mật khẩu: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Đổi mật khẩu')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildPasswordField(
              label: 'Mật khẩu hiện tại',
              controller: _currentPasswordController,
              isObscured: !_showCurrentPassword,
              onToggleVisibility: () => setState(() => _showCurrentPassword = !_showCurrentPassword),
            ),
            _buildPasswordField(
              label: 'Mật khẩu mới',
              controller: _newPasswordController,
              isObscured: !_showNewPassword,
              onToggleVisibility: () => setState(() => _showNewPassword = !_showNewPassword),
            ),
            _buildPasswordField(
              label: 'Xác nhận mật khẩu mới',
              controller: _confirmPasswordController,
              isObscured: !_showConfirmPassword,
              onToggleVisibility: () => setState(() => _showConfirmPassword = !_showConfirmPassword),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading ? null : _handleChangePassword,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.lightTabBackground,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: _isLoading 
                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white)) 
                : const Text('Đổi mật khẩu'),
            ),
          ],
        ),
      ),
    );
  }

  // Widget helper cho gọn
  Widget _buildPasswordField({
    required String label,
    required TextEditingController controller,
    required bool isObscured,
    required VoidCallback onToggleVisibility,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppFonts.comfortaaRegular.copyWith(fontSize: 14)),
          const SizedBox(height: 5),
          TextField(
            controller: controller,
            obscureText: isObscured,
            enabled: !_isLoading,
            decoration: InputDecoration(
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              suffixIcon: IconButton(
                icon: Icon(isObscured ? Icons.visibility_off : Icons.visibility),
                onPressed: onToggleVisibility,
              ),
            ),
          ),
        ],
      ),
    );
  }
}