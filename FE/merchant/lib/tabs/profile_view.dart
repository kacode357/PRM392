// lib/views/profile_view.dart (hoặc tên tệp của bạn)
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:merchant/constants/app_colors.dart';
import 'package:merchant/constants/app_fonts.dart';
import 'package:merchant/screens/auth/signin_screen.dart';
import 'package:merchant/screens/settings_screen.dart';
import 'package:merchant/services/user_services.dart';
import 'dart:convert';
import 'dart:ui'; // MỚI: Import để dùng BackdropFilter cho hiệu ứng kính mờ

// Class UserInfo giữ nguyên
class UserInfo {
  final String fullName;
  final String email;
  final String? photoUrl;
  final List<String> packageNames;

  UserInfo({
    required this.fullName,
    required this.email,
    this.photoUrl,
    required this.packageNames,
  });
}

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  // Toàn bộ logic xử lý state và fetch dữ liệu của bạn được giữ nguyên
  bool _isLoading = true;
  UserInfo? _userInfo;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _fetchUserInfo();
  }

  Future<void> _fetchUserInfo() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _hasError = false;
        _userInfo = null;
      });
    }

    try {
      final response = await UserServices.getCurrentUserApi();
      final prefs = await SharedPreferences.getInstance();
      List<String> currentPackageNames = [];

      final storedPackageNamesString = prefs.getString('packageNames');
      if (storedPackageNamesString != null && storedPackageNamesString.isNotEmpty) {
        try {
          final decoded = json.decode(storedPackageNamesString);
          if (decoded is List) {
            currentPackageNames = List<String>.from(decoded);
          }
        } catch (e) {
          debugPrint('Lỗi parse packageNames từ SharedPreferences: $e');
          currentPackageNames = [];
        }
      }

      if (mounted) {
        setState(() {
          _userInfo = UserInfo(
            fullName: response.data['fullname'] ?? 'Người dùng không xác định',
            email: response.data['email'] ?? 'Không có email',
            photoUrl: response.data['image'],
            packageNames: currentPackageNames,
          );
          _isLoading = false;
        });
      }
    } catch (error) {
      debugPrint('Lỗi lấy thông tin user: $error');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
      _handleLogout();
    }
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
  // Kết thúc phần logic

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(backgroundColor: AppColors.lightBackground, body: Center(child: CircularProgressIndicator()));
    }

    if (_userInfo == null || _hasError) {
      // Giao diện lỗi giữ nguyên, rất tốt rồi!
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.cloud_off, size: 64, color: AppColors.lightIcon),
                const SizedBox(height: 20),
                Text(
                  'Không thể tải dữ liệu người dùng.\nVui lòng kiểm tra kết nối và thử lại.',
                  textAlign: TextAlign.center,
                  style: AppFonts.comfortaaRegular.copyWith(color: AppColors.lightText, fontSize: 16),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  icon: const Icon(Icons.refresh),
                  label: Text('Thử lại', style: AppFonts.comfortaaMedium.copyWith(fontSize: 16)),
                  onPressed: _fetchUserInfo,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.lightPrimary,
                    foregroundColor: AppColors.lightWhiteText,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: _handleLogout,
                  style: TextButton.styleFrom(foregroundColor: AppColors.lightPrimaryText),
                  child: Text('Đăng xuất', style: AppFonts.comfortaaMedium.copyWith(fontSize: 16)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Giao diện chính đã được thiết kế lại
    String packageHeaderText;
    if (_userInfo!.packageNames.isEmpty) {
      packageHeaderText = 'Miễn phí';
    } else if (_userInfo!.packageNames.length == 1) {
      packageHeaderText = _userInfo!.packageNames[0];
    } else {
      packageHeaderText = 'Nhiều gói dịch vụ';
    }

    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      body: CustomScrollView(
        slivers: [
          // THAY ĐỔI: SliverAppBar được thiết kế lại hoàn toàn
          SliverAppBar(
            expandedHeight: 240.0,
            pinned: true,
            stretch: true,
            automaticallyImplyLeading: false,
            backgroundColor: AppColors.lightPrimary, // Màu nền khi cuộn lên
            elevation: 2,
            actions: [
              IconButton(
                icon: const Icon(Icons.settings_outlined, color: Colors.white),
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen())),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [StretchMode.zoomBackground],
              background: Container(
                // Sử dụng gradient để header trông nổi bật hơn
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFF9D423), Color(0xFFFF4E50)], // Gradient "Hoàng Hôn Rực Rỡ"
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 30), // Thêm khoảng cách với thanh trạng thái
                    // MỚI: Avatar có viền trắng để nổi bật
                    CircleAvatar(
                      radius: 42,
                      backgroundColor: Colors.white,
                      child: CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.grey.shade200,
                        backgroundImage: _userInfo!.photoUrl != null ? NetworkImage(_userInfo!.photoUrl!) : null,
                        child: _userInfo!.photoUrl == null ? const Icon(Icons.person, size: 45, color: Colors.grey) : null,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        _userInfo!.fullName,
                        textAlign: TextAlign.center,
                        style: AppFonts.baloo2ExtraBold.copyWith(color: Colors.white, fontSize: 24, shadows: [Shadow(blurRadius: 5.0, color: Colors.black.withOpacity(0.3), offset: const Offset(0, 1))]),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // MỚI: Chip trạng thái với hiệu ứng kính mờ
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 15),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
                          ),
                          child: Text(
                            packageHeaderText,
                            style: AppFonts.comfortaaExtraBold.copyWith(fontSize: 14, color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // THAY ĐỔI: SliverList được cấu trúc lại bằng các Card
          SliverPadding(
            padding: const EdgeInsets.all(16.0),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Thẻ thông tin liên hệ
                _buildInfoCard(
                  title: 'Thông tin liên hệ',
                  children: [
                    _buildInfoRowWithIcon(
                      icon: Icons.email_outlined,
                      label: 'Email',
                      value: _userInfo!.email,
                    ),
                  ],
                ),

                // Thẻ các gói dịch vụ (chỉ hiển thị nếu cần)
                if (_userInfo!.packageNames.length > 1) ...[
                  const SizedBox(height: 16),
                  _buildInfoCard(
                    title: 'Các gói dịch vụ đang dùng',
                    children: _userInfo!.packageNames.map((packageName) =>
                        _buildInfoRowWithIcon(
                          icon: Icons.card_membership_outlined,
                          label: packageName,
                          value: '', // Có thể để trống hoặc thêm thông tin khác
                        )
                    ).toList(),
                  ),
                ],

                // MỚI: Nút đăng xuất được đưa ra ngoài rõ ràng
                const SizedBox(height: 24),
                ListTile(
                  leading: const Icon(Icons.logout, color: AppColors.lightError),
                  title: Text('Đăng xuất', style: AppFonts.comfortaaBold.copyWith(color: AppColors.lightError)),
                  onTap: _handleLogout,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  tileColor: AppColors.lightError.withOpacity(0.08),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  // MỚI: Widget để tạo một thẻ thông tin chung
  Widget _buildInfoCard({required String title, required List<Widget> children}) {
    return Card(
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: AppFonts.comfortaaBold.copyWith(fontSize: 18, color: AppColors.lightText)),
            const SizedBox(height: 8),
            const Divider(),
            ...children,
          ],
        ),
      ),
    );
  }

  // MỚI: Widget để tạo một hàng thông tin có icon
  Widget _buildInfoRowWithIcon({required IconData icon, required String label, required String value}) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: AppColors.lightPrimary),
      title: Text(label, style: AppFonts.comfortaaMedium.copyWith(fontSize: 16, color: AppColors.lightText)),
      trailing: value.isNotEmpty
          ? Text(value, style: AppFonts.comfortaaRegular.copyWith(fontSize: 14, color: AppColors.lightIcon))
          : null,
    );
  }
}