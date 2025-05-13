import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'router.dart';
import 'utils/certificate_helper.dart';
import 'dart:io' show Platform;
import 'package:flutter/services.dart';

void main() {
  // 确保Flutter绑定初始化
  WidgetsFlutterBinding.ensureInitialized();
  
  // 允许自签名证书（开发环境）
  CertificateHelper.allowSelfSignedCertificates();
  
  // 在移动设备上设置首选方向
  if (Platform.isAndroid || Platform.isIOS) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }
  
  runApp(const HealthAdvisorApp());
}

class HealthAdvisorApp extends StatelessWidget {
  const HealthAdvisorApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Initialize AuthProvider
    final authProvider = AuthProvider();
    // Initialize AppRouter with AuthProvider
    final appRouter = AppRouter(authProvider: authProvider);

    return ChangeNotifierProvider<AuthProvider>.value(
      value: authProvider,
      child: MaterialApp.router(
        title: '健康顾问',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true, // 推荐用于现代Flutter应用
          // 根据屏幕大小调整字体大小
          textTheme: Typography.material2018().black.copyWith(
            bodyLarge: const TextStyle(fontSize: 16),
            bodyMedium: const TextStyle(fontSize: 14),
            bodySmall: const TextStyle(fontSize: 12),
            titleLarge: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            titleMedium: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            titleSmall: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            labelLarge: const TextStyle(fontSize: 14),
            labelMedium: const TextStyle(fontSize: 12),
            labelSmall: const TextStyle(fontSize: 10),
          ),
          // 调整输入框和按钮样式，使其在小屏幕上更易于点击
          inputDecorationTheme: InputDecorationTheme(
            contentPadding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
            filled: true,
            fillColor: Colors.grey.shade50,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
              minimumSize: const Size(88, 36), // 确保按钮有足够的触摸区域
            ),
          ),
          cardTheme: CardThemeData(
            elevation: 2.0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
            clipBehavior: Clip.antiAlias,
          ),
        ),
        // 添加响应式配置
        builder: (context, child) {
          // 获取设备信息
          final mediaQuery = MediaQuery.of(context);
          final screenSize = mediaQuery.size;
          final isSmallScreen = screenSize.width < 600;
          
          // 确保文本缩放不会过大，影响布局
          // 在小屏幕上使用更小的缩放范围
          final textScaleFactor = isSmallScreen 
              ? mediaQuery.textScaleFactor.clamp(0.8, 1.1)
              : mediaQuery.textScaleFactor.clamp(0.8, 1.2);
          
          return MediaQuery(
            data: mediaQuery.copyWith(
              textScaleFactor: textScaleFactor,
              // 添加安全区域填充，确保内容不会被系统UI遮挡
              padding: mediaQuery.padding,
            ),
            child: child!,
          );
        },
        routerConfig: appRouter.router, // 使用路由配置
        debugShowCheckedModeBanner: false, // 移除调试标记
      ),
    );
  }
}
