import 'package:user/config/dio_customize.dart'; // Đảm bảo mày đã import đúng file dio và ApiResponse

class ReviewServices {
  // 1. Tạo một review mới
  static Future<ApiResponse> createReviewApi({
    required String snackPlaceId,
    required String userId,
    required int tasteRating,
    required int priceRating,
    required int sanitaryRating,
    required int textureRating,
    required int convenienceRating,
    required String image,
    required String comment,
  }) async {
    final response = await skipNotiDioInstance.post(
      '/api/reviews/create',
      data: {
        'snackPlaceId': snackPlaceId,
        'userId': userId,
        'tasteRating': tasteRating,
        'priceRating': priceRating,
        'sanitaryRating': sanitaryRating,
        'textureRating': textureRating,
        'convenienceRating': convenienceRating,
        'image': image,
        'comment': comment,
      },
    );
    return ApiResponse.fromJson(response.data);
  }

  // 2. Lấy điểm đánh giá trung bình của một địa điểm
  static Future<ApiResponse> getAverageRateApi({required String snackPlaceId}) async {
    final response = await skipAllNotiDioInstance.get(
      '/api/reviews/getAverageRate',
      queryParameters: {'snackPlaceId': snackPlaceId},
    );
    return ApiResponse.fromJson(response.data);
  }

  // 3. Lấy tất cả review của một địa điểm (theo user hiện tại)
  static Future<ApiResponse> getReviewsBySnackPlaceIdApi({
    required String snackPlaceId,
    required String currentUserId,
  }) async {
    final response = await skipNotiDioInstance.get(
      '/api/reviews/getBySnackPlaceId',
      queryParameters: {
        'snackPlaceId': snackPlaceId,
        'currentUserId': currentUserId,
      },
    );
    return ApiResponse.fromJson(response.data);
  }

  // 4. Đề xuất/recommend một review
  static Future<ApiResponse> recommendReviewApi({
    required String reviewId,
    required String userId,
  }) async {
    final response = await skipNotiDioInstance.post(
      '/api/reviews/recommend',
      queryParameters: {
        'reviewId': reviewId,
        'userId': userId,
      },
    );
    return ApiResponse.fromJson(response.data);
  }

  // 5. Xóa một review
  static Future<ApiResponse> deleteReviewApi({required String reviewId}) async {
    final response = await defaultDioInstance.delete(
      '/api/reviews/delete',
      queryParameters: {'id': reviewId}, // BE yêu cầu param là 'id'
    );
    return ApiResponse.fromJson(response.data);
  }

  // 6. Lấy tất cả review và reply của một địa điểm
  static Future<ApiResponse> getAllReviewsAndRepliesBySnackPlaceIdApi({
    required String snackPlaceId,
  }) async {
    final response = await skipNotiDioInstance.get(
      '/api/reviews/getAllReviewsAndRepliesBySnackPlaceId',
      queryParameters: {'snackPlaceId': snackPlaceId},
    );
    return ApiResponse.fromJson(response.data);
  }

  // 7. Tạo một reply cho review hoặc cho một reply khác
  static Future<ApiResponse> createReplyApi({
    String? reviewId,       // Có thể null nếu trả lời reply khác
    String? parentReplyId,  // Có thể null nếu trả lời review gốc
    required String content,
    required String userId,
  }) async {
    final response = await defaultDioInstance.post(
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