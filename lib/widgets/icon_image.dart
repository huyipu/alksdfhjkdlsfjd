import 'package:flutter/material.dart';

/// 图鉴图标：icon 为空或加载失败时回退到 Material 图标
class IconImage extends StatelessWidget {
  final String icon; // assets 相对路径，可为空
  final double size;
  final Color fallbackColor;
  final IconData fallback;
  final double radius;

  const IconImage({
    super.key,
    required this.icon,
    this.size = 40,
    this.fallbackColor = Colors.grey,
    this.fallback = Icons.shield_outlined,
    this.radius = 8,
  });

  @override
  Widget build(BuildContext context) {
    if (icon.isEmpty) return Icon(fallback, size: size, color: fallbackColor);
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Image.asset(
        icon,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Icon(fallback, size: size, color: fallbackColor),
      ),
    );
  }
}
