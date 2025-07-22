// lib/widgets/home/snack_place_card.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:user/constants/app_colors.dart';
import 'package:user/constants/app_fonts.dart';
import 'package:user/models/snack_place_model.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';

class SnackPlaceCard extends StatelessWidget {
  final SnackPlace? item;
  final VoidCallback? onTap;
  final bool isLoading;

  const SnackPlaceCard({
    super.key,
    this.item,
    this.onTap,
    this.isLoading = false,
  });

  String _formatTime(String time) {
    try {
      final parts = time.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      String period = "sáng";
      int displayHour = hour;

      if (hour >= 12) {
        period = hour >= 18 ? "tối" : "chiều";
        displayHour = hour == 12 ? 12 : hour - 12;
      }
      if (hour == 0) displayHour = 12;

      return '${displayHour.toString()}:${minute.toString().padLeft(2, '0')} $period';
    } catch (e) {
      return 'Không xác định';
    }
  }

  @override
  Widget build(BuildContext context) {
    // Nếu đang loading, hiển thị skeleton (shimmer effect)
    if (isLoading) {
      return Shimmer.fromColors(
        baseColor: AppColors.lightGrayBackground,
        highlightColor: AppColors.lightBackground,
        child: Container(
          margin: const EdgeInsets.only(bottom: 15, left: 10, right: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: const BoxDecoration(
                  color: Colors.white, // Màu của placeholder trong shimmer
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(12),
                    bottomLeft: Radius.circular(12),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: double.infinity,
                        height: 18.0,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: MediaQuery.of(context).size.width * 0.4,
                        height: 14.0,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 4),
                      Container(
                        width: MediaQuery.of(context).size.width * 0.3,
                        height: 14.0,
                        color: Colors.white,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Nếu không loading, hiển thị nội dung card thật
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 15, left: 10, right: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Hero(
              tag: 'snackPlaceImage-${item!.snackPlaceId}',
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
                child: CachedNetworkImage(
                  imageUrl: item!.image,
                  width: 120,
                  height: 120,
                  fit: BoxFit.cover,
                  // THAY ĐỔI PHẦN PLACEHOLDER NÀY
                  placeholder: (context, url) => Container(
                    width: 120,
                    height: 120,
                    color: Colors.grey[200], // Màu nền tĩnh khi đang tải ảnh
                    child: const Icon(Icons.image, color: Colors.grey), // Có thể thêm icon hoặc để trống
                  ),
                  errorWidget: (context, url, error) => Container(
                      width: 120,
                      height: 120,
                      color: Colors.grey[200],
                      child: const Icon(Icons.broken_image, color: Colors.grey)),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        if (item!.premiumPackage?.isActive == true)
                          const Icon(Icons.star, color: Color(0xFFFFD700), size: 18),
                        if (item!.premiumPackage?.isActive == true)
                          const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            item!.placeName,
                            style: AppFonts.comfortaaBold.copyWith(fontSize: 18),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text.rich(
                      TextSpan(
                        style: AppFonts.comfortaaRegular.copyWith(fontSize: 14, color: Colors.grey[600]),
                        children: [
                          TextSpan(text: 'Giờ mở cửa: ', style: AppFonts.comfortaaBold),
                          TextSpan(text: _formatTime(item!.openingHour)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text.rich(
                      TextSpan(
                        style: AppFonts.comfortaaRegular.copyWith(fontSize: 14, color: Colors.grey[600]),
                        children: [
                          TextSpan(text: 'Giá: ', style: AppFonts.comfortaaBold),
                          TextSpan(
                              text: NumberFormat.currency(locale: 'vi_VN', symbol: '₫')
                                  .format(item!.averagePrice)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}