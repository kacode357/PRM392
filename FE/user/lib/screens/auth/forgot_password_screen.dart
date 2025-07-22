import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';

import 'package:user/components/alert_modal.dart';
import 'package:user/services/user_services.dart';
import 'package:user/styles/app_styles.dart';
import 'package:user/utils/theme_notifier.dart';
import 'package:user/screens/auth/verify_otp_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;

  // --- Logic chống spam ---
  int _requestAttempts = 0;
  DateTime? _requestBlockedUntil;
  final int _maxAttempts = 3;
  final Duration _blockDuration = const Duration(minutes: 5);
  // -------------------------

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _dismissKeyboard() {
    FocusScope.of(context).unfocus();
  }

  void _showAlertModal({
    required String title,
    required String message,
    VoidCallback? onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertModal(
          visible: true,
          title: title,
          message: message,
          onConfirm: () {
            Navigator.of(dialogContext).pop();
            if (onConfirm != null) onConfirm();
          },
        );
      },
    );
  }

  Future<void> _handleForgotPassword() async {
    _dismissKeyboard();
    final String email = _emailController.text.trim();

    // --- Kiểm tra logic chống spam ---
    final now = DateTime.now();

    if (_requestBlockedUntil != null && now.isBefore(_requestBlockedUntil!)) {
      final remainingTime = _requestBlockedUntil!.difference(now).inSeconds;
      _showAlertModal(
        title: 'Lỗi',
        message: 'Bạn đã thử quá nhiều lần. Vui lòng chờ $remainingTime giây trước khi thử lại.',
      );
      return;
    } else if (_requestBlockedUntil != null && now.isAfter(_requestBlockedUntil!)) {
      // Nếu hết thời gian khoá, reset lại
      _requestAttempts = 0;
      _requestBlockedUntil = null;
    }

    if (_requestAttempts >= _maxAttempts) {
      setState(() {
        _requestBlockedUntil = now.add(_blockDuration);
        _requestAttempts = 0; // Reset lại sau khi bị khoá
      });
      _showAlertModal(
        title: 'Lỗi',
        message: 'Bạn đã vượt quá số lần thử. Vui lòng chờ 5 phút.',
      );
      return;
    }
    // ---------------------------------

    if (email.isEmpty || !RegExp(r'\S+@\S+\.\S+').hasMatch(email)) {
      _showAlertModal(
        title: 'Lỗi',
        message: 'Vui lòng nhập một địa chỉ email hợp lệ.',
      );
      return;
    }

    setState(() { _isLoading = true; });

    try {
      await UserServices.forgotPasswordApi(email: email);

      setState(() {
        _requestAttempts++; // Tăng số lần thử nếu thành công
      });

      // Chuyển màn hình với email để xác thực OTP
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VerifyOtpScreen(email: email),
          ),
        );
      }
    } catch (e) {
      debugPrint('Lỗi khi gửi yêu cầu quên mật khẩu: $e');
      // Lỗi đã được xử lý bởi interceptor, không cần show modal ở đây
      // trừ khi mày muốn ghi đè.
    } finally {
      if (mounted) {
        setState(() { _isLoading = false; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final String colorScheme = themeNotifier.colorSchemeString;
    // Tạm dùng styles của SignUp, mày có thể tạo styles riêng cho màn này nếu muốn
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
                Text('QUÊN MẬT KHẨU?', style: styles['title']),
                const SizedBox(height: 10),
                Text(
                  'Đừng lo lắng, hãy nhập email của bạn để chúng mình gửi mã xác nhận nhé!',
                  style: styles['subtitle'],
                ),
                const SizedBox(height: 30),

                // Email input
                Text('Email', style: styles['inputLabel']),
                Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: styles['inputDecoration'],
                  child: TextField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      hintText: 'hello@example.com',
                      hintStyle: styles['inputTextStyle'].copyWith(color: styles['eyeIconColor']),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 15),
                    ),
                    style: styles['inputTextStyle'],
                    keyboardType: TextInputType.emailAddress,
                    textCapitalization: TextCapitalization.none,
                    enabled: !_isLoading,
                  ),
                ),

                // Nút xác nhận
                GestureDetector(
                  onTap: _isLoading ? null : _handleForgotPassword,
                  child: Container(
                    width: double.infinity,
                    height: 50,
                    decoration: styles['signupButtonDecoration'],
                    alignment: Alignment.center,
                    child: _isLoading
                        ? const CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          )
                        : Text('Xác nhận', style: styles['signupButtonText']),
                  ),
                ),

                const SizedBox(height: 20),
                // Nút quay lại
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Text(
                        'Quay lại Đăng nhập',
                        style: styles['loginLink'],
                      ),
                    ),
                  ],
                ),
                 SizedBox(height: MediaQuery.of(context).padding.bottom + 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}