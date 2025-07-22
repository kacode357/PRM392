import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';

import 'package:merchant/components/alert_modal.dart';
import 'package:merchant/services/user_services.dart';
import 'package:merchant/styles/app_styles.dart';
import 'package:merchant/utils/theme_notifier.dart';
import 'package:merchant/screens/auth/signin_screen.dart';

class VerifyOtpScreen extends StatefulWidget {
  final String email; // Nhận email từ màn hình trước

  const VerifyOtpScreen({super.key, required this.email});

  @override
  State<VerifyOtpScreen> createState() => _VerifyOtpScreenState();
}

class _VerifyOtpScreenState extends State<VerifyOtpScreen> {
  // --- State cho OTP ---
  static const int _otpLength = 6;
  static const int _countdownSeconds = 30;
  late List<TextEditingController> _otpControllers;
  late List<FocusNode> _otpFocusNodes;
  Timer? _timer;
  int _countdown = _countdownSeconds;
  bool _canResend = false;
  
  // --- State chung ---
  bool _isOtpVerified = false; // Dùng để chuyển đổi UI
  bool _isLoading = false;

  // --- State cho Mật khẩu mới ---
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  bool _secureNewPassword = true;
  bool _secureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    _otpControllers = List.generate(_otpLength, (_) => TextEditingController());
    _otpFocusNodes = List.generate(_otpLength, (_) => FocusNode());
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var focusNode in _otpFocusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  void _startTimer() {
    _canResend = false;
    _countdown = _countdownSeconds;
    _timer?.cancel(); // Hủy timer cũ nếu có
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 0) {
        setState(() {
          _countdown--;
        });
      } else {
        setState(() {
          _canResend = true;
        });
        timer.cancel();
      }
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
        );
      },
    );
  }

  void _handleOtpChange(String value, int index) {
    if (value.isNotEmpty) {
      if (index < _otpLength - 1) {
        _otpFocusNodes[index + 1].requestFocus();
      } else {
        _dismissKeyboard();
        _handleVerifyOtp(); // Tự động xác thực khi nhập đủ
      }
    } else {
      if (index > 0) {
        _otpFocusNodes[index - 1].requestFocus();
      }
    }
  }

  void _handleVerifyOtp() {
    final otpCode = _otpControllers.map((c) => c.text).join();
    if (otpCode.length != _otpLength) {
      _showAlertModal(title: 'Lỗi', message: 'Vui lòng nhập đủ $_otpLength chữ số OTP.');
      return;
    }
    // Chỉ chuyển UI, không gọi API ở bước này
    setState(() {
      _isOtpVerified = true;
    });
  }

  Future<void> _handleResendOtp() async {
    if (!_canResend) return;

    setState(() { _isLoading = true; });

    try {
      await UserServices.forgotPasswordApi(email: widget.email);
      // Reset lại các ô OTP và bắt đầu đếm ngược lại
      for (var controller in _otpControllers) {
        controller.clear();
      }
      _otpFocusNodes[0].requestFocus();
      _startTimer();
      _showAlertModal(
        title: 'Thành công',
        message: 'Đã gửi lại mã OTP thành công!',
        isSuccess: true,
      );

    } catch (e) {
      debugPrint('Lỗi gửi lại OTP: $e');
    } finally {
      setState(() { _isLoading = false; });
    }
  }

  Future<void> _handleResetPassword() async {
    _dismissKeyboard();
    final String newPassword = _newPasswordController.text.trim();
    final String confirmPassword = _confirmPasswordController.text.trim();
    final String otp = _otpControllers.map((c) => c.text).join();

    if (newPassword.isEmpty || confirmPassword.isEmpty) {
      _showAlertModal(title: 'Lỗi', message: 'Vui lòng nhập đầy đủ mật khẩu mới.');
      return;
    }
    if (newPassword.length < 6) {
      _showAlertModal(title: 'Lỗi', message: 'Mật khẩu phải có ít nhất 6 ký tự.');
      return;
    }
    if (newPassword != confirmPassword) {
      _showAlertModal(title: 'Lỗi', message: 'Mật khẩu xác nhận không khớp.');
      return;
    }

    setState(() { _isLoading = true; });

    try {
      await UserServices.resetPasswordApi(
        email: widget.email,
        otp: otp,
        newPassword: newPassword,
      );
      _showAlertModal(
        title: 'Thành công',
        message: 'Mật khẩu của bạn đã được đặt lại. Vui lòng đăng nhập.',
        isSuccess: true,
        onConfirm: () {
          // Xoá hết stack và đẩy về màn hình đăng nhập
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const SignInScreen()),
            (Route<dynamic> route) => false,
          );
        },
      );
    } catch (e) {
      debugPrint('Lỗi đặt lại mật khẩu: $e');
    } finally {
      if(mounted) {
        setState(() { _isLoading = false; });
      }
    }
  }

  String _formatTime(int seconds) {
    final mins = (seconds / 60).floor().toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$mins:$secs';
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
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                SizedBox(height: MediaQuery.of(context).padding.top + 20),
                Text(
                  _isOtpVerified ? 'ĐẶT LẠI MẬT KHẨU' : 'XÁC THỰC OTP',
                  style: styles['title'],
                ),
                const SizedBox(height: 10),
                Text(
                  _isOtpVerified
                      ? 'Vui lòng nhập mật khẩu mới cho tài khoản của bạn.'
                      : 'Nhập mã OTP mà chúng mình vừa gửi qua ${widget.email}',
                  style: styles['subtitle'],
                ),
                const SizedBox(height: 30),

                // --- Hiển thị UI dựa trên _isOtpVerified ---
                if (!_isOtpVerified)
                  _buildOtpInputSection(styles)
                else
                  _buildNewPasswordSection(styles),

                SizedBox(height: MediaQuery.of(context).padding.bottom + 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Widget cho phần nhập OTP
  Widget _buildOtpInputSection(Map<String, dynamic> styles) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Các ô OTP
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(_otpLength, (index) {
            return SizedBox(
              width: 50,
              height: 50,
              child: TextField(
                controller: _otpControllers[index],
                focusNode: _otpFocusNodes[index],
                onChanged: (value) => _handleOtpChange(value, index),
                style: styles['inputTextStyle'].copyWith(fontSize: 20.0), 
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: styles['eyeIconColor']),
                  ),
                  enabledBorder: OutlineInputBorder(
                     borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: styles['eyeIconColor']),
                  ),
                  focusedBorder: OutlineInputBorder(
                     borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: styles['loginLink'].color, width: 2),
                  ),
                  counterText: '',
                  contentPadding: const EdgeInsets.all(0),
                ),
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                maxLength: 1,
              ),
            );
          }),
        ),
        const SizedBox(height: 20),

        // Nút xác nhận
        GestureDetector(
          onTap: _isLoading ? null : _handleVerifyOtp,
          child: Container(
            width: double.infinity,
            height: 50,
            decoration: styles['signupButtonDecoration'],
            alignment: Alignment.center,
            child: _isLoading
                ? const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white))
                : Text('Xác nhận', style: styles['signupButtonText']),
          ),
        ),
        const SizedBox(height: 20),

        // Gửi lại mã
        Center(
          child: _canResend
              ? GestureDetector(
                  onTap: _handleResendOtp,
                  child: Text('Gửi lại mã', style: styles['loginLink']),
                )
              : Text(
                  'Gửi lại mã sau ${_formatTime(_countdown)}',
                  style: styles['loginText'],
                ),
        )
      ],
    );
  }

  // Widget cho phần nhập mật khẩu mới
  Widget _buildNewPasswordSection(Map<String, dynamic> styles) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Mật khẩu mới
        Text('Mật khẩu mới', style: styles['inputLabel']),
        Container(
          margin: const EdgeInsets.only(bottom: 15),
          decoration: styles['inputDecoration'],
          child: Stack(
            alignment: Alignment.centerRight,
            children: [
              TextField(
                controller: _newPasswordController,
                decoration: InputDecoration(
                  hintText: '••••••••',
                  hintStyle: styles['inputTextStyle'].copyWith(color: styles['eyeIconColor']),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.only(left: 15, right: 45),
                ),
                style: styles['inputTextStyle'],
                obscureText: _secureNewPassword,
                enabled: !_isLoading,
              ),
              Positioned(
                right: 15,
                child: GestureDetector(
                  onTap: () => setState(() => _secureNewPassword = !_secureNewPassword),
                  child: Icon(
                    _secureNewPassword ? Icons.visibility_off : Icons.visibility,
                    size: 20, color: styles['eyeIconColor'],
                  ),
                ),
              ),
            ],
          ),
        ),

        // Xác nhận mật khẩu mới
        Text('Xác nhận mật khẩu', style: styles['inputLabel']),
        Container(
          margin: const EdgeInsets.only(bottom: 20),
          decoration: styles['inputDecoration'],
          child: Stack(
            alignment: Alignment.centerRight,
            children: [
              TextField(
                controller: _confirmPasswordController,
                decoration: InputDecoration(
                  hintText: '••••••••',
                  hintStyle: styles['inputTextStyle'].copyWith(color: styles['eyeIconColor']),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.only(left: 15, right: 45),
                ),
                style: styles['inputTextStyle'],
                obscureText: _secureConfirmPassword,
                enabled: !_isLoading,
              ),
              Positioned(
                right: 15,
                child: GestureDetector(
                  onTap: () => setState(() => _secureConfirmPassword = !_secureConfirmPassword),
                  child: Icon(
                    _secureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                    size: 20, color: styles['eyeIconColor'],
                  ),
                ),
              ),
            ],
          ),
        ),

        // Nút đặt lại mật khẩu
        GestureDetector(
          onTap: _isLoading ? null : _handleResetPassword,
          child: Container(
            width: double.infinity,
            height: 50,
            decoration: styles['signupButtonDecoration'],
            alignment: Alignment.center,
            child: _isLoading
                ? const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white))
                : Text('Đặt lại mật khẩu', style: styles['signupButtonText']),
          ),
        ),
      ],
    );
  }
}