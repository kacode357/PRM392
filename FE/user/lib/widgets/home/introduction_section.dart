import 'package:flutter/material.dart';
import 'package:user/constants/app_colors.dart'; // Mày tự import màu và font của mày
import 'package:user/constants/app_fonts.dart';

class IntroductionSection extends StatelessWidget {
  const IntroductionSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 15.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'KHUYẾN MÃI "ĐẬM ĐÀ"',
            style: AppFonts.baloo2Bold.copyWith(fontSize: 24, color: AppColors.lightBlackText),
          ),
          const SizedBox(height: 10),
          Stack(
            alignment: Alignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: Image.asset(
                  'assets/images/introduction-food.png', // NHỚ THÊM ẢNH NÀY VÀO assets
                  width: double.infinity,
                  height: 180,
                  fit: BoxFit.cover,
                ),
              ),
              Container(
                width: double.infinity,
                height: 180,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              Text(
                'Giảm Giá 30%',
                style: AppFonts.comfortaaBold.copyWith(fontSize: 36, color: AppColors.lightWhiteText),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Text(
            'Đề xuất dành cho bạn!',
            style: AppFonts.baloo2Bold.copyWith(fontSize: 24),
          ),
        ],
      ),
    );
  }
}