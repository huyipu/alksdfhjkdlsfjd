import 'package:flutter/material.dart';
import 'prefs.dart';

/// 天龙亿旧主题：宣纸亮 / 墨夜暗 双主题（武侠怀旧调性）
///
/// 用法：
/// - 双端常量（不随主题变）：AppColors.primary / accent / qGreen 等静态常量
/// - 随主题变的颜色：页面里用 `AppColors.of(context).bg / .card / .ink / .inkLight / .bgGradient`
///   （旧写法 AppColors.bg 保留为亮色值，仅用于不需要随主题变的场景，新代码一律走 of(context)）
class AppColors {
  AppColors._();

  // 主色：暗金（双主题通用）
  static const Color primary = Color(0xFF9C7A3C);
  static const Color primaryLight = Color(0xFFC8A45D);
  static const Color accent = Color(0xFF7A1F1F); // 朱砂红（印章感）

  // 亮色：宣纸底 + 墨色
  static const Color bg = Color(0xFFF5F0E6);
  static const Color card = Color(0xFFFFFDF7);
  static const Color ink = Color(0xFF2B2B2B);
  static const Color inkLight = Color(0xFF6B6B6B);

  // 品质色（图鉴用，双主题通用）
  static const Color qGreen = Color(0xFF4CAF50);
  static const Color qBlue = Color(0xFF42A5F5);
  static const Color qPurple = Color(0xFFAB47BC);
  static const Color qOrange = Color(0xFFFF9800);

  static const LinearGradient bgGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFEFE7D6), Color(0xFFF5F0E6)],
  );

  /// 当前主题调色板（随暗色模式切换）
  static AppPalette of(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? AppPalette.dark : AppPalette.light;
  }

  static Color qualityColor(String quality) {
    switch (quality) {
      case 'green':
        return qGreen;
      case 'blue':
        return qBlue;
      case 'purple':
        return qPurple;
      case 'orange':
        return qOrange;
      default:
        return inkLight;
    }
  }

  static String qualityName(String quality) {
    switch (quality) {
      case 'green':
        return '精品';
      case 'blue':
        return '稀有';
      case 'purple':
        return '史诗';
      case 'orange':
        return '传说';
      default:
        return '普通';
    }
  }
}

/// 随主题变化的颜色集合
class AppPalette {
  final Color bg;
  final Color card;
  final Color ink;
  final Color inkLight;
  final LinearGradient bgGradient;

  const AppPalette({
    required this.bg,
    required this.card,
    required this.ink,
    required this.inkLight,
    required this.bgGradient,
  });

  /// 宣纸亮
  static const AppPalette light = AppPalette(
    bg: Color(0xFFF5F0E6),
    card: Color(0xFFFFFDF7),
    ink: Color(0xFF2B2B2B),
    inkLight: Color(0xFF6B6B6B),
    bgGradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFFEFE7D6), Color(0xFFF5F0E6)],
    ),
  );

  /// 墨夜暗：深夜墨色底 + 暖金文案点缀
  static const AppPalette dark = AppPalette(
    bg: Color(0xFF1B1A17),
    card: Color(0xFF262521),
    ink: Color(0xFFE8E2D4),
    inkLight: Color(0xFF9A948A),
    bgGradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF14130F), Color(0xFF1B1A17)],
    ),
  );
}

/// 主题模式控制器（跟随系统/亮/暗，持久化）
class ThemeController {
  static final ThemeController _instance = ThemeController._internal();
  factory ThemeController() => _instance;
  ThemeController._internal();

  final ValueNotifier<ThemeMode> mode = ValueNotifier(ThemeMode.system);

  Future<void> load() async {
    final v = Prefs().getString(Prefs.keyThemeMode);
    mode.value = switch (v) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  Future<void> setMode(ThemeMode m) async {
    mode.value = m;
    await Prefs().setString(Prefs.keyThemeMode, switch (m) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      _ => 'system',
    });
  }

  static String label(ThemeMode m) => switch (m) {
        ThemeMode.light => '亮色',
        ThemeMode.dark => '暗色',
        _ => '跟随系统',
      };
}

ThemeData buildAppTheme() {
  final p = AppPalette.light;
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      surface: p.bg,
    ),
    scaffoldBackgroundColor: p.bg,
    appBarTheme: AppBarTheme(
      backgroundColor: p.bg,
      foregroundColor: p.ink,
      elevation: 0,
      centerTitle: true,
    ),
    cardTheme: CardTheme(
      color: p.card,
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    tabBarTheme: TabBarTheme(
      labelColor: AppColors.primary,
      unselectedLabelColor: p.inkLight,
      indicatorColor: AppColors.primary,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: p.card,
      indicatorColor: AppColors.primaryLight.withOpacity(0.25),
      labelTextStyle: WidgetStateProperty.all(const TextStyle(fontSize: 12)),
    ),
    dialogTheme: DialogTheme(backgroundColor: p.card),
    bottomSheetTheme: BottomSheetThemeData(backgroundColor: p.card),
  );
}

ThemeData buildDarkTheme() {
  final p = AppPalette.dark;
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.dark,
      primary: AppColors.primaryLight,
      surface: p.bg,
    ),
    scaffoldBackgroundColor: p.bg,
    appBarTheme: AppBarTheme(
      backgroundColor: p.bg,
      foregroundColor: p.ink,
      elevation: 0,
      centerTitle: true,
    ),
    cardTheme: CardTheme(
      color: p.card,
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    tabBarTheme: TabBarTheme(
      labelColor: AppColors.primaryLight,
      unselectedLabelColor: p.inkLight,
      indicatorColor: AppColors.primaryLight,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: p.card,
      indicatorColor: AppColors.primaryLight.withOpacity(0.25),
      labelTextStyle: WidgetStateProperty.all(const TextStyle(fontSize: 12)),
    ),
    dialogTheme: DialogTheme(backgroundColor: p.card),
    bottomSheetTheme: BottomSheetThemeData(backgroundColor: p.card),
  );
}
