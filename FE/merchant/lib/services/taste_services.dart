// lib/services/taste_services.dart

import 'package:merchant/config/dio_customize.dart'; // Mày phải đảm bảo import này đúng

class TasteServices {
  /// Phương thức tạo một khẩu vị (Taste) mới.
  static Future<ApiResponse> createTasteApi({
    required String name,
  }) async {
    final response = await defaultDioInstance.post(
      '/api/Taste/create',
      data: {'name': name},
    );
    return ApiResponse.fromJson(response.data);
  }

  /// Phương thức tìm kiếm Taste theo từ khóa và phân trang.
  static Future<ApiResponse> searchTastesApi({
    required int pageNum,
    required int pageSize,
    required String searchKeyword,
    required bool status,
  }) async {
    final response = await skipNotiDioInstance.post(
      '/api/Taste/search',
      data: {
        'pageNum': pageNum,
        'pageSize': pageSize,
        'searchKeyword': searchKeyword,
        'status': status,
      },
    );
    return ApiResponse.fromJson(response.data);
  }

  /// Phương thức lấy thông tin Taste theo ID.
  static Future<ApiResponse> getTasteByIdApi({
    required String id,
  }) async {
    final response = await defaultDioInstance.get(
      '/api/Taste/getById',
      queryParameters: {'id': id},
    );
    return ApiResponse.fromJson(response.data);
  }

  /// Phương thức cập nhật thông tin Taste.
  static Future<ApiResponse> updateTasteApi({
    required String id,
    required String name,
  }) async {
    final response = await defaultDioInstance.put(
      '/api/Taste/update',
      data: {
        'id': id,
        'name': name,
      },
    );
    return ApiResponse.fromJson(response.data);
  }

  /// Phương thức xóa một Taste theo ID.
  static Future<ApiResponse> deleteTasteApi({
    required String id,
  }) async {
    final response = await defaultDioInstance.delete(
      '/api/Taste/delete',
      queryParameters: {'id': id},
    );
    return ApiResponse.fromJson(response.data);
  }
}