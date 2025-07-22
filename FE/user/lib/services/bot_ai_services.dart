import 'dart:developer';
import 'package:user/config/dio_customize.dart';

/// Kết quả API chung
class ApiResponse<T> {
  final int status;
  final String message;
  final T? data;
  ApiResponse({required this.status, required this.message, this.data});
}

/// =======================
///        GEMINI API
/// =======================
class BotAiServices {
  /* ------------ ASK ------------ */
  static Future<ApiResponse> askGemini({
    required String prompt,
    required String sessionId,
  }) async {
    final res = await skipNotiDioInstance.post(
      '/api/Gemini/ask',
      data: {
        'request': prompt,          // backend yêu cầu key “request”
        'sessionId': sessionId,
        'prompt': prompt,           // kèm theo cho an toàn
      },
    );
    log('Gemini.ask > ${res.data}', name: 'BotAiServices');
    return ApiResponse(
        status: res.statusCode ?? 500, message: 'Success', data: res.data);
  }

  /* ------------ SESSION CRUD ------------ */
  static Future<ApiResponse> createSession({String? title}) async {
    final res = await skipNotiDioInstance.post(
      '/api/Gemini/createSession',
      queryParameters: {
        if (title != null && title.isNotEmpty) 'title': title,
      },
    );
    log('Gemini.createSession > ${res.data}', name: 'BotAiServices');
    return ApiResponse(
        status: res.statusCode ?? 500, message: 'Success', data: res.data);
  }

  static Future<ApiResponse> getAllSessions() async {
    final res = await skipNotiDioInstance.get('/api/Gemini/getAllSessions');
    log('Gemini.getAllSessions > ${res.data}', name: 'BotAiServices');
    return ApiResponse(
        status: res.statusCode ?? 500, message: 'Success', data: res.data);
  }

  static Future<ApiResponse> getSessionById({required String sessionId}) async {
    final res = await skipNotiDioInstance.get(
      '/api/Gemini/getSessionById',
      queryParameters: {'sessionId': sessionId},
    );
    log('Gemini.getSessionById > ${res.data}', name: 'BotAiServices');
    return ApiResponse(
        status: res.statusCode ?? 500, message: 'Success', data: res.data);
  }

  static Future<ApiResponse> deleteSession({required String sessionId}) async {
    final res = await skipNotiDioInstance.delete(
      '/api/Gemini/deleteSession',
      queryParameters: {'sessionId': sessionId},
    );
    log('Gemini.deleteSession > ${res.data}', name: 'BotAiServices');
    return ApiResponse(
        status: res.statusCode ?? 500, message: 'Success', data: res.data);
  }
}
