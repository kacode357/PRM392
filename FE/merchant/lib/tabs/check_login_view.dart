import 'package:flutter/material.dart';
import 'package:merchant/constants/app_colors.dart';
import 'package:merchant/constants/app_fonts.dart';
import 'package:merchant/screens/welcome_screen.dart';

class CheckLoginView extends StatelessWidget {
  const CheckLoginView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Thay vì dùng ảnh, tao dùng Icon cho tiện
              const Icon(
                Icons.warning_amber_rounded,
                size: 100,
                color: AppColors.lightTabBackground,
              ),
              const SizedBox(height: 20),
              Text(
                'Úi, bạn chưa đăng nhập!',
                style: AppFonts.comfortaaRegular.copyWith(fontSize: 28),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                'Bạn cần đăng nhập để sử dụng các tính năng này.',
                style: AppFonts.comfortaaRegular.copyWith(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () {
                  // Về màn welcome để có thể chọn đăng nhập/đăng ký
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const WelcomeScreen()),
                    (route) => false,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.lightPrimaryText,
                  foregroundColor: AppColors.lightWhiteText,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: Text(
                  'Đăng nhập',
                  style: AppFonts.comfortaaMedium.copyWith(fontSize: 16),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}