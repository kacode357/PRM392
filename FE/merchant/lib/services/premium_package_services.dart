// lib/services/premium_package_services.dart

import 'package:merchant/config/dio_customize.dart'; // Mày phải đảm bảo import này đúng

class PremiumPackageServices {
  /// Phương thức tạo một Gói Premium mới.
  static Future<ApiResponse> createPremiumPackageApi({
    required String name,
    required num price,
    required List<String> descriptions,
  }) async {
    final response = await defaultDioInstance.post(
      '/api/PremiumPackage/create',
      data: {
        'name': name,
        'price': price,
        'descriptions': descriptions,
      },
    );
    return ApiResponse.fromJson(response.data);
  }

  /// Phương thức lấy thông tin Gói Premium theo ID.
  static Future<ApiResponse> getPremiumPackageByIdApi({
    required String id,
  }) async {
    final response = await skipNotiDioInstance.get(
      '/api/PremiumPackage/getById',
      queryParameters: {'id': id},
    );
    return ApiResponse.fromJson(response.data);
  }

  /// Phương thức tìm kiếm Gói Premium theo từ khóa và phân trang.
  static Future<ApiResponse> searchPremiumPackagesApi({
    required int pageNum,
    required int pageSize,
    required String searchKeyword,
    required bool status,
  }) async {
    final response = await skipNotiDioInstance.post(
      '/api/PremiumPackage/search',
      data: {
        'pageNum': pageNum,
        'pageSize': pageSize,
        'searchKeyword': searchKeyword,
        'status': status,
      },
    );
    return ApiResponse.fromJson(response.data);
  }

  /// Phương thức cập nhật thông tin Gói Premium.
  static Future<ApiResponse> updatePremiumPackageApi({
    required String id,
    required String name,
    required num price,
    required List<String> descriptions,
  }) async {
    final response = await defaultDioInstance.put(
      '/api/PremiumPackage/update', // Endpoint không cần query param ở đây
      queryParameters: {'id': id}, // Dio sẽ tự thêm `?id=...` vào URL
      data: {
        'name': name,
        'price': price,
        'descriptions': descriptions,
      },
    );
    return ApiResponse.fromJson(response.data);
  }

  /// Phương thức xóa một Gói Premium theo ID.
  static Future<ApiResponse> deletePremiumPackageApi({
    required String id,
  }) async {
    final response = await defaultDioInstance.delete(
      '/api/PremiumPackage/delete',
      queryParameters: {'id': id},
    );
    return ApiResponse.fromJson(response.data);
  }
}