// lib/services/payment_services.dart

import 'dart:convert'; // Thêm để in JSON đẹp
import 'package:dio/dio.dart'; // Thêm để bắt lỗi Dio
import 'package:merchant/config/dio_customize.dart';

class PaymentServices {
  /// Phương thức tạo một giao dịch thanh toán mới.
  static Future<ApiResponse> createPaymentApi({
    required int premiumPackageId,
  }) async {
    const String endpoint = '/api/Payment/create';
    print('🚀 [API REQUEST] Calling $endpoint...');

    try {
      final response = await skipNotiDioInstance.post(
        endpoint,
        data: {'premiumPackageId': premiumPackageId},
      );
      // LOG KHI THÀNH CÔNG
      _logSuccess('createPaymentApi', response.data);
      return ApiResponse.fromJson(response.data);
    } catch (e) {
      // LOG KHI CÓ LỖI và NÉM LỖI RA LẠI
      _logError('createPaymentApi', e);
      rethrow; // Ném lỗi ra lại để UI có thể bắt và xử lý
    }
  }

  /// Phương thức kiểm tra trạng thái của một giao dịch.
  static Future<ApiResponse> checkPaymentStatusApi({
    required String paymentId,
  }) async {
    const String endpoint = '/api/Payment/checkStatus';
    print('🚀 [API REQUEST] Calling $endpoint with paymentId: $paymentId');
    
    try {
      final response = await skipAllNotiDioInstance.get(
        endpoint,
        queryParameters: {'paymentId': paymentId},
      );
      // LOG KHI THÀNH CÔNG
      _logSuccess('checkPaymentStatusApi', response.data);
      return ApiResponse.fromJson(response.data);
    } catch (e) {
      // LOG KHI CÓ LỖI và NÉM LỖI RA LẠI
      _logError('checkPaymentStatusApi', e);
      rethrow;
    }
  }

  /// Phương thức lấy lịch sử giao dịch của người dùng hiện tại.
  static Future<ApiResponse> getPaymentHistoryApi() async {
    const String endpoint = '/api/Payment/paymentHistory';
    print('🚀 [API REQUEST] Calling $endpoint...');

    try {
      final response = await skipNotiDioInstance.get(endpoint);
      // LOG KHI THÀNH CÔNG
      _logSuccess('getPaymentHistoryApi', response.data);
      return ApiResponse.fromJson(response.data);
    } catch (e) {
      // LOG KHI CÓ LỖI và NÉM LỖI RA LẠI
      _logError('getPaymentHistoryApi', e);
      rethrow;
    }
  }

  /// Phương thức kiểm tra xem người dùng hiện tại có gói premium nào không.
  static Future<ApiResponse> hasPackageApi() async {
    const String endpoint = '/api/Payment/hasPackage';
    print('🚀 [API REQUEST] Calling $endpoint...');

    try {
      final response = await skipNotiDioInstance.get(endpoint);
      // LOG KHI THÀNH CÔNG
      _logSuccess('hasPackageApi', response.data);
      return ApiResponse.fromJson(response.data);
    } catch (e) {
      // LOG KHI CÓ LỖI và NÉM LỖI RA LẠI
      _logError('hasPackageApi', e);
      rethrow;
    }
  }

  // === HÀM HELPER ĐỂ LOG CHO GỌN ===
  static void _logSuccess(String functionName, dynamic data) {
    const encoder = JsonEncoder.withIndent('  ');
    final prettyResponse = encoder.convert(data);
    print('✅ [API SUCCESS] in $functionName:\n$prettyResponse');
  }

  static void _logError(String functionName, Object e) {
    print('❌ [API ERROR] in $functionName: $e');
    if (e is DioException) {
      print('    Error Type: ${e.type}');
      print('    Error Response: ${e.response?.data}');
    }
  }
}