import 'dart:ui'; // Import để sử dụng BackdropFilter
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simple_animations/simple_animations.dart'; // Import gói animation

import 'package:user/components/alert_modal.dart';
import 'package:user/constants/app_colors.dart';
import 'package:user/constants/app_fonts.dart';
import 'package:user/screens/auth/forgot_password_screen.dart';
import 'package:user/screens/auth/signup_screen.dart';
import 'package:user/screens/home_page.dart';
import 'package:user/services/user_services.dart';
// import 'package:user/styles/app_styles.dart'; // Chúng ta sẽ không cần AppStyles ở đây nữa
import 'package:user/utils/theme_notifier.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

// Enum để điều khiển animation
enum AniProps { opacity, translateY }

class _SignInScreenState extends State<SignInScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _secureTextEntry = true;
  bool _isLoading = false;

  // Giữ nguyên các hàm logic của bạn
  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _togglePasswordVisibility() {
    setState(() {
      _secureTextEntry = !_secureTextEntry;
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

  Future<void> _handleSignIn() async {
    _dismissKeyboard();

    final String userName = _usernameController.text.trim();
    final String password = _passwordController.text.trim();

    if (userName.isEmpty || password.isEmpty) {
      _showAlertModal(
        title: 'Lỗi',
        message: 'Vui lòng điền đầy đủ tên đăng nhập và mật khẩu',
      );
      return;
    }
    if (!RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(userName)) {
      _showAlertModal(
        title: 'Lỗi',
        message: 'Tên đăng nhập chỉ được chứa chữ cái, số, dấu gạch dưới hoặc gạch ngang.',
      );
      return;
    }
    setState(() {
      _isLoading = true;
    });
    try {
      final loginResponse = await UserServices.loginUserApi(userName: userName, password: password);
      final accessToken = loginResponse.data['accessToken'];
      final refreshToken = loginResponse.data['refreshToken'];

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('accessToken', accessToken);
      await prefs.setString('refreshToken', refreshToken);

      final userResponse = await UserServices.getCurrentUserApi();
      final id = userResponse.data['id'];
      final userNameResponse = userResponse.data['userName'];
      final email = userResponse.data['email'];
      final fullname = userResponse.data['fullname'];
      final List<dynamic> roles = userResponse.data['roles'];

      if (roles.isEmpty || roles[0] != 'User') {
        debugPrint('Access denied: User does not have User role');
        _showAlertModal(
          title: 'Truy cập bị từ chối',
          message: 'Bạn không có quyền để đăng nhập vào ứng dụng này.',
        );
        setState(() => _isLoading = false); // Dừng loading nếu bị từ chối
        return;
      }

      await prefs.setString('user_id', id);
      await prefs.setString('user_name', userNameResponse);
      await prefs.setString('user_email', email);
      await prefs.setString('user_fullname', fullname);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomePage()),
      );
    } catch (e) {
      debugPrint('Lỗi khi đăng nhập: $e');
     
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final isDarkMode = themeNotifier.colorSchemeString == 'dark';

    // Timeline cho animation, các widget sẽ xuất hiện lần lượt
    final tween = MovieTween()
      ..tween(AniProps.opacity, Tween<double>(begin: 0.0, end: 1.0), duration: const Duration(milliseconds: 500))
      ..tween(AniProps.translateY, Tween<double>(begin: 30.0, end: 0.0), duration: const Duration(milliseconds: 500), curve: Curves.easeOut);

    return GestureDetector(
      onTap: _dismissKeyboard,
      child: Scaffold(
        body: Container(
          // Thiết kế nền Gradient
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
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top,
                ),
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
                      const SizedBox(height: 40),

                      // Logo Hero
                      Hero(
                        tag: 'appLogo',
                        child: Image.asset(
                          'assets/images/logo-mm-final-2.png',
                          height: 120,
                        ),
                      ),
                      const SizedBox(height: 30),

                      // Tiêu đề
                      Text(
                        'Chào mừng trở lại!',
                        textAlign: TextAlign.center,
                        style: AppFonts.baloo2ExtraBold.copyWith(
                          fontSize: 28,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              blurRadius: 10.0,
                              color: Colors.white.withOpacity(0.3),
                              offset: Offset(2.0, 2.0),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        'Đăng nhập để tiếp tục',
                        textAlign: TextAlign.center,
                        style: AppFonts.comfortaaRegular.copyWith(
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                      const SizedBox(height: 40),

                      // Ô nhập liệu Tên đăng nhập
                      _buildGlassmorphismTextField(
                        controller: _usernameController,
                        hintText: 'Tên đăng nhập',
                        icon: Icons.person_outline,
                        isDarkMode: isDarkMode,
                      ),
                      const SizedBox(height: 20),

                      // Ô nhập liệu Mật khẩu
                      _buildGlassmorphismTextField(
                        controller: _passwordController,
                        hintText: 'Mật khẩu',
                        icon: Icons.lock_outline,
                        isDarkMode: isDarkMode,
                        obscureText: _secureTextEntry,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _secureTextEntry ? Icons.visibility_off : Icons.visibility,
                            color: Colors.white70,
                          ),
                          onPressed: _togglePasswordVisibility,
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Quên mật khẩu
                      Align(
                        alignment: Alignment.centerRight,
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => const ForgotPasswordScreen()));
                          },
                          child: Text(
                            'Quên mật khẩu?',
                            style: AppFonts.comfortaaBold.copyWith(
                              fontSize: 14,
                              color: Colors.white,
                              decoration: TextDecoration.underline,
                              decorationColor: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),

                      // Nút Đăng nhập
                      _buildLoginButton(),
                      const SizedBox(height: 30),

                      // Dòng phân cách
                      _buildDivider(),
                      const SizedBox(height: 20),

                      // Nút đăng nhập mạng xã hội
                      _buildSocialLoginButtons(isDarkMode),
                      const SizedBox(height: 30),

                      // Chuyển đến trang Đăng ký
                      _buildSignUpLink(),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Widget con cho Ô nhập liệu (hiệu ứng kính mờ)
  Widget _buildGlassmorphismTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    required bool isDarkMode,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(15.0),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
        child: Container(
          decoration: BoxDecoration(
            color: isDarkMode
                ? Colors.white.withOpacity(0.1)
                : Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(15.0),
            border: Border.all(width: 1.5, color: Colors.white.withOpacity(0.2)),
          ),
          child: TextField(
            controller: controller,
            obscureText: obscureText,
            enabled: !_isLoading,
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

  // Widget con cho nút Đăng nhập
  Widget _buildLoginButton() {
    return GestureDetector(
      onTap: _isLoading ? null : _handleSignIn,
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
          'Đăng nhập',
          style: AppFonts.comfortaaBold.copyWith(
            fontSize: 18,
            color: AppColors.lightPrimaryText,
          ),
        ),
      ),
    );
  }

  // Widget con cho dòng phân cách
  Widget _buildDivider() {
    return Row(
      children: <Widget>[
        Expanded(child: Divider(color: Colors.white.withOpacity(0.5))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(
            'Hoặc tiếp tục với',
            style: AppFonts.comfortaaRegular.copyWith(
              fontSize: 14,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
        ),
        Expanded(child: Divider(color: Colors.white.withOpacity(0.5))),
      ],
    );
  }

  // Widget con cho các nút mạng xã hội
  Widget _buildSocialLoginButtons(bool isDarkMode) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        _buildSocialButton(FontAwesomeIcons.apple, isDarkMode),
        const SizedBox(width: 20),
        _buildSocialButton(FontAwesomeIcons.google, isDarkMode),
        const SizedBox(width: 20),
        _buildSocialButton(FontAwesomeIcons.facebookF, isDarkMode),
      ],
    );
  }

  Widget _buildSocialButton(IconData icon, bool isDarkMode) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(25.0),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
        child: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: isDarkMode
                ? Colors.white.withOpacity(0.1)
                : Colors.white.withOpacity(0.2),
            shape: BoxShape.circle,
            border: Border.all(width: 1.5, color: Colors.white.withOpacity(0.2)),
          ),
          child: IconButton(
            icon: FaIcon(icon, color: Colors.white),
            onPressed: () {
              // Xử lý logic đăng nhập mạng xã hội ở đây
            },
          ),
        ),
      ),
    );
  }

  // Widget con cho link đăng ký
  Widget _buildSignUpLink() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const SignUpScreen()),
        );
      },
      child: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          style: AppFonts.comfortaaRegular.copyWith(fontSize: 16, color: Colors.white.withOpacity(0.8)),
          children: [
            const TextSpan(text: 'Bạn chưa có tài khoản? '),
            TextSpan(
              text: 'Đăng ký tại đây',
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