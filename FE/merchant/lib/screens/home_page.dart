// lib/screens/home_page.dart
import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart'; // MỚI: Import GNav
import 'package:merchant/constants/app_colors.dart';

import 'package:merchant/tabs/statistics_tab.dart';
import 'package:merchant/tabs/restaurant_tab.dart';
import 'package:merchant/tabs/promotions_tab.dart';
import 'package:merchant/tabs/help_tab.dart';
import 'package:merchant/tabs/profile_tab.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  static const List<Widget> _widgetOptions = <Widget>[
    StatisticsTab(),
    RestaurantTab(),
    PromotionsTab(),
    HelpTab(),
    ProfileTab(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      // THAY ĐỔI: Sử dụng GNav thay cho BottomNavigationBar
      bottomNavigationBar: Container(
        // Thêm một lớp Container để có thể đổ bóng và tùy biến màu nền
        decoration: BoxDecoration(
          color: AppColors.lightTabBackground,
          boxShadow: [
            BoxShadow(
              blurRadius: 20,
              color: Colors.black.withOpacity(.1),
            )
          ],
        ),
        // MỚI: Bọc GNav trong SafeArea để tránh bị các thành phần hệ thống che khuất
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: GNav(
              rippleColor: Colors.grey[300]!,
              hoverColor: Colors.grey[100]!,
              gap: 8, // Khoảng cách giữa icon và chữ
              activeColor: Colors.white, // Màu của icon và chữ khi được chọn
              iconSize: 24,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              duration: const Duration(milliseconds: 400),
              tabBackgroundColor: AppColors.lightTabIconSelected.withOpacity(0.8), // Màu nền của tab khi được chọn
              color: AppColors.lightTabIconDefault, // Màu của icon và chữ khi không được chọn
              tabs: const [
                GButton(
                  icon: Icons.bar_chart,
                  text: 'Số liệu',
                ),
                GButton(
                  icon: Icons.storefront,
                  text: 'Quán ăn',
                ),
                GButton(
                  icon: Icons.campaign,
                  text: 'Quảng bá',
                ),
                GButton(
                  icon: Icons.help_outline,
                  text: 'Trợ giúp',
                ),
                GButton(
                  icon: Icons.person_outline,
                  text: 'Của tôi',
                ),
              ],
              selectedIndex: _selectedIndex,
              onTabChange: (index) {
                _onItemTapped(index);
              },
            ),
          ),
        ),
      ),
    );
  }
}