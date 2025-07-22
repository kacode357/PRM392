// lib/splash_screen.dart

import 'package:flutter/material.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:user/screens/welcome_screen.dart';
import 'package:user/screens/home_page.dart';
import 'package:user/services/user_services.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkTokenAndNavigate();
  }

  Future<void> _checkTokenAndNavigate() async {
    await Future.delayed(const Duration(milliseconds: 1500));

    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('accessToken');
    final refreshToken = prefs.getString('refreshToken');

    if (accessToken == null) {
      if (mounted) {
        // Chuyển hướng đến WelcomeScreen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const WelcomeScreen()),
        );
      }
      return;
    }

    if (refreshToken != null) {
      try {
        final response = await UserServices.refreshTokenApi(
          accessToken: accessToken,
          refreshToken: refreshToken,
        );
        final newAccessToken = response.data['accessToken'];
        final newRefreshToken = response.data['refreshToken'];

        await prefs.setString('accessToken', newAccessToken);
        if (newRefreshToken != null) {
          await prefs.setString('refreshToken', newRefreshToken);
        }

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomePage()),
          );
        }
      } catch (error) {
        debugPrint("Lỗi refresh token: $error");
        await prefs.remove('accessToken');
        await prefs.remove('refreshToken');
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const WelcomeScreen()),
          );
        }
      }
    } else {
      await prefs.remove('accessToken');
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const WelcomeScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        // BỌC LOGO BẰNG HERO WIDGET
        child: Hero(
          tag: 'appLogo', // Đặt một tag duy nhất, ví dụ 'appLogo'
          child: Image.asset(
            'assets/images/logo-mm-final-2.png',
            width: 250.0,
            height: 250.0,
          ),
        ),
      ),
    );
  }
}