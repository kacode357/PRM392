// lib/services/review_services.dart

import 'package:merchant/config/dio_customize.dart'; // Mày phải đảm bảo import này đúng và có class ApiResponse

class ReviewServices {
  /// Phương thức lấy tất cả các review và các phản hồi tương ứng.
  static Future<ApiResponse> getAllReviewsAndRepliesApi() async {
    // Dùng skipNotiDioInstance vì trong code gốc mày dùng skipNotiAxiosInstance
    final response = await skipNotiDioInstance.get('/api/reviews/getAllReviewsAndReplies');
    return ApiResponse.fromJson(response.data);
  }

  /// Phương thức tạo một phản hồi (reply) mới.
  ///
  /// - [reviewId]: ID của review gốc.
  /// - [parentReplyId]: ID của phản hồi cha (nếu đây là phản hồi của một phản hồi khác). Có thể null.
  /// - [content]: Nội dung của phản hồi.
  /// - [userId]: ID của người dùng tạo phản hồi.
  static Future<ApiResponse> createReplyApi({
    String? reviewId,
    String? parentReplyId, // Chấp nhận giá trị null, tương ứng với parentReplyId?: string | null
    required String content,
    required String userId,
  }) async {
    final response = await skipNotiDioInstance.post(
      '/api/Reply/create',
      data: {
        'reviewId': reviewId,
        'parentReplyId': parentReplyId,
        'content': content,
        'userId': userId,
      },
    );
    return ApiResponse.fromJson(response.data);
  }
}