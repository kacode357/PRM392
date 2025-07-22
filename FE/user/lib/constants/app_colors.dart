import 'package:flutter/material.dart'; // Cần cái này để dùng Color

class AppColors {
  // Định nghĩa màu cho chế độ light
  static const Color lightText = Color(0xFF11181C);
  static const Color lightBackground = Color(0xFFFFFFFF);
  static const Color lightTint = Color(0xFF0a7ea4);
  static const Color lightIcon = Color(0xFF687076);
  static const Color lightTabIconDefault = Color(0xFFFFFFFF);
  static const Color lightTabIconSelected = Color(0xFFFFE001);
  static const Color lightTabBackground = Color(0xFFFF9500);
  static const Color lightYellowText = Color(0xFFFFE001);
  static const Color lightPrimaryText = Color(0xFFFF9500);
  static const Color lightBlackText = Color(0xFF000000);
  static const Color lightWhiteText = Color(0xFFFFFFFF);
  static const Color lightSafeAreaBackground = Color(0xFFF5F5F5);
  static const Color lightGrayBackground = Color(0xFFE0E0E0);
  static const Color lightSuccess = Color(0xFF28a745);
  static const Color lightError = Color(0xFFdc3545);

  // Định nghĩa màu cho chế độ dark (hiện tại giống light, mày có thể thay đổi)
  static const Color darkText = Color(0xFF11181C);
  static const Color darkBackground = Color(0xFFFFFFFF);
  static const Color darkTint = Color(0xFF0a7ea4);
  static const Color darkIcon = Color(0xFF687076);
  static const Color darkTabIconDefault = Color(0xFFFFFFFF);
  static const Color darkTabIconSelected = Color(0xFFFFE001);
  static const Color darkTabBackground = Color(0xFFFF9500);
  static const Color darkYellowText = Color(0xFFFFE001);
  static const Color darkPrimaryText = Color(0xFFFF9500);
  static const Color darkBlackText = Color(0xFF000000);
  static const Color darkWhiteText = Color(0xFFFFFFFF);
  static const Color darkSafeAreaBackground = Color(0xFFF5F5F5);
  static const Color darkGrayBackground = Color(0xFFE0E0E0);
  static const Color darkSuccess = Color(0xFF28a745);
  static const Color darkError = Color(0xFFdc3545);

  // Nếu mày muốn truy cập màu theo theme (light/dark) tiện hơn,
  // mày có thể tạo một đối tượng hoặc getter dựa vào context/theme mode
  // Ví dụ:
  // static Color get textColor => /* logic kiểm tra theme mode */ ? lightText : darkText;
}