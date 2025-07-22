import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:merchant/constants/app_colors.dart';
import 'package:merchant/constants/app_fonts.dart';

class LanguageSettingsScreen extends StatefulWidget {
  const LanguageSettingsScreen({super.key});

  @override
  State<LanguageSettingsScreen> createState() => _LanguageSettingsScreenState();
}

class _LanguageSettingsScreenState extends State<LanguageSettingsScreen> {
  String _activeLanguage = 'vi';
  static const String _languageKey = 'appLanguage';

  @override
  void initState() {
    super.initState();
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _activeLanguage = prefs.getString(_languageKey) ?? 'vi';
    });
  }

  Future<void> _handleLanguageSelect(String lang) async {
    // Tạm thời chỉ cho chọn Tiếng Việt
    if (lang == 'en') {
      return;
    }
    setState(() {
      _activeLanguage = lang;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, lang);
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cài đặt ngôn ngữ')),
      body: Column(
        children: [
          _buildLanguageRow(
            context,
            code: 'vi',
            name: 'Tiếng Việt',
            enabled: true,
          ),
          const Divider(height: 1),
          _buildLanguageRow(
            context,
            code: 'en',
            name: 'English',
            enabled: false, // Vô hiệu hóa tiếng Anh
          ),
        ],
      ),
    );
  }

  // Widget helper cho gọn
  Widget _buildLanguageRow(BuildContext context, {required String code, required String name, required bool enabled}) {
    final bool isActive = _activeLanguage == code;
    return ListTile(
      title: Text(
        name,
        style: AppFonts.comfortaaRegular.copyWith(
          fontSize: 16,
          color: enabled ? AppColors.lightText : AppColors.lightIcon,
        ),
      ),
      trailing: isActive 
        ? const Icon(Icons.check_circle, color: AppColors.lightPrimaryText) 
        : null,
      onTap: enabled ? () => _handleLanguageSelect(code) : null,
      enabled: enabled,
    );
  }
}