import 'package:merchant/config/dio_customize.dart'; // Thay 'your_app_name' bằng tên project của mày

class UserServices {
  // Phương thức tạo người dùng mới
  static Future<ApiResponse> createUserApi(
      {required String fullName,
      required String email,
      required String userName,
      required String password}) async {
    final response = await defaultDioInstance.post(
      '/api/merchants/create',
      data: {
        'fullName': fullName,
        'email': email,
        'userName': userName,
        'password': password,
      },
    );
    return ApiResponse.fromJson(response.data);
  }

  // Phương thức đăng nhập
  static Future<ApiResponse> loginUserApi(
      {required String userName, required String password}) async {
    final response = await skipNotiDioInstance.post(
      '/api/merchants/login',
      data: {
        'userName': userName,
        'password': password,
      },
    );
    return ApiResponse.fromJson(response.data);
  }

  // Phương thức lấy thông tin người dùng hiện tại
  static Future<ApiResponse> getCurrentUserApi() async {
    final response = await skipNotiDioInstance.get('/api/users/get-current-login');
    return ApiResponse.fromJson(response.data);
  }

  // Phương thức quên mật khẩu
  static Future<ApiResponse> forgotPasswordApi({required String email}) async {
    final response = await defaultDioInstance.post(
      '/api/users/forgot-password',
      data: {'email': email},
    );
    return ApiResponse.fromJson(response.data);
  }

  // Phương thức đặt lại mật khẩu
  static Future<ApiResponse> resetPasswordApi({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    final response = await defaultDioInstance.post(
      '/api/users/reset-password',
      data: {
        'email': email,
        'otp': otp,
        'newPassword': newPassword,
      },
    );
    return ApiResponse.fromJson(response.data);
  }

  // Phương thức refresh token
  static Future<ApiResponse> refreshTokenApi(
      {required String accessToken, required String refreshToken}) async {
    final response = await skipNotiDioInstance.post(
      '/api/users/refresh-token',
      data: {
        'accessToken': accessToken,
        'refreshToken': refreshToken,
      },
    );
    return ApiResponse.fromJson(response.data);
  }

  // Phương thức lấy người dùng theo ID
  static Future<ApiResponse> getUserByIdApi({required String id}) async {
    final response = await skipNotiDioInstance.get('/api/users/getById?id=$id');
    return ApiResponse.fromJson(response.data);
  }

  // Phương thức cập nhật thông tin người dùng
  static Future<ApiResponse> updateUserApi({
    required String id,
    required String phoneNumber,
    required String fullname,
    required String image,
    required String dateOfBirth,
  }) async {
    final response = await defaultDioInstance.put(
      '/api/users/update',
      data: {
        'id': id,
        'phoneNumber': phoneNumber,
        'fullname': fullname,
        'image': image,
        'dateOfBirth': dateOfBirth,
      },
    );
    return ApiResponse.fromJson(response.data);
  }

  // Phương thức đổi mật khẩu
  static Future<ApiResponse> changePasswordApi({
    required String oldPassword,
    required String newPassword,
  }) async {
    final response = await defaultDioInstance.post(
      '/api/users/change-password',
      data: {
        'oldPassword': oldPassword,
        'newPassword': newPassword,
      },
    );
    return ApiResponse.fromJson(response.data);
  }
}