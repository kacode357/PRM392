import 'package:merchant/config/dio_customize.dart';// Mày nhớ thay đúng đường dẫn

class DishServices {
  // Phương thức tạo một món ăn mới
  static Future<ApiResponse> createDishApi({
    required String name,
    required String description,
    required String image,
    required num price,
    required String snackPlaceId,
  }) async {
    final response = await defaultDioInstance.post(
      '/api/Dish/create',
      data: {
        'name': name,
        'description': description,
        'image': image,
        'price': price,
        'snackPlaceId': snackPlaceId,
      },
    );
    return ApiResponse.fromJson(response.data);
  }

  // Phương thức lấy danh sách món ăn theo địa điểm (có thông báo)
  static Future<ApiResponse> getDishesBySnackPlaceApi({
    required String snackPlaceId,
  }) async {
    final response = await skipNotiDioInstance.get(
      '/api/Dish/getBySnackPlace',
      queryParameters: {'snackPlaceId': snackPlaceId},
    );
    return ApiResponse.fromJson(response.data);
  }

  // Phương thức lấy danh sách món ăn theo địa điểm (không có thông báo)
  static Future<ApiResponse> getNoNotiDishesBySnackPlaceApi({
    required String snackPlaceId,
  }) async {
    final response = await skipAllNotiDioInstance.get(
      '/api/Dish/getBySnackPlace',
      queryParameters: {'snackPlaceId': snackPlaceId},
    );
    return ApiResponse.fromJson(response.data);
  }

  // Phương thức cập nhật thông tin món ăn
  static Future<ApiResponse> updateDishApi({
    required String dishId,
    required String name,
    required String description,
    required String image,
    required num price,
    required String snackPlaceId,
  }) async {
    final response = await defaultDioInstance.put(
      '/api/Dish/update',
      data: {
        'dishId': dishId,
        'name': name,
        'description': description,
        'image': image,
        'price': price,
        'snackPlaceId': snackPlaceId,
      },
    );
    return ApiResponse.fromJson(response.data);
  }
}