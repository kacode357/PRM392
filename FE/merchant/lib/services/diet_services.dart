// lib/services/diet_services.dart

import 'package:merchant/config/dio_customize.dart'; // Mày phải đảm bảo import này đúng

class DietServices {
  /// Phương thức tạo một chế độ ăn kiêng (Diet) mới.
  static Future<ApiResponse> createDietApi({
    required String name,
  }) async {
    final response = await defaultDioInstance.post(
      '/api/Diet/create',
      data: {'name': name},
    );
    return ApiResponse.fromJson(response.data);
  }

  /// Phương thức tìm kiếm Diet theo từ khóa và phân trang.
  static Future<ApiResponse> searchDietsApi({
    required int pageNum,
    required int pageSize,
    required String searchKeyword,
    required bool status,
  }) async {
    final response = await skipNotiDioInstance.post(
      '/api/Diet/search',
      data: {
        'pageNum': pageNum,
        'pageSize': pageSize,
        'searchKeyword': searchKeyword,
        'status': status,
      },
    );
    return ApiResponse.fromJson(response.data);
  }

  /// Phương thức lấy thông tin Diet theo ID.
  static Future<ApiResponse> getDietByIdApi({
    required String id,
  }) async {
    final response = await defaultDioInstance.get(
      '/api/Diet/getById',
      queryParameters: {'id': id},
    );
    return ApiResponse.fromJson(response.data);
  }

  /// Phương thức cập nhật thông tin Diet.
  static Future<ApiResponse> updateDietApi({
    required String id,
    required String name,
  }) async {
    final response = await defaultDioInstance.put(
      '/api/Diet/update',
      data: {
        'id': id,
        'name': name,
      },
    );
    return ApiResponse.fromJson(response.data);
  }

  /// Phương thức xóa một Diet theo ID.
  static Future<ApiResponse> deleteDietApi({
    required String id,
  }) async {
    final response = await defaultDioInstance.delete(
      '/api/Diet/delete',
      queryParameters: {'id': id},
    );
    return ApiResponse.fromJson(response.data);
  }
}