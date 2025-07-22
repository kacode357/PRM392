// lib/services/food_type_services.dart

import 'package:merchant/config/dio_customize.dart'; // Mày phải đảm bảo import này đúng

class FoodTypeServices {
  /// Phương thức tạo một loại món ăn (FoodType) mới.
  static Future<ApiResponse> createFoodTypeApi({
    required String name,
  }) async {
    final response = await defaultDioInstance.post(
      '/api/FoodType/create',
      data: {'name': name},
    );
    return ApiResponse.fromJson(response.data);
  }

  /// Phương thức tìm kiếm FoodType theo từ khóa và phân trang.
  static Future<ApiResponse> searchFoodTypesApi({
    required int pageNum,
    required int pageSize,
    required String searchKeyword,
    required bool status,
  }) async {
    final response = await skipNotiDioInstance.post(
      '/api/FoodType/search',
      data: {
        'pageNum': pageNum,
        'pageSize': pageSize,
        'searchKeyword': searchKeyword,
        'status': status,
      },
    );
    return ApiResponse.fromJson(response.data);
  }

  /// Phương thức lấy thông tin FoodType theo ID.
  static Future<ApiResponse> getFoodTypeByIdApi({
    required String id,
  }) async {
    final response = await defaultDioInstance.get(
      '/api/FoodType/getById',
      queryParameters: {'id': id},
    );
    return ApiResponse.fromJson(response.data);
  }

  /// Phương thức cập nhật thông tin FoodType.
  static Future<ApiResponse> updateFoodTypeApi({
    required String id,
    required String name,
  }) async {
    final response = await defaultDioInstance.put(
      '/api/FoodType/update',
      data: {
        'id': id,
        'name': name,
      },
    );
    return ApiResponse.fromJson(response.data);
  }

  /// Phương thức xóa một FoodType theo ID.
  static Future<ApiResponse> deleteFoodTypeApi({
    required String id,
  }) async {
    final response = await defaultDioInstance.delete(
      '/api/FoodType/delete',
      queryParameters: {'id': id},
    );
    return ApiResponse.fromJson(response.data);
  }
}