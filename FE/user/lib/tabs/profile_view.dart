import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:user/constants/app_colors.dart';
import 'package:user/constants/app_fonts.dart';
import 'package:user/screens/auth/signin_screen.dart';
import 'package:user/screens/settings_screen.dart';
import 'package:user/services/user_services.dart';

// Class để chứa thông tin User cho gọn
class UserInfo {
  final String fullName;
  final String email;
  final String? photoUrl;

  UserInfo({required this.fullName, required this.email, this.photoUrl});
}

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  bool _isLoading = true;
  UserInfo? _userInfo;

  @override
  void initState() {
    super.initState();
    _fetchUserInfo();
  }

  Future<void> _fetchUserInfo() async {
    // Không cần setState isLoading ở đây, tránh build lại không cần thiết
    try {
      final response = await UserServices.getCurrentUserApi();
      if (mounted) {
        setState(() {
          _userInfo = UserInfo(
            fullName: response.data['fullname'] ?? 'Unknown User',
            email: response.data['email'] ?? 'N/A',
            photoUrl: response.data['image'],
          );
          _isLoading = false; // Chuyển cờ loading vào đây
        });
      }
    } catch (error) {
      debugPrint('Lỗi lấy thông tin user: $error');
      // Nếu lỗi (ví dụ token hết hạn), xử lý đăng xuất
      _handleLogout();
    }
    // Không cần khối finally nữa
  }

  Future<void> _handleLogout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const SignInScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_userInfo == null) {
      // Có thể hiển thị một UI lỗi thân thiện hơn
      return const Scaffold(body: Center(child: Text('Không thể tải dữ liệu người dùng.')));
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: AppColors.lightTabBackground,
            expandedHeight: 200.0, // TAO TĂNG CHIỀU CAO LÊN CHO THOÁNG
            pinned: true,
            automaticallyImplyLeading: false,
            actions: [
              IconButton(
                icon: const Icon(Icons.settings_outlined, color: Colors.white),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SettingsScreen()),
                  );
                },
              ),
              // TAO ĐÃ BỎ NÚT LOGOUT Ở ĐÂY
            ],
            flexibleSpace: FlexibleSpaceBar(
              // TAO BỎ title ĐI VÌ ĐÃ GỘP VÀO background
              background: Container(
                color: AppColors.lightTabBackground, // Đảm bảo background có màu
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 40, // TAO TĂNG KÍCH THƯỚC AVATAR
                        backgroundColor: Colors.white,
                        backgroundImage: _userInfo!.photoUrl != null
                            ? NetworkImage(_userInfo!.photoUrl!)
                            : null,
                        child: _userInfo!.photoUrl == null
                            ? const Icon(Icons.person, size: 45, color: AppColors.lightIcon)
                            : null,
                      ),
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          _userInfo!.fullName,
                          textAlign: TextAlign.center,
                          style: AppFonts.baloo2ExtraBold.copyWith(
                            color: AppColors.lightWhiteText,
                            fontSize: 22, // TAO TĂNG FONT SIZE TÊN
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildListDelegate([
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Thông tin liên hệ',
                      style: AppFonts.comfortaaMedium.copyWith(fontSize: 16),
                    ),
                    const SizedBox(height: 10),
                    _buildInfoRow('Email', _userInfo!.email),
                    const Divider(),
                    // Thêm các dòng thông tin khác ở đây nếu mày muốn
                  ],
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppFonts.comfortaaRegular.copyWith(fontSize: 14)),
          const SizedBox(width: 16), // Thêm khoảng cách giữa label và value
          Expanded(
            child: Text(
              value,
              style: AppFonts.comfortaaRegular.copyWith(fontSize: 14, color: Colors.grey[700]), // Đổi màu cho dễ nhìn
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}