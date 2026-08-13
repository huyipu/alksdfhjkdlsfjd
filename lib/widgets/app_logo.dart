import 'package:flutter/material.dart';

/// App 内品牌 Logo：跟随主题——亮色用白天图，暗色用黑夜图。
/// （launcher 图标之外的 App 内展示统一走这里）
class AppLogo extends StatelessWidget {
  final double size;
  const AppLogo({super.key, required this.size});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Image.asset(
      isDark ? 'assets/logo/app_logo_dark.png' : 'assets/logo/app_logo_light.png',
      width: size,
      height: size,
      fit: BoxFit.cover,
    );
  }
}
