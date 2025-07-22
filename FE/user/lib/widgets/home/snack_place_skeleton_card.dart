// lib/widgets/home/snack_place_skeleton_card.dart

import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:user/constants/app_colors.dart'; // Đảm bảo import AppColors

class SnackPlaceSkeletonCard extends StatelessWidget {
  const SnackPlaceSkeletonCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.lightGrayBackground, // Màu nền của shimmer
      highlightColor: AppColors.lightGrayBackground, // Màu highlight khi shimmer chạy qua
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: Colors.white, // Màu nền của skeleton item
          borderRadius: BorderRadius.circular(12.0),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Placeholder cho hình ảnh
            Container(
              width: double.infinity,
              height: 150.0,
              decoration: BoxDecoration(
                color: Colors.grey[300], // Màu của placeholder
                borderRadius: BorderRadius.circular(8.0),
              ),
            ),
            const SizedBox(height: 12.0),
            // Placeholder cho tiêu đề
            Container(
              width: double.infinity,
              height: 16.0,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 8.0),
            // Placeholder cho địa chỉ
            Container(
              width: MediaQuery.of(context).size.width * 0.6, // Chiều rộng tương đối
              height: 14.0,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 8.0),
            // Placeholder cho khoảng cách/đánh giá
            Row(
              children: [
                Container(
                  width: 60.0,
                  height: 12.0,
                  color: Colors.grey[300],
                ),
                const SizedBox(width: 10),
                Container(
                  width: 40.0,
                  height: 12.0,
                  color: Colors.grey[300],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}