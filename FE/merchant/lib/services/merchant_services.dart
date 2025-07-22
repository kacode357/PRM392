// lib/services/merchant_services.dart

import 'package:merchant/config/dio_customize.dart'; // Mày phải đảm bảo import này đúng

class MerchantServices {
  /// Phương thức tạo tài khoản Merchant mới.
  static Future<ApiResponse> createMerchantApi({
    required String fullName,
    required String email,
    required String userName,
    required String password,
  }) async {
    // Dùng instance mặc định, có bật tất cả toast
    final response = await defaultDioInstance.post(
      '/api/merchants/create',
      data: {
        'fullName': fullName,
        'email': email,
        'userName': userName,
        'password': password,
      },
    );
    // Trả về đối tượng ApiResponse đã được parse
    return ApiResponse.fromJson(response.data);
  }

  /// Phương thức đăng nhập cho Merchant.
  static Future<ApiResponse> loginMerchantApi({
    required String userName,
    required String password,
  }) async {
    // Dùng instance không báo toast thành công, chỉ báo lỗi
    final response = await skipNotiDioInstance.post(
      '/api/merchants/login',
      data: {
        'userName': userName,
        'password': password,
      },
    );
    return ApiResponse.fromJson(response.data);
  }

  /// Phương thức kiểm tra xem Merchant đã tạo quán ăn nào chưa.
  static Future<ApiResponse> checkCreatedSnackplaceApi() async {
    // Dùng instance tắt tất cả toast, phù hợp cho việc kiểm tra thầm lặng
    final response = await skipAllNotiDioInstance.get(
      '/api/merchants/checkCreatedSnackplace',
    );
    return ApiResponse.fromJson(response.data);
  }
}