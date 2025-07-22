// lib/screens/welcome_screen.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:simple_animations/simple_animations.dart';

import 'package:user/constants/app_colors.dart';
import 'package:user/constants/app_fonts.dart';
import 'package:user/screens/auth/signup_screen.dart';
import 'package:user/screens/home_page.dart';
import 'package:user/utils/theme_notifier.dart';
import 'package:user/screens/auth/signin_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final isDarkMode = themeNotifier.colorSchemeString == 'dark';
    const String appVersion = '1.0.0';

    // Sử dụng MovieTween để tạo animation cho nhiều widget một cách tuần tự
    final tween = MovieTween()
      ..scene(duration: const Duration(milliseconds: 500), curve: Curves.easeOut)
          .tween('opacity', Tween<double>(begin: 0.0, end: 1.0))
          .tween('y', Tween<double>(begin: 20.0, end: 0.0))
      ..scene(duration: const Duration(milliseconds: 400), curve: Curves.easeOut)
          .tween('opacityLogo', Tween<double>(begin: 0.0, end: 1.0))
          .tween('yLogo', Tween<double>(begin: 20.0, end: 0.0))
      ..scene(duration: const Duration(milliseconds: 400), curve: Curves.easeOut)
          .tween('opacityButtons', Tween<double>(begin: 0.0, end: 1.0))
          .tween('yButtons', Tween<double>(begin: 20.0, end: 0.0));


    return Scaffold(
      body: Container(
        // Áp dụng nền gradient nhất quán
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDarkMode
                ? [AppColors.darkBackground, const Color(0xFF1a2333)]
                : [Color(0xFFFFE259), Color(0xFFFFA751)] // Tông màu Hoàng Hôn Rực Rỡ
          ),
        ),
        child: PlayAnimationBuilder<Movie>(
          tween: tween,
          duration: tween.duration,
          builder: (context, value, child) {
            return Stack(
              children: [
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Spacer(flex: 2),
                        // Header
                        _buildAnimatedHeader(value),
                        const Spacer(flex: 1),
                        // Logo
                        _buildAnimatedLogo(context, value),
                        const Spacer(flex: 2),
                        // Action Buttons
                        _buildAnimatedActionButtons(context, value),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
                // Version Text
                Positioned(
                  bottom: 10,
                  right: 20,
                  child: Text(
                    'v$appVersion',
                    style: AppFonts.comfortaaRegular.copyWith(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // Widget con cho Header (có animation)
  Widget _buildAnimatedHeader(Movie value) {
    return Opacity(
      opacity: value.get('opacity'),
      child: Transform.translate(
        offset: Offset(0, value.get('y')),
        child: RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: AppFonts.baloo2ExtraBold.copyWith(
              fontSize: 36.0,
              height: 1.3,
              color: Colors.white,
              shadows: [
                Shadow(
                  blurRadius: 10.0,
                  color: Colors.black.withOpacity(0.25),
                  offset: const Offset(0, 2),
                )
              ],
            ),
            children: const <TextSpan>[
              TextSpan(text: 'ĐÓI BỤNG?\nLÊN '),
              TextSpan(text: 'MAP'),
              TextSpan(text: ', '),
              TextSpan(text: 'MĂM'),
              TextSpan(text: ' NGAY!'),
            ],
          ),
        ),
      ),
    );
  }

  // Widget con cho Logo (có animation và Hero)
  Widget _buildAnimatedLogo(BuildContext context, Movie value) {
    return Opacity(
      opacity: value.get('opacityLogo'),
      child: Transform.translate(
        offset: Offset(0, value.get('yLogo')),
        child: Hero(
          tag: 'appLogo', // Giữ nguyên tag để có hiệu ứng chuyển cảnh mượt mà
          child: Image.asset(
            'assets/images/logo-mm-final-2.png',
            width: MediaQuery.of(context).size.width * 0.5,
          ),
        ),
      ),
    );
  }

  // Widget con cho các nút hành động (có animation)
  Widget _buildAnimatedActionButtons(BuildContext context, Movie value) {
    return Opacity(
      opacity: value.get('opacityButtons'),
      child: Transform.translate(
        offset: Offset(0, value.get('yButtons')),
        child: Column(
          children: [
            // Nút chính: Tạo tài khoản
            _buildPrimaryButton(
              context: context,
              text: 'Tạo tài khoản',
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const SignUpScreen()));
              },
            ),
            const SizedBox(height: 16),
            // Nút phụ: Đăng nhập
            _buildSecondaryButton(
              context: context,
              text: 'Đăng nhập',
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const SignInScreen()));
              },
            ),
            const SizedBox(height: 24),
            // Link: Tiếp tục không đăng nhập
            GestureDetector(
              onTap: () {
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const HomePage()));
              },
              child: Text(
                'Tiếp tục với tư cách khách',
                style: AppFonts.comfortaaBold.copyWith(
                  color: Colors.white,
                  decoration: TextDecoration.underline,
                  decorationColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget cho nút chính (nền trắng, nổi bật)
  Widget _buildPrimaryButton({required BuildContext context, required String text, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 55,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              spreadRadius: 2,
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Text(
          text,
          style: AppFonts.comfortaaBold.copyWith(
            fontSize: 18,
            color: const Color(0xFFFF4E50), // Màu cam đậm của gradient
          ),
        ),
      ),
    );
  }

  // Widget cho nút phụ (hiệu ứng kính mờ)
  Widget _buildSecondaryButton({required BuildContext context, required String text, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30.0),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
          child: Container(
            width: double.infinity,
            height: 55,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(30.0),
              border: Border.all(width: 1.5, color: Colors.white.withOpacity(0.3)),
            ),
            child: Text(
              text,
              style: AppFonts.comfortaaBold.copyWith(fontSize: 18, color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }
}