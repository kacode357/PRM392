// lib/services/business_model_services.dart

import 'package:merchant/config/dio_customize.dart'; // Mày phải đảm bảo import này đúng

class BusinessModelServices {
  /// Phương thức tìm kiếm Mô hình kinh doanh theo từ khóa và phân trang.
  static Future<ApiResponse> searchBusinessModelsApi({
    required int pageNum,
    required int pageSize,
    required String searchKeyword,
    required bool status,
  }) async {
    // Dùng instance không báo toast thành công
    final response = await skipNotiDioInstance.post(
      '/api/BusinessModels/search',
      data: {
        'pageNum': pageNum,
        'pageSize': pageSize,
        'searchKeyword': searchKeyword,
        'status': status,
      },
    );
    return ApiResponse.fromJson(response.data);
  }
}