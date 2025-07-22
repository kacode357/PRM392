import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart'; // Import shimmer

class SnackPlaceDetailSkeleton extends StatelessWidget {
  const SnackPlaceDetailSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView( // Đảm bảo skeleton có thể cuộn
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Skeleton cho ảnh header
          Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(
              height: 300,
              width: double.infinity,
              color: Colors.white,
            ),
          ),
          // Skeleton cho phần thông tin chính
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Shimmer.fromColors(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.grey[100]!,
                  child: Container(
                    width: double.infinity,
                    height: 28.0, // Chiều cao ước tính của tên quán
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                Shimmer.fromColors(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.grey[100]!,
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.6,
                    height: 16.0, // Chiều cao ước tính của tóm tắt đánh giá
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                Shimmer.fromColors(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.grey[100]!,
                  child: Column(
                    children: List.generate(3, (index) => Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Container(
                        width: double.infinity,
                        height: 14.0, // Chiều cao ước tính của các dòng mô tả
                        color: Colors.white,
                      ),
                    )),
                  ),
                ),
                const SizedBox(height: 24),
                // Skeleton cho các dòng chi tiết (địa chỉ, sđt, giờ mở cửa)
                _buildSkeletonDetailRow(context),
                _buildSkeletonDetailRow(context),
                _buildSkeletonDetailRow(context),
                const SizedBox(height: 24),
                // Skeleton cho nút
                Shimmer.fromColors(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.grey[100]!,
                  child: Container(
                    width: double.infinity,
                    height: 50.0,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                Shimmer.fromColors(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.grey[100]!,
                  child: Container(
                    width: double.infinity,
                    height: 50.0,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          // Skeleton cho TabBar
          Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(
              width: double.infinity,
              height: kToolbarHeight, // Chiều cao của TabBar
              color: Colors.white,
              margin: const EdgeInsets.symmetric(vertical: 16.0), // Tạo khoảng cách
            ),
          ),
          // Skeleton cho nội dung TabView
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Shimmer.fromColors(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.grey[100]!,
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.5,
                    height: 20.0, // Tiêu đề tab
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                Shimmer.fromColors(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.grey[100]!,
                  child: Column(
                    children: List.generate(5, (index) => Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Container(
                        width: double.infinity,
                        height: 14.0, // Các dòng text trong tab
                        color: Colors.white,
                      ),
                    )),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper để tạo một dòng skeleton cho thông tin chi tiết
  Widget _buildSkeletonDetailRow(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(
              width: 22,
              height: 22,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Shimmer.fromColors(
              baseColor: Colors.grey[300]!,
              highlightColor: Colors.grey[100]!,
              child: Container(
                height: 16,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}