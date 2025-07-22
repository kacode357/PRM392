import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Để ẩn bàn phím
import 'package:font_awesome_flutter/font_awesome_flutter.dart'; // Cho các icon xã hội
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert'; // Import để dùng jsonEncode

import 'package:merchant/components/alert_modal.dart';
import 'package:merchant/constants/app_colors.dart';
import 'package:merchant/constants/app_fonts.dart';
import 'package:merchant/screens/auth/forgot_password_screen.dart';
import 'package:merchant/screens/auth/signup_screen.dart';
import 'package:merchant/screens/home_page.dart';
import 'package:merchant/services/user_services.dart';
import 'package:merchant/styles/app_styles.dart';
import 'package:merchant/utils/theme_notifier.dart';
// import 'package:merchant/main.dart'; // Không cần import main.dart nếu MyHomePage không dùng ở đây

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _secureTextEntry = true;
  bool _isLoading = false;
  Map<String, dynamic> _modalConfig = {'title': '', 'message': ''};

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _togglePasswordVisibility() {
    setState(() {
      _secureTextEntry = !_secureTextEntry;
    });
  }

  void _dismissKeyboard() {
    FocusScope.of(context).unfocus(); // Tương đương Keyboard.dismiss()
  }

  // Hàm hiển thị AlertModal
  void _showAlertModal({
    required String title,
    required String message,
    bool? isSuccess,
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false, // Không đóng dialog khi chạm ra ngoài
      builder: (BuildContext dialogContext) {
        return AlertModal(
          visible: true, // Luôn visible khi dùng showDialog
          title: title,
          message: message,
          isSuccess: isSuccess,
          onConfirm: () {
            Navigator.of(dialogContext).pop(); // Đóng dialog
            if (onConfirm != null) onConfirm();
          },
          onCancel: onCancel != null
              ? () {
                  Navigator.of(dialogContext).pop(); // Đóng dialog
                  onCancel();
                }
              : null,
        );
      },
    );
  }

  Future<void> _handleSignIn() async {
    _dismissKeyboard(); // Ẩn bàn phím trước khi xử lý

    final String userName = _usernameController.text.trim();
    final String password = _passwordController.text.trim();

    // 1. Xác thực đầu vào
    if (userName.isEmpty || password.isEmpty) {
      _showAlertModal(
        title: 'Lỗi',
        message: 'Vui lòng điền đầy đủ tên đăng nhập và mật khẩu',
      );
      return;
    }

    // Kiểm tra định dạng username (chỉ chứa chữ cái, số, dấu gạch dưới hoặc gạch ngang)
    if (!RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(userName)) {
      _showAlertModal(
        title: 'Lỗi',
        message:
            'Tên đăng nhập chỉ được chứa chữ cái, số, dấu gạch dưới hoặc gạch ngang, không chứa khoảng trắng hoặc ký tự đặc biệt',
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // 2. Gọi API đăng nhập
      final loginResponse = await UserServices.loginUserApi(
        userName: userName,
        password: password,
      );
      final accessToken = loginResponse.data['accessToken'];
      final refreshToken = loginResponse.data['refreshToken'];

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('accessToken', accessToken);
      await prefs.setString('refreshToken', refreshToken);

      // 3. Lấy thông tin người dùng hiện tại
      final userResponse = await UserServices.getCurrentUserApi();
      final id = userResponse.data['id'];
      final userNameResponse = userResponse.data['userName'];
      final email = userResponse.data['email'];
      final fullname = userResponse.data['fullname'];
      final List<dynamic> roles = userResponse.data['roles']; // roles là List
      // Lấy userPackages và trích xuất packageNames
      final List<dynamic>? userPackages = userResponse.data['userPackages'];
      List<String> packageNames = [];
      if (userPackages != null) {
        packageNames = userPackages
            .map((item) => item['packageName'].toString())
            .toList();
      }

      debugPrint('User roles: ${roles[0]}');

      // Kiểm tra quyền của người dùng
      // Ở đây mày đang kiểm tra là 'Merchant', nếu user role là 'User' thì mới đúng với app User
      // Nếu đây là app Merchant, thì để nguyên là 'Merchant'
      // Tao giữ nguyên logic của mày, nếu user role không phải là 'Merchant', sẽ báo lỗi.
      if (roles[0] != 'Merchant') {
        debugPrint('Access denied: User does not have Merchant role');
        _showAlertModal(
          title: 'Truy cập bị từ chối',
          message: 'Bạn không có quyền để đăng nhập vào ứng dụng này.',
        );
        // Xóa token nếu không có quyền
        await prefs.clear();
        return; // Không chuyển màn hình nếu không có quyền
      }

      // Lưu trữ thông tin người dùng
      await prefs.setString('user_id', id);
      await prefs.setString('user_name', userNameResponse);
      debugPrint('User email: $userNameResponse');
      await prefs.setString('user_email', email);
      await prefs.setString('user_fullname', fullname);
      await prefs.setString('user_role', roles[0]); // Lưu role

      // LƯU TRỮ DANH SÁCH TÊN GÓI ĐÃ MUA
      // Chuyển List<String> thành chuỗi JSON và lưu vào SharedPreferences
      await prefs.setString('packageNames', jsonEncode(packageNames));
      debugPrint('Saved packageNames: ${packageNames.toString()}');


      // Chuyển hướng khi thành công
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => HomePage()), // HomeScreen là màn hình chứa các tab
            (Route<dynamic> route) => false, // Dòng này xóa tất cả các màn hình trước đó khỏi ngăn xếp
      );
    } catch (e) {
      debugPrint('Lỗi khi đăng nhập: $e');
      // Toast lỗi đã được xử lý bởi interceptor trong dio_customize.dart
      // Nếu muốn hiển thị modal thay vì toast cho lỗi API, thì bỏ comment dòng dưới
      // _showAlertModal(title: 'Lỗi đăng nhập', message: 'Tên đăng nhập hoặc mật khẩu không đúng. Vui lòng thử lại.', isSuccess: false);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final String colorScheme = themeNotifier.colorSchemeString;
    final Map<String, dynamic> styles = AppStyles.getSigninStyles(
      colorScheme,
      _isLoading,
    );

    return GestureDetector(
      onTap: _dismissKeyboard,
      child: Scaffold(
        backgroundColor: styles['container'].color,
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight:
                  MediaQuery.of(context).size.height -
                  MediaQuery.of(context).padding.top, // Trừ padding top cho status bar
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                SizedBox(
                  height: MediaQuery.of(context).padding.top + 20,
                ), // Đẩy nội dung xuống dưới status bar một chút
                // Logo
                Container(
                  margin: styles['logoContainer'],
                  alignment: Alignment.center,
                  child: Image.asset(
                    'assets/images/logo-merchant.png',
                    width: styles['logo'].width,
                    height: styles['logo'].height,
                  ),
                ),

                // Tiêu đề ĐĂNG NHẬP
                Align(
                  alignment: Alignment.topLeft,
                  child: Text('ĐĂNG NHẬP', style: styles['title']),
                ),

                const SizedBox(height: 10),

                // Tên đăng nhập
                Align(
                  alignment: Alignment.topLeft,
                  child: Text('Tên đăng nhập', style: styles['inputLabel']),
                ),
                Container(
                  margin: const EdgeInsets.only(bottom: 15),
                  decoration: styles['inputDecoration'],
                  child: TextField(
                    controller: _usernameController,
                    decoration: InputDecoration(
                      hintText: 'username',
                      hintStyle: AppFonts.comfortaaRegular.copyWith(
                        color: colorScheme == 'light'
                            ? AppColors.lightIcon
                            : AppColors.darkIcon,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 15,
                      ),
                    ),
                    style: styles['inputTextStyle'],
                    textCapitalization: TextCapitalization.none,
                    enabled: !_isLoading,
                  ),
                ),

                // Mật khẩu
                Align(
                  alignment: Alignment.topLeft,
                  child: Text('Mật khẩu', style: styles['inputLabel']),
                ),
                Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: styles['inputDecoration'],
                  child: Stack(
                    alignment: Alignment.centerRight,
                    children: [
                      TextField(
                        controller: _passwordController,
                        decoration: InputDecoration(
                          hintText: '••••••••',
                          hintStyle: AppFonts.comfortaaRegular.copyWith(
                            color: colorScheme == 'light'
                                ? AppColors.lightIcon
                                : AppColors.darkIcon,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.only(
                            left: 15,
                            right: 45,
                          ),
                        ),
                        style: styles['inputTextStyle'],
                        obscureText: _secureTextEntry,
                        textCapitalization: TextCapitalization.none,
                        enabled: !_isLoading,
                      ),
                      Positioned(
                        right: 15,
                        child: GestureDetector(
                          onTap: _togglePasswordVisibility,
                          child: Icon(
                            _secureTextEntry
                                ? Icons.visibility_off
                                : Icons.visibility,
                            size: 20,
                            color: styles['eyeIconColor'],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Quên mật khẩu
                Align(
                  alignment: Alignment.topRight,
                  child: GestureDetector(
                    onTap: () {
                      debugPrint('Chuyển đến màn hình Quên mật khẩu');
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const ForgotPasswordScreen()));
                    },
                    child: Text(
                      'Quên mật khẩu?',
                      style: styles['forgotPassword'],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Nút Đăng nhập
                GestureDetector(
                  onTap: _isLoading ? null : _handleSignIn,
                  child: Container(
                    width: double.infinity,
                    height: 50,
                    decoration: styles['loginButtonDecoration'],
                    alignment: Alignment.center,
                    child: _isLoading
                        ? const CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          )
                        : Text('Đăng nhập', style: styles['loginButtonText']),
                  ),
                ),

                const SizedBox(height: 20),

                // Đường phân cách "Hoặc tiếp tục với"
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Container(
                        height: 1,
                        color: styles['dividerLineColor'],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text(
                        'Hoặc tiếp tục với',
                        style: styles['dividerText'],
                      ),
                    ),
                    Expanded(
                      child: Container(
                        height: 1,
                        color: styles['dividerLineColor'],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Các nút đăng nhập xã hội
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[
                    Container(
                      width: 50,
                      height: 50,
                      decoration: styles['socialButtonDecoration'],
                      child: IconButton(
                        icon: FaIcon(
                          FontAwesomeIcons.apple,
                          size: 24,
                          color: styles['socialIconColor'],
                        ),
                        onPressed: () {
                          debugPrint('Đăng nhập với Apple');
                        },
                      ),
                    ),
                    Container(
                      width: 50,
                      height: 50,
                      decoration: styles['socialButtonDecoration'],
                      child: IconButton(
                        icon: FaIcon(
                          FontAwesomeIcons.google,
                          size: 24,
                          color: styles['socialIconColor'],
                        ),
                        onPressed: () {
                          debugPrint('Đăng nhập với Google');
                        },
                      ),
                    ),
                    Container(
                      width: 50,
                      height: 50,
                      decoration: styles['socialButtonDecoration'],
                      child: IconButton(
                        icon: FaIcon(
                          FontAwesomeIcons.facebookF,
                          size: 24,
                          color: styles['socialIconColor'],
                        ),
                        onPressed: () {
                          debugPrint('Đăng nhập với Facebook');
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Đăng ký tài khoản mới
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text(
                      'Bạn chưa có tài khoản? ',
                      style: styles['signupText'],
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          // Dùng push thay vì pushReplacement để có thể quay lại SignIn
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SignUpScreen(),
                          ),
                        );
                      },
                      child: Text(
                        'Đăng ký tại đây',
                        style: styles['signupLink'],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: MediaQuery.of(context).padding.bottom + 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}