import 'package:dio/dio.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart'; // THÊM DÒNG NÀY VÀO ĐÂY!

// Định nghĩa cấu trúc phản hồi API giống như bên React Native
class ApiResponse {
  final int status;
  final String? message;
  final Map<String, List<String>>? errors;
  final dynamic data;

  ApiResponse({
    required this.status,
    this.message,
    this.errors,
    this.data,
  });

  factory ApiResponse.fromJson(Map<String, dynamic> json) {
    return ApiResponse(
      status: json['status'] as int,
      message: json['message'] as String?,
      errors: (json['errors'] as Map<String, dynamic>?)?.map(
        (key, value) => MapEntry(key, List<String>.from(value as List)),
      ),
      data: json['data'],
    );
  }
}

// Lớp tùy chỉnh cho Interceptors để xử lý logic
class CustomInterceptors extends Interceptor {
  final bool showSuccessToast;
  final bool showErrorToast;

  CustomInterceptors({this.showSuccessToast = true, this.showErrorToast = true});

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("accessToken");
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (response.data is Map<String, dynamic>) {
      final apiResponse = ApiResponse.fromJson(response.data);

      if (showSuccessToast && apiResponse.message != null) {
        Fluttertoast.showToast(
          msg: apiResponse.message!,
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.TOP,
          backgroundColor: Colors.green,
          textColor: Colors.white,
          fontSize: 16.0,
        );
      }
    }
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    String errorMessage = "Đã xảy ra lỗi không xác định.";
    if (err.response?.data is Map<String, dynamic>) {
      final apiResponse = ApiResponse.fromJson(err.response!.data);
      if (apiResponse.message != null) {
        errorMessage = apiResponse.message!;
      }
    } else if (err.message != null) {
      errorMessage = err.message!;
    }

    if (showErrorToast) {
      Fluttertoast.showToast(
        msg: errorMessage,
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.TOP,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0,
      );
    }
    super.onError(err, handler);
  }
}

// Hàm để tạo instance Dio với baseURL và các Interceptor
Dio createDioInstance({
  bool showSuccessToast = true,
  bool showErrorToast = true,
}) {
  final Dio dio = Dio(
    BaseOptions(
      baseUrl: "https://mammap-dxapa6h5c2ctd9hz.southeastasia-01.azurewebsites.net",
      connectTimeout: const Duration(milliseconds: 30000), // 30 seconds
      receiveTimeout: const Duration(milliseconds: 30000), // 30 seconds
      headers: {
        "Content-Type": "application/json",
      },
    ),
  );

  dio.interceptors.add(CustomInterceptors(
    showSuccessToast: showSuccessToast,
    showErrorToast: showErrorToast,
  ));

  return dio;
}

// Các instance Dio đã cấu hình sẵn
final Dio defaultDioInstance = createDioInstance(
  showSuccessToast: true,
  showErrorToast: true,
);

final Dio skipNotiDioInstance = createDioInstance(
  showSuccessToast: false,
  showErrorToast: true,
);

final Dio skipAllNotiDioInstance = createDioInstance(
  showSuccessToast: false,
  showErrorToast: false,
);