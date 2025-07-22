import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:user/constants/app_colors.dart';
import 'package:user/splash_screen.dart';
import 'package:user/utils/theme_notifier.dart';

void main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();
  // Load environment variables
  await dotenv.load(fileName: '.env');
  runApp(
    ChangeNotifierProvider(
      create: (context) => ThemeNotifier(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'User App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.lightPrimaryText,
          primary: AppColors.lightPrimaryText,
          background: AppColors.lightBackground,
        ),
        fontFamily: 'BeVietnamPro', // Sử dụng tên family bạn đã khai báo trong pubspec.yaml
        // Bạn cũng có thể tùy chỉnh thêm textTheme nếu muốn
        textTheme: Theme.of(context).textTheme.apply(
              fontFamily: 'BeVietnamPro',
            ),
        scaffoldBackgroundColor: AppColors.lightBackground,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.lightPrimaryText,
          foregroundColor: AppColors.lightWhiteText,
        ),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}