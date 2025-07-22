import 'package:flutter/material.dart';
import 'package:user/constants/app_colors.dart'; // Nhớ sửa 'user'
// import 'package:user/constants/app_fonts.dart'; // BỎ DÒNG NÀY ĐI HOÀN TOÀN NẾU MÀY KHÔNG CÓ FONT TÙY CHỈNH NÀO CẢ

class AppStyles {
  // Hàm này vẫn giữ nguyên, nhưng nếu mày không dùng font tùy chỉnh,
  // fontFamily sẽ bị bỏ qua và Flutter sẽ dùng font mặc định.
  static TextStyle _getTextStyle(String colorScheme, Color? defaultColor, {required FontWeight fontWeight, required double fontSize}) {
    Color textColor = defaultColor ?? AppColors.lightText;

    if (colorScheme == 'dark') {
      textColor = defaultColor ?? AppColors.darkText;
    }

    return TextStyle(
      fontWeight: fontWeight,
      fontSize: fontSize,
      color: textColor,
    );
  }

  // Phương thức hỗ trợ tạo BoxDecoration cho input
  static BoxDecoration _getInputDecoration({required String colorScheme, bool isLoading = false}) {
    Color borderColor = colorScheme == 'light' ? AppColors.lightIcon : AppColors.darkIcon;
    return BoxDecoration(
      border: Border.all(color: borderColor, width: 1),
      borderRadius: BorderRadius.circular(25),
      color: isLoading
          ? (colorScheme == 'light' ? AppColors.lightGrayBackground.withOpacity(0.5) : AppColors.darkGrayBackground.withOpacity(0.5))
          : (colorScheme == 'light' ? AppColors.lightBackground : AppColors.darkBackground),
    );
  }

  // Phương thức hỗ trợ tạo BoxDecoration cho nút login
  static BoxDecoration _getLoginButtonDecoration({required String colorScheme, bool isLoading = false}) {
    Color bgColor = colorScheme == 'light' ? AppColors.lightPrimaryText : AppColors.darkPrimaryText;
    return BoxDecoration(
      color: bgColor.withOpacity(isLoading ? 0.6 : 1.0),
      borderRadius: BorderRadius.circular(25),
    );
  }

  // Phương thức hỗ trợ tạo BoxDecoration cho các nút mạng xã hội
  static BoxDecoration _getSocialButtonDecoration({required String colorScheme}) {
    Color borderColor = colorScheme == 'light' ? AppColors.lightIcon : AppColors.darkIcon;
    return BoxDecoration(
      border: Border.all(color: borderColor, width: 1),
      borderRadius: BorderRadius.circular(25),
    );
  }


  static Map<String, dynamic> getSigninStyles(String colorScheme, bool isLoading) {
    return {
      'container': BoxDecoration(
        color: colorScheme == 'light' ? AppColors.lightBackground : AppColors.darkBackground,
      ),
      'logoContainer': const EdgeInsets.only(bottom: 20),
      'logo': const Size(220, 150),
      // Sửa lỗi 'CrossAxisAlignment.start'
      // Trong Flutter, các giá trị của enum như CrossAxisAlignment.start
      // đã là hằng số rồi, không cần dùng const với constructor của nó.
      // Chỉ cần dùng trực tiếp enum value là được.
      'textContainerAlignment': CrossAxisAlignment.start, // Đổi tên key để rõ ràng hơn

      'title': TextStyle(
        fontWeight: FontWeight.w800,
        fontSize: 36,
        color: colorScheme == 'light' ? AppColors.lightText : AppColors.darkText,
        height: 53 * 1.3 / 36,
        letterSpacing: -0.02 * 53,
      ),
      'inputLabel': TextStyle(
        fontWeight: FontWeight.w500,
        fontSize: 16,
        color: colorScheme == 'light' ? AppColors.lightText : AppColors.darkText,
      ),
      // Gọi các hàm đã được định nghĩa lại ở trên
      'inputDecoration': _getInputDecoration(colorScheme: colorScheme, isLoading: isLoading),
      'inputTextStyle': TextStyle(
        fontWeight: FontWeight.w400,
        fontSize: 16,
        color: colorScheme == 'light' ? AppColors.lightText : AppColors.darkText,
      ),
      'passwordContainer': { // Đây là map để mô phỏng style của container
        'width': double.infinity,
        'position': 'relative',
      },
      'eyeIconColor': colorScheme == 'light' ? AppColors.lightPrimaryText : AppColors.darkPrimaryText,
      'forgotPasswordContainerAlignment': CrossAxisAlignment.end, // Đổi tên key để rõ ràng hơn
      'forgotPassword': TextStyle(
        fontWeight: FontWeight.w400,
        fontSize: 14,
        color: colorScheme == 'light' ? AppColors.lightPrimaryText : AppColors.darkPrimaryText,
      ),
      // Gọi các hàm đã được định nghĩa lại ở trên
      'loginButtonDecoration': _getLoginButtonDecoration(colorScheme: colorScheme, isLoading: isLoading),
      'loginButtonText': TextStyle(
        fontWeight: FontWeight.w500,
        fontSize: 16,
        color: colorScheme == 'light' ? AppColors.lightWhiteText : AppColors.darkWhiteText,
      ),
      'dividerLineColor': colorScheme == 'light' ? AppColors.lightIcon : AppColors.darkIcon,
      'dividerText': TextStyle(
        fontWeight: FontWeight.w400,
        fontSize: 14,
        color: colorScheme == 'light' ? AppColors.lightIcon : AppColors.darkIcon,
      ),
      // Gọi các hàm đã được định nghĩa lại ở trên
      'socialButtonDecoration': _getSocialButtonDecoration(colorScheme: colorScheme),
      'socialIconColor': colorScheme == 'light' ? AppColors.lightText : AppColors.darkText,
      'signupLinkContainerAlignment': MainAxisAlignment.center, // Đổi tên key để rõ ràng hơn
      'signupText': TextStyle(
        fontWeight: FontWeight.w400,
        fontSize: 14,
        color: colorScheme == 'light' ? AppColors.lightText : AppColors.darkText,
      ),
      'signupLink': TextStyle(
        fontWeight: FontWeight.w400,
        fontSize: 14,
        color: colorScheme == 'light' ? AppColors.lightPrimaryText : AppColors.darkPrimaryText,
      ),
    };
  }
  static Map<String, dynamic> getSignupStyles(String colorScheme, bool isLoading) {
    return {
      'container': BoxDecoration(
        color: colorScheme == 'light' ? AppColors.lightBackground : AppColors.darkBackground,
      ),
      'scrollContainerPadding': const EdgeInsets.symmetric(horizontal: 20),
      'textContainerAlignment': CrossAxisAlignment.start,
      'title': TextStyle(
        fontWeight: FontWeight.w800,
        fontSize: 36,
        color: colorScheme == 'light' ? AppColors.lightText : AppColors.darkText,
        height: 53 * 1.3 / 36,
        letterSpacing: -0.02 * 53,
      ),
      'subtitle': TextStyle(
        fontWeight: FontWeight.w400, // Hoặc FontWeight.normal
        fontSize: 14,
        color: colorScheme == 'light' ? AppColors.lightText : AppColors.darkText,
      ),
      'inputLabel': TextStyle(
        fontWeight: FontWeight.w500,
        fontSize: 16,
        color: colorScheme == 'light' ? AppColors.lightText : AppColors.darkText,
      ),
      'inputDecoration': _getInputDecoration(colorScheme: colorScheme, isLoading: isLoading),
      'inputTextStyle': TextStyle(
        fontWeight: FontWeight.w400,
        fontSize: 16,
        color: colorScheme == 'light' ? AppColors.lightText : AppColors.darkText,
      ),
      'passwordContainerWidth': double.infinity,
      'eyeIconColor': colorScheme == 'light' ? AppColors.lightPrimaryText : AppColors.darkPrimaryText,
      'termsContainerAlignment': CrossAxisAlignment.start,
      'termsText': TextStyle(
        fontWeight: FontWeight.w400,
        fontSize: 14,
        color: colorScheme == 'light' ? AppColors.lightText : AppColors.darkText,
      ),
      'termsLink': TextStyle(
        fontWeight: FontWeight.w400,
        fontSize: 14,
        color: colorScheme == 'light' ? AppColors.lightPrimaryText : AppColors.darkPrimaryText,
      ),
      'signupButtonDecoration': _getLoginButtonDecoration(colorScheme: colorScheme, isLoading: isLoading), // Tái sử dụng style nút login
      'signupButtonText': TextStyle(
        fontWeight: FontWeight.w500,
        fontSize: 16,
        color: colorScheme == 'light' ? AppColors.lightWhiteText : AppColors.darkWhiteText,
      ),
      'loginLinkContainerAlignment': MainAxisAlignment.center,
      'loginText': TextStyle(
        fontWeight: FontWeight.w400,
        fontSize: 14,
        color: colorScheme == 'light' ? AppColors.lightText : AppColors.darkText,
      ),
      'loginLink': TextStyle(
        fontWeight: FontWeight.w400,
        fontSize: 14,
        color: colorScheme == 'light' ? AppColors.lightPrimaryText : AppColors.darkPrimaryText,
      ),
    };
  }
  static Map<String, dynamic> getForgotPasswordStyles(String colorScheme, bool isLoading) {
  return {
    'container': BoxDecoration(
      color: colorScheme == 'light' ? AppColors.lightBackground : AppColors.darkBackground,
    ),
    'scrollContainerPadding': const EdgeInsets.symmetric(horizontal: 20),
    'textContainerAlignment': CrossAxisAlignment.start,
    'title': TextStyle(
      fontWeight: FontWeight.w800,
      fontSize: 36,
      color: colorScheme == 'light' ? AppColors.lightText : AppColors.darkText,
      height: 36 * 1.3 / 36, // line-height
      letterSpacing: -0.02 * 36,
    ),
    'instruction': TextStyle(
      fontWeight: FontWeight.w400,
      fontSize: 16,
      height: 24 / 16, // Adjusted proportionally
      color: colorScheme == 'light' ? AppColors.lightPrimaryText : AppColors.darkPrimaryText,
    ),
    'inputLabel': TextStyle(
      fontWeight: FontWeight.w500,
      fontSize: 16,
      color: colorScheme == 'light' ? AppColors.lightText : AppColors.darkText,
    ),
    'inputDecoration': _getInputDecoration(colorScheme: colorScheme, isLoading: isLoading),
    'inputTextStyle': TextStyle(
      fontWeight: FontWeight.w400,
      fontSize: 16,
      color: colorScheme == 'light' ? AppColors.lightText : AppColors.darkText,
    ),
    'resetButtonDecoration': _getLoginButtonDecoration(colorScheme: colorScheme, isLoading: isLoading),
    'resetButtonText': TextStyle(
      fontWeight: FontWeight.w500,
      fontSize: 16,
      color: colorScheme == 'light' ? AppColors.lightWhiteText : AppColors.darkWhiteText,
    ),
    'errorText': TextStyle(
      fontWeight: FontWeight.w400,
      fontSize: 14,
      color: colorScheme == 'light' ? AppColors.lightError : AppColors.darkError, // Sử dụng AppColors.lightError
    ),
  };
}
}