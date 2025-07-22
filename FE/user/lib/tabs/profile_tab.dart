import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:user/tabs/check_login_view.dart';
import 'package:user/tabs/profile_view.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  // null: đang check, true: có token, false: không có token
  bool? _hasToken;

  @override
  void initState() {
    super.initState();
    _checkToken();
  }

  Future<void> _checkToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken');
    if (mounted) {
      setState(() {
        _hasToken = token != null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Dựa vào _hasToken để hiển thị màn hình tương ứng
    if (_hasToken == null) {
      // Trạng thái đang load, chưa check xong
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    } else if (_hasToken == true) {
      // Đã đăng nhập -> Hiển thị ProfileView
      return const ProfileView();
    } else {
      // Chưa đăng nhập -> Hiển thị CheckLoginView
      return const CheckLoginView();
    }
  }
}