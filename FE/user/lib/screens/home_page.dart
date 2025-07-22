import 'package:flutter/material.dart';
import 'package:user/constants/app_colors.dart';
// Import các màn hình tab từ thư mục mới
import 'package:user/tabs/help_tab.dart';
import 'package:user/tabs/home_tab.dart';
import 'package:user/tabs/map_tab.dart';
import 'package:user/tabs/profile_tab.dart';
// Import gói google_nav_bar
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:user/constants/app_fonts.dart'; // Giả sử bạn có file này cho font chữ


class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0; // Index của tab đang được chọn

  // Danh sách các màn hình tương ứng với các tab
  static const List<Widget> _widgetOptions = <Widget>[
    HomeTab(),
    MapTab(),
    HelpTab(),
    ProfileTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Body sẽ hiển thị màn hình tương ứng với tab được chọn
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      // Thay thế BottomNavigationBar bằng GNav
    bottomNavigationBar: SafeArea( // <-- THÊM WIDGET NÀY
    bottom: true, // Chỉ áp dụng Safe Area ở phía dưới
    child: Container(
    color: AppColors.lightTabBackground,
    child: Padding(
    padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 8.0),
    child: GNav(
    rippleColor: AppColors.lightTabIconDefault,
    hoverColor: AppColors.lightTabIconSelected,
    gap: 8,
    activeColor: AppColors.lightTabIconSelected,
    iconSize: 24,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    duration: const Duration(milliseconds: 400),
    tabBackgroundColor: AppColors.lightTabBackground,
    color: AppColors.lightTabIconDefault,
    tabs: [
    GButton(
    icon: Icons.home,
    text: 'Trang chủ',
    textStyle: AppFonts.comfortaaMedium.copyWith(color: AppColors.lightTabIconSelected),
    ),
    GButton(
    icon: Icons.map_outlined,
    text: 'Bản đồ',
    textStyle: AppFonts.comfortaaMedium.copyWith(color: AppColors.lightTabIconSelected),
    ),
    GButton(
    icon: Icons.help_outline,
    text: 'Trợ Giúp',
    textStyle: AppFonts.comfortaaMedium.copyWith(color: AppColors.lightTabIconSelected),
    ),
    GButton(
    icon: Icons.person_outline,
    text: 'Của tôi',
    textStyle: AppFonts.comfortaaMedium.copyWith(color: AppColors.lightTabIconSelected),
    ),
    ],
    selectedIndex: _selectedIndex,
    onTabChange: (index) {
    setState(() {
    _selectedIndex = index;
    });
    },
    ),
    ),
    ),
    )
    );
  }}