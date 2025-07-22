import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:merchant/screens/auth/signup_screen.dart';
import 'package:merchant/screens/home_page.dart'; // Giữ lại nếu cần, dù cho merchant thường không vào đây
import 'package:merchant/styles/app_styles.dart';
import 'package:merchant/utils/theme_notifier.dart';
import 'package:merchant/screens/auth/signin_screen.dart'; // Vẫn dùng SignInScreen

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final String colorScheme = themeNotifier.colorSchemeString;
    final Map<String, dynamic> styles = AppStyles.getSigninStyles(colorScheme, false);
    final screenHeight = MediaQuery.of(context).size.height;
    const String appVersion = '1.0.0';

    return Scaffold(
      backgroundColor: styles['container'].color,
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      // Tiêu đề chính
                      Text(
                        'Quản Lý Dễ Dàng!',
                        textAlign: TextAlign.center,
                        style: styles['title'].copyWith(
                          fontSize: 40.0, // Đã là double, giữ nguyên
                          height: 1.2,
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.02),

                      // Phụ đề
                      RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          style: styles['forgotPassword'].copyWith(
                            fontSize: 18.0, // Đã là double, giữ nguyên
                            height: 1.2,
                          ),
                          children: <TextSpan>[
                            const TextSpan(text: 'Đưa quán ăn của bạn lên '),
                            TextSpan(
                              text: 'MAP',
                              style: styles['signupLink'].copyWith(
                                  fontSize: 18.0, // Đã là double, giữ nguyên
                                  height: 1.2),
                            ),
                            const TextSpan(text: ' và thu hút khách hàng!'),
                          ],
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.05),

                      // Logo Merchant
                      Image.asset(
                        'assets/images/logo-merchant.png', // Đảm bảo đường dẫn đúng
                        width: 200,
                        height: 200,
                        fit: BoxFit.contain,
                      ),
                      SizedBox(height: screenHeight * 0.05),

                      // Nút "Quản lý quán ngay" (Trỏ về SignInScreen)
                      GestureDetector(
                        onTap: () {
                          // Điều hướng đến màn hình đăng nhập
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const SignInScreen()));
                        },
                        child: Container(
                          width: 280,
                          height: 48,
                          decoration: BoxDecoration(
                            border: Border.all(color: styles['title'].color),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Quản lý quán ngay',
                            // SỬA Ở ĐÂY: Thêm .0
                            style: styles['forgotPassword'].copyWith(fontSize: 16.0),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Nút "Đăng ký người dùng" (Vẫn trỏ về SignUpScreen)
                      GestureDetector(
                        onTap: () {
                          // Điều hướng đến màn hình đăng ký
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const SignUpScreen()));
                        },
                        child: Container(
                          width: 280,
                          height: 48,
                          decoration: BoxDecoration(
                            color: styles['signupLink'].color,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Đăng ký người dùng',
                            // SỬA Ở ĐÂY: Thêm .0
                            style: styles['loginButtonText'].copyWith(color: styles['container'].color, fontSize: 16.0),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Version Text
            Positioned(
              bottom: 20,
              right: 20,
              child: Text(
                'Phiên bản: $appVersion',
                // SỬA Ở ĐÂY: Thêm .0
                style: styles['dividerText'].copyWith(fontSize: 12.0),
              ),
            ),
          ],
        ),
      ),
    );
  }
}