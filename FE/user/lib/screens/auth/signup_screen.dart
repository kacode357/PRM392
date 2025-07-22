import 'dart:ui'; // Import để sử dụng BackdropFilter
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:simple_animations/simple_animations.dart'; // Import gói animation

import 'package:user/components/alert_modal.dart';
import 'package:user/constants/app_colors.dart';
import 'package:user/constants/app_fonts.dart';
import 'package:user/screens/auth/signin_screen.dart';
import 'package:user/services/user_services.dart';
import 'package:user/utils/theme_notifier.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

// Enum để điều khiển animation
enum AniProps { opacity, translateY }

class _SignUpScreenState extends State<SignUpScreen> {
  // --- GIỮ NGUYÊN TOÀN BỘ LOGIC VÀ STATE CỦA BẠN ---
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _userNameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _secureTextEntry = true;
  bool _secureConfirmTextEntry = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _fullNameController.dispose();
    _userNameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _togglePasswordVisibility() {
    setState(() {
      _secureTextEntry = !_secureTextEntry;
    });
  }

  void _toggleConfirmPasswordVisibility() {
    setState(() {
      _secureConfirmTextEntry = !_secureConfirmTextEntry;
    });
  }

  void _dismissKeyboard() {
    FocusScope.of(context).unfocus();
  }

  void _showAlertModal({
    required String title,
    required String message,
    bool? isSuccess,
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertModal(
          visible: true,
          title: title,
          message: message,
          isSuccess: isSuccess,
          onConfirm: () {
            Navigator.of(dialogContext).pop();
            if (onConfirm != null) onConfirm();
          },
          onCancel: onCancel != null
              ? () {
            Navigator.of(dialogContext).pop();
            onCancel();
          }
              : null,
        );
      },
    );
  }

  Future<void> _handleSignup() async {
    _dismissKeyboard();

    final String email = _emailController.text.trim();
    final String fullName = _fullNameController.text.trim();
    final String userName = _userNameController.text.trim();
    final String password = _passwordController.text.trim();
    final String confirmPassword = _confirmPasswordController.text.trim();

    if (email.isEmpty || fullName.isEmpty || userName.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      _showAlertModal(title: 'Lỗi', message: 'Vui lòng điền đầy đủ tất cả các thông tin');
      return;
    }
    if (!RegExp(r'\S+@\S+\.\S+').hasMatch(email)) {
      _showAlertModal(title: 'Lỗi', message: 'Định dạng email không hợp lệ');
      return;
    }
    if (!RegExp(r'^[a-z0-9_-]+$').hasMatch(userName)) {
      _showAlertModal(
          title: 'Lỗi',
          message:
          'Tên đăng nhập chỉ được chứa chữ thường, số, dấu gạch dưới hoặc gạch ngang.');
      return;
    }
    if (password != confirmPassword) {
      _showAlertModal(title: 'Lỗi', message: 'Mật khẩu và xác nhận mật khẩu không khớp');
      return;
    }
    if (password.length < 6) {
      _showAlertModal(title: 'Lỗi', message: 'Mật khẩu phải có ít nhất 6 ký tự');
      return;
    }
    if (!RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&;])[A-Za-z\d@$!%*?&;]+$').hasMatch(password)) {
      _showAlertModal(
          title: 'Lỗi',
          message:
          'Mật khẩu phải chứa ít nhất một chữ hoa, một chữ thường, một số và một ký tự đặc biệt.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await UserServices.createUserApi(
        fullName: fullName,
        email: email,
        userName: userName,
        password: password,
      );
      _showAlertModal(
        title: 'Thành công',
        message: 'Tài khoản của bạn đã được tạo thành công! Vui lòng đăng nhập.',
        isSuccess: true,
        onConfirm: () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const SignInScreen()),
          );
        },
      );
    } catch (error) {
      debugPrint('Signup error: $error');
      _showAlertModal(title: 'Lỗi', message: 'Đã có lỗi xảy ra. Tên đăng nhập hoặc email có thể đã tồn tại.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // --- KẾT THÚC PHẦN LOGIC ---

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final isDarkMode = themeNotifier.colorSchemeString == 'dark';

    // Timeline cho animation
    final tween = MovieTween()
      ..tween(AniProps.opacity, Tween<double>(begin: 0.0, end: 1.0), duration: const Duration(milliseconds: 500))
      ..tween(AniProps.translateY, Tween<double>(begin: 30.0, end: 0.0), duration: const Duration(milliseconds: 500), curve: Curves.easeOut);

    return GestureDetector(
      onTap: _dismissKeyboard,
      child: Scaffold(
        body: Container(
          // Nền Gradient đồng bộ với màn hình Đăng nhập
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isDarkMode
                  ? [AppColors.darkBackground, Color(0xFF1a2333)]
                  : [Color(0xFFE0E0E0), Color(0xFFFFA751)]
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: PlayAnimationBuilder<Movie>(
                tween: tween,
                duration: tween.duration,
                builder: (context, value, child) {
                  return Opacity(
                    opacity: value.get(AniProps.opacity),
                    child: Transform.translate(
                      offset: Offset(0, value.get(AniProps.translateY)),
                      child: child,
                    ),
                  );
                },
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    const SizedBox(height: 20),
                    // Hero animation cho logo để chuyển cảnh mượt mà
                    Hero(
                      tag: 'appLogo',
                      child: Image.asset('assets/images/logo-mm-final-2.png', height: 80),
                    ),
                    const SizedBox(height: 15),

                    // Tiêu đề
                    Text(
                      'Tạo tài khoản mới',
                      textAlign: TextAlign.center,
                      style: AppFonts.baloo2ExtraBold.copyWith(fontSize: 28, color: Colors.white),
                    ),
                    Text(
                      'Bắt đầu hành trình của bạn với chúng tôi',
                      textAlign: TextAlign.center,
                      style: AppFonts.comfortaaRegular.copyWith(fontSize: 16, color: Colors.white.withOpacity(0.8)),
                    ),
                    const SizedBox(height: 30),

                    // Các trường nhập liệu
                    _buildGlassmorphismTextField(controller: _fullNameController, hintText: 'Họ và tên', icon: Icons.badge_outlined, isDarkMode: isDarkMode),
                    const SizedBox(height: 16),
                    _buildGlassmorphismTextField(controller: _emailController, hintText: 'Email', icon: Icons.email_outlined, isDarkMode: isDarkMode, keyboardType: TextInputType.emailAddress),
                    const SizedBox(height: 16),
                    _buildGlassmorphismTextField(controller: _userNameController, hintText: 'Tên đăng nhập', icon: Icons.person_outline, isDarkMode: isDarkMode),
                    const SizedBox(height: 16),
                    _buildGlassmorphismTextField(
                      controller: _passwordController,
                      hintText: 'Mật khẩu',
                      icon: Icons.lock_outline,
                      isDarkMode: isDarkMode,
                      obscureText: _secureTextEntry,
                      suffixIcon: IconButton(
                        icon: Icon(_secureTextEntry ? Icons.visibility_off : Icons.visibility, color: Colors.white70),
                        onPressed: _togglePasswordVisibility,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildGlassmorphismTextField(
                      controller: _confirmPasswordController,
                      hintText: 'Xác nhận mật khẩu',
                      icon: Icons.lock_outline,
                      isDarkMode: isDarkMode,
                      obscureText: _secureConfirmTextEntry,
                      suffixIcon: IconButton(
                        icon: Icon(_secureConfirmTextEntry ? Icons.visibility_off : Icons.visibility, color: Colors.white70),
                        onPressed: _toggleConfirmPasswordVisibility,
                      ),
                    ),
                    const SizedBox(height: 25),

                    // Nút Đăng ký
                    _buildSignUpButton(),
                    const SizedBox(height: 25),

                    // Link quay lại Đăng nhập
                    _buildSignInLink(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Widget con cho Ô nhập liệu (hiệu ứng kính mờ) - Tái sử dụng thiết kế
  Widget _buildGlassmorphismTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    required bool isDarkMode,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(15.0),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
        child: Container(
          decoration: BoxDecoration(
            color: isDarkMode ? Colors.white.withOpacity(0.1) : Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(15.0),
            border: Border.all(width: 1.5, color: Colors.white.withOpacity(0.2)),
          ),
          child: TextField(
            controller: controller,
            obscureText: obscureText,
            enabled: !_isLoading,
            keyboardType: keyboardType,
            style: AppFonts.comfortaaRegular.copyWith(color: Colors.white, fontSize: 16),
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: Colors.white70),
              suffixIcon: suffixIcon,
              hintText: hintText,
              hintStyle: AppFonts.comfortaaRegular.copyWith(color: Colors.white70),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 20.0),
            ),
          ),
        ),
      ),
    );
  }

  // Widget con cho nút Đăng ký
  Widget _buildSignUpButton() {
    return GestureDetector(
      onTap: _isLoading ? null : _handleSignup,
      child: Container(
        height: 60,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              spreadRadius: 2,
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: _isLoading
            ? const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(AppColors.lightPrimaryText))
            : Text(
          'Đăng ký',
          style: AppFonts.comfortaaBold.copyWith(fontSize: 18, color: AppColors.lightPrimaryText),
        ),
      ),
    );
  }

  // Widget con cho link quay lại Đăng nhập
  Widget _buildSignInLink() {
    return GestureDetector(
      onTap: () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const SignInScreen()),
        );
      },
      child: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          style: AppFonts.comfortaaRegular.copyWith(fontSize: 16, color: Colors.white.withOpacity(0.8)),
          children: [
            const TextSpan(text: 'Bạn đã có tài khoản? '),
            TextSpan(
              text: 'Đăng nhập tại đây',
              style: AppFonts.comfortaaBold.copyWith(
                color: Colors.white,
                decoration: TextDecoration.underline,
                decorationColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}