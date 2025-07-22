// lib/services/snackplace_services.dart

import 'package:merchant/config/dio_customize.dart'; // Nhớ import dòng này nhé

class SnackPlaceServices {
  /// Phương thức tạo một địa điểm ăn vặt mới.
  static Future<ApiResponse> createSnackPlaceApi({
    required String userId,
    required String placeName,
    required String ownerName,
    required String address,
    required String email,
    required String coordinates,
    required String openingHour,
    required num averagePrice,
    required String image,
    required String mainDish,
    required String phoneNumber,
    required String businessModelId,
    required List<String> tasteIds,
    required List<String> dietIds,
    required List<String> foodTypeIds,
    String? description, // THÊM TRƯỜNG NÀY
  }) async {
    final response = await defaultDioInstance.post(
      '/api/SnackPlaces/create',
      data: {
        'userId': userId,
        'placeName': placeName,
        'ownerName': ownerName,
        'address': address,
        'email': email,
        'coordinates': coordinates,
        'openingHour': openingHour,
        'averagePrice': averagePrice,
        'image': image,
        'mainDish': mainDish,
        'phoneNumber': phoneNumber,
        'businessModelId': businessModelId,
        'tasteIds': tasteIds,
        'dietIds': dietIds,
        'foodTypeIds': foodTypeIds,
        'description': description, // THÊM TRƯỜNG NÀY
      },
    );
    return ApiResponse.fromJson(response.data);
  }

  /// Phương thức cập nhật thông tin quán ăn.
  static Future<ApiResponse> updateSnackPlaceApi({
    required String snackPlaceId,
    required String placeName,
    required String ownerName,
    required String address,
    required String email,
    required String coordinates,
    required String openingHour,
    required num averagePrice,
    required String image,
    required String mainDish,
    required String phoneNumber,
    required String businessModelId,
    required List<String> tasteIds,
    required List<String> dietIds,
    required List<String> foodTypeIds,
    String? description, // THÊM TRƯỜNG NÀY
  }) async {
    final response = await defaultDioInstance.put(
      '/api/SnackPlaces/update',
      data: {
        'snackPlaceId': snackPlaceId,
        'placeName': placeName,
        'ownerName': ownerName,
        'address': address,
        'email': email,
        'coordinates': coordinates,
        'openingHour': openingHour,
        'averagePrice': averagePrice,
        'image': image,
        'mainDish': mainDish,
        'phoneNumber': phoneNumber,
        'businessModelId': businessModelId,
        'tasteIds': tasteIds,
        'dietIds': dietIds,
        'foodTypeIds': foodTypeIds,
        'description': description, // THÊM TRƯỜNG NÀY
      },
    );
    return ApiResponse.fromJson(response.data);
  }

  /// Phương thức tìm kiếm địa điểm ăn vặt.
  static Future<ApiResponse> searchSnackPlacesApi({
    required int pageNum,
    required int pageSize,
    required String searchKeyword,
    required bool status,
  }) async {
    final response = await skipNotiDioInstance.post(
      '/api/SnackPlaces/search-snackplaces',
      data: {
        'pageNum': pageNum,
        'pageSize': pageSize,
        'searchKeyword': searchKeyword,
        'status': status,
      },
    );
    return ApiResponse.fromJson(response.data);
  }

  /// Phương thức lấy địa điểm ăn vặt theo ID, có thể tắt thông báo.
  static Future<ApiResponse> getSnackPlaceByIdApi({
    required String id,
    bool silent = false, // Đặt là true để tắt mọi thông báo
  }) async {
    final dio = silent ? skipAllNotiDioInstance : skipNotiDioInstance;
    final response = await dio.get(
      '/api/SnackPlaces/getById',
      queryParameters: {'id': id},
    );
    return ApiResponse.fromJson(response.data);
  }

  /// Phương thức ghi lại lượt click vào địa điểm.
  static Future<ApiResponse> recordSnackPlaceClickApi({
    required String userId,
    required String snackPlaceId,
  }) async {
    final response = await skipNotiDioInstance.post(
      '/api/SnackPlaces/click',
      data: {
        'userId': userId,
        'snackPlaceId': snackPlaceId,
      },
    );
    return ApiResponse.fromJson(response.data);
  }

  /// Phương thức lấy tất cả các thuộc tính của địa điểm (taste, diet, foodtype).
  static Future<ApiResponse> getAllSnackPlaceAttributesApi() async {
    final response = await skipNotiDioInstance.get('/api/SnackPlaces/getAllAttributes');
    return ApiResponse.fromJson(response.data);
  }

  /// Phương thức lọc địa điểm ăn vặt.
  static Future<ApiResponse> filterSnackPlacesApi({
    required num priceFrom,
    required num priceTo,
    required List<String> tasteIds,
    required List<String> dietIds,
    required List<String> foodTypeIds,
  }) async {
    final response = await skipNotiDioInstance.post(
      '/api/SnackPlaces/filter',
      data: {
        'priceFrom': priceFrom,
        'priceTo': priceTo,
        'tasteIds': tasteIds,
        'dietIds': dietIds,
        'foodTypeIds': foodTypeIds,
      },
    );
    return ApiResponse.fromJson(response.data);
  }

  /// Phương thức lấy thống kê địa điểm ăn vặt theo ID.
  /// Tương ứng với `getSnackPlaceStats` bên React Native.
  static Future<ApiResponse> getSnackPlaceStatsApi({
    required String id,
  }) async {
    final response = await skipNotiDioInstance.get(
      '/api/SnackPlaces/stats',
      queryParameters: {'id': id},
    );
    return ApiResponse.fromJson(response.data);
  }

  /// Phương thức lấy lượt click địa điểm ăn vặt trong khoảng ngày.
  /// Tương ứng với `getSnackPlaceClicks` bên React Native.
  static Future<ApiResponse> getSnackPlaceClicksApi({
    required String startDate, // Định dạng ngày: YYYY-MM-DD
    required String endDate,   // Định dạng ngày: YYYY-MM-DD
  }) async {
    final response = await skipNotiDioInstance.get(
      '/api/SnackPlaces/getClick',
      queryParameters: {
        'startDate': startDate,
        'endDate': endDate,
      },
    );
    return ApiResponse.fromJson(response.data);
  }
}