import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Để ẩn bàn phím
import 'package:provider/provider.dart';

import 'package:merchant/components/alert_modal.dart';
import 'package:merchant/constants/app_colors.dart';
import 'package:merchant/services/user_services.dart';
import 'package:merchant/styles/app_styles.dart';
import 'package:merchant/utils/theme_notifier.dart';
import 'package:merchant/screens/auth/signin_screen.dart'; // Import màn hình đăng nhập để chuyển về

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _userNameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _secureTextEntry = true;
  bool _secureConfirmTextEntry = true;
  bool _isLoading = false;
  // bool _modalVisible = false; // Không cần biến này nữa
  Map<String, dynamic> _modalConfig = {'title': '', 'message': ''};

  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _emailController.dispose();
    _fullNameController.dispose();
    _userNameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _scrollController.dispose();
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

  // Hàm hiển thị AlertModal (tái sử dụng từ SignInScreen)
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

    // Client-side validation
    if (email.isEmpty || fullName.isEmpty || userName.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      _showAlertModal(
        title: 'Lỗi',
        message: 'Vui lòng điền đầy đủ tất cả các thông tin',
      );
      return;
    }

    if (!RegExp(r'\S+@\S+\.\S+').hasMatch(email)) {
      _showAlertModal(
        title: 'Lỗi',
        message: 'Định dạng email không hợp lệ',
      );
      return;
    }

    if (!RegExp(r'^[a-z0-9_-]+$').hasMatch(userName)) {
      _showAlertModal(
        title: 'Lỗi',
        message: 'Tên đăng nhập chỉ được chứa chữ thường, số, dấu gạch dưới hoặc gạch ngang, không chứa khoảng trắng hoặc chữ hoa',
      );
      return;
    }

    if (password != confirmPassword) {
      _showAlertModal(
        title: 'Lỗi',
        message: 'Mật khẩu và xác nhận mật khẩu không khớp',
      );
      return;
    }

    if (password.length < 6) {
      _showAlertModal(
        title: 'Lỗi',
        message: 'Mật khẩu phải có ít nhất 6 ký tự',
      );
      return;
    }

    // New password validation
    if (!RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&;])[A-Za-z\d@$!%*?&;]+$').hasMatch(password)) {
      _showAlertModal(
        title: 'Lỗi',
        message: 'Mật khẩu phải chứa ít nhất một chữ cái viết hoa, một chữ cái viết thường, một số và một ký tự đặc biệt',
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

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
      // Toast lỗi đã được xử lý bởi interceptor
      // Nếu muốn hiển thị modal thay vì toast cho lỗi API, thì bỏ comment dòng dưới
      // _showAlertModal(title: 'Lỗi Đăng ký', message: 'Đã xảy ra lỗi khi tạo tài khoản. Vui lòng thử lại.', isSuccess: false);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Handle keyboard visibility for scrolling
  void _onKeyboardChanged(bool isVisible, double keyboardHeight) {
    if (isVisible) {
      // Khi bàn phím hiện ra, cuộn xuống dưới cùng để input không bị che
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } else {
      // Khi bàn phím ẩn đi, cuộn về đầu nếu muốn
      _scrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final String colorScheme = themeNotifier.colorSchemeString;
    final Map<String, dynamic> styles = AppStyles.getSignupStyles(colorScheme, _isLoading);

    return GestureDetector(
      onTap: _dismissKeyboard,
      child: Scaffold(
        backgroundColor: styles['container'].color,
        body: Padding(
          padding: styles['scrollContainerPadding'],
          child: SingleChildScrollView(
            controller: _scrollController,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top - MediaQuery.of(context).padding.bottom,
              ),
              child: IntrinsicHeight( // Để Column có thể co giãn theo nội dung trong SingleChildScrollView
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start, // Alignments for overall column
                  children: <Widget>[
                    SizedBox(height: MediaQuery.of(context).padding.top + 20), // Padding from top

                    // Tiêu đề
                    Text(
                      'TẠO TÀI KHOẢN',
                      style: styles['title'],
                    ),
                    Text(
                      'Hãy điền đầy đủ thông tin dưới đây để chúng mình có thể hỗ trợ tốt hơn nhé!',
                      style: styles['subtitle'],
                    ),
                    const SizedBox(height: 30), // Khoảng cách giữa subtitle và input đầu tiên

                    // Email
                    Text('Email', style: styles['inputLabel']),
                    Container(
                      margin: const EdgeInsets.only(bottom: 15),
                      decoration: styles['inputDecoration'],
                      child: TextField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          hintText: 'hello@example.com',
                          hintStyle: styles['inputTextStyle'].copyWith(
                            color: colorScheme == 'light' ? AppColors.lightIcon : AppColors.darkIcon,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 15),
                        ),
                        style: styles['inputTextStyle'],
                        keyboardType: TextInputType.emailAddress,
                        textCapitalization: TextCapitalization.none,
                        enabled: !_isLoading,
                      ),
                    ),

                    // Họ tên
                    Text('Họ tên của bạn', style: styles['inputLabel']),
                    Container(
                      margin: const EdgeInsets.only(bottom: 15),
                      decoration: styles['inputDecoration'],
                      child: TextField(
                        controller: _fullNameController,
                        decoration: InputDecoration(
                          hintText: 'Nguyễn Văn A',
                          hintStyle: styles['inputTextStyle'].copyWith(
                            color: colorScheme == 'light' ? AppColors.lightIcon : AppColors.darkIcon,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 15),
                        ),
                        style: styles['inputTextStyle'],
                        textCapitalization: TextCapitalization.words,
                        enabled: !_isLoading,
                      ),
                    ),

                    // Tên đăng nhập
                    Text('Tên đăng nhập', style: styles['inputLabel']),
                    Container(
                      margin: const EdgeInsets.only(bottom: 15),
                      decoration: styles['inputDecoration'],
                      child: TextField(
                        controller: _userNameController,
                        decoration: InputDecoration(
                          hintText: 'username',
                          hintStyle: styles['inputTextStyle'].copyWith(
                            color: colorScheme == 'light' ? AppColors.lightIcon : AppColors.darkIcon,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 15),
                        ),
                        style: styles['inputTextStyle'],
                        textCapitalization: TextCapitalization.none,
                        enabled: !_isLoading,
                      ),
                    ),

                    // Mật khẩu
                    Text('Mật khẩu', style: styles['inputLabel']),
                    Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: styles['inputDecoration'],
                      child: Stack(
                        alignment: Alignment.centerRight,
                        children: [
                          TextField(
                            controller: _passwordController,
                            decoration: InputDecoration(
                              hintText: '••••••••',
                              hintStyle: styles['inputTextStyle'].copyWith(
                                color: colorScheme == 'light' ? AppColors.lightIcon : AppColors.darkIcon,
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.only(left: 15, right: 45),
                            ),
                            style: styles['inputTextStyle'],
                            obscureText: _secureTextEntry,
                            textCapitalization: TextCapitalization.none,
                            enabled: !_isLoading,
                          ),
                          Positioned(
                            right: 15,
                            child: GestureDetector(
                              onTap: _togglePasswordVisibility,
                              child: Icon(
                                _secureTextEntry ? Icons.visibility_off : Icons.visibility,
                                size: 20,
                                color: styles['eyeIconColor'],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Xác nhận mật khẩu
                    Text('Xác nhận mật khẩu', style: styles['inputLabel']),
                    Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: styles['inputDecoration'],
                      child: Stack(
                        alignment: Alignment.centerRight,
                        children: [
                          TextField(
                            controller: _confirmPasswordController,
                            decoration: InputDecoration(
                              hintText: '••••••••',
                              hintStyle: styles['inputTextStyle'].copyWith(
                                color: colorScheme == 'light' ? AppColors.lightIcon : AppColors.darkIcon,
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.only(left: 15, right: 45),
                            ),
                            style: styles['inputTextStyle'],
                            obscureText: _secureConfirmTextEntry,
                            textCapitalization: TextCapitalization.none,
                            enabled: !_isLoading,
                          ),
                          Positioned(
                            right: 15,
                            child: GestureDetector(
                              onTap: _toggleConfirmPasswordVisibility,
                              child: Icon(
                                _secureConfirmTextEntry ? Icons.visibility_off : Icons.visibility,
                                size: 20,
                                color: styles['eyeIconColor'],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Điều khoản và điều kiện
                    Align( // Align để căn trái toàn bộ cụm Text này
                      alignment: Alignment.topLeft,
                      child: Wrap( // Dùng Wrap để các Text có thể xuống dòng
                        children: <Widget>[
                          Text(
                            'Bằng cách gửi biểu mẫu này, tôi đồng ý với ',
                            style: styles['termsText'],
                          ),
                          GestureDetector(
                            onTap: () {
                              debugPrint('Navigate to terms and conditions');
                            },
                            child: Text(
                              'điều khoản và điều kiện',
                              style: styles['termsLink'],
                            ),
                          ),
                          Text(
                            ' của Măm Map',
                            style: styles['termsText'],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20), // Khoảng cách

                    // Nút Đăng ký
                    GestureDetector(
                      onTap: _isLoading ? null : _handleSignup,
                      child: Container(
                        width: double.infinity,
                        height: 50,
                        decoration: styles['signupButtonDecoration'],
                        alignment: Alignment.center,
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              )
                            : Text(
                                'Đăng ký',
                                style: styles['signupButtonText'],
                              ),
                      ),
                    ),

                    const SizedBox(height: 20), // Khoảng cách

                    // Đã có tài khoản? Đăng nhập tại đây
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Text('Bạn đã có tài khoản? ', style: styles['loginText']),
                        GestureDetector(
                          onTap: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (context) => const SignInScreen()),
                            );
                          },
                          child: Text(
                            'Đăng nhập tại đây',
                            style: styles['loginLink'],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: MediaQuery.of(context).padding.bottom + 20), // Khoảng cách dưới cùng
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}