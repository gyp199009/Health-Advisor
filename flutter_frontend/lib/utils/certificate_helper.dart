import 'dart:io';
import 'package:flutter/foundation.dart';

/// 证书验证帮助类
/// 用于处理自签名证书的HTTPS连接
class CertificateHelper {
  /// 初始化HTTP客户端，允许自签名证书
  /// 仅在开发环境中使用
  static void allowSelfSignedCertificates() {
    if (kDebugMode) {
      HttpOverrides.global = _DevHttpOverrides();
      debugPrint('⚠️ 已配置允许自签名证书 - 仅用于开发环境');
    } else {
      debugPrint('✅ 生产环境中未启用自签名证书支持');
    }
  }
}

/// 开发环境HTTP覆盖
/// 允许所有证书，仅用于开发测试
class _DevHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) {
        // 允许所有证书，不进行验证
        // ⚠️ 警告：这在生产环境中是不安全的
        return true;
      };
  }
}