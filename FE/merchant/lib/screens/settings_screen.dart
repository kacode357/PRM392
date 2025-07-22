import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:merchant/constants/app_colors.dart';
import 'package:merchant/constants/app_fonts.dart';
import 'package:merchant/screens/auth/signin_screen.dart';
import 'package:merchant/screens/change_password_screen.dart';
import 'package:merchant/screens/language_settings_screen.dart';
import 'package:merchant/screens/personal_info_screen.dart';
// THÊM IMPORT NÀY
import 'package:merchant/screens/payment_history_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  // ... (Hàm _handleLogout giữ nguyên)
  Future<void> _handleLogout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); 
    
    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const SignInScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cài đặt'),
      ),
      backgroundColor: Colors.white,
      body: ListView(
        children: [
          // ---- Section Tài khoản ----
          _buildSectionTitle('Tài khoản'),
          _buildListTile(
            context,
            title: 'Thông tin cá nhân',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PersonalInfoScreen()),
              );
            },
          ),
          const Divider(height: 1, indent: 20, endIndent: 20),
          _buildListTile(
            context,
            title: 'Đổi mật khẩu',
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const ChangePasswordScreen()));
            },
          ),
           const Divider(height: 1, indent: 20, endIndent: 20),
          
          // ---- THÊM MỤC LỊCH SỬ GIAO DỊCH ----
          _buildListTile(
            context,
            title: 'Lịch sử giao dịch',
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const PaymentHistoryScreen()));
            },
          ),
          // ------------------------------------

          // ---- Section Cài đặt ----
          _buildSectionTitle('Cài đặt'),
          _buildListTile(
            context,
            title: 'Ngôn ngữ',
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const LanguageSettingsScreen()));
            },
          ),
          const SizedBox(height: 20),

          // ---- Nút Đăng xuất ----
          // ... (giữ nguyên)
          GestureDetector(
            onTap: () => _handleLogout(context),
            child: Text(
              'Đăng xuất',
              textAlign: TextAlign.center,
              style: AppFonts.comfortaaMedium.copyWith(
                fontSize: 16,
                color: AppColors.lightError,
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ... (Hàm _buildSectionTitle và _buildListTile giữ nguyên)
  Widget _buildSectionTitle(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      color: AppColors.lightGrayBackground,
      child: Text(
        title.toUpperCase(),
        style: AppFonts.comfortaaRegular.copyWith(
          fontSize: 14,
          color: AppColors.lightText,
        ),
      ),
    );
  }

  Widget _buildListTile(BuildContext context, {required String title, required VoidCallback onTap}) {
    return ListTile(
      title: Text(title, style: AppFonts.comfortaaRegular.copyWith(fontSize: 14)),
      trailing: const Icon(Icons.chevron_right, color: AppColors.lightIcon),
      onTap: onTap,
    );
  }
}