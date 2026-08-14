/// App 元信息（全 App 唯一配置点：公司名、版本、日期等只改这里）
class AppMeta {
  AppMeta._();

  static const String appName = '天龙亿旧';
  static const String slogan = '老天龙玩家的随身图鉴与时光机';
  static const String version = '1.1.0';
  // 开发者署名已改为后台 basic.developer 配置驱动（无值则隐去对应行），App 内不再写死
  static const String effectiveDate = '2026年8月7日'; // 用户协议/隐私政策生效日期
}
