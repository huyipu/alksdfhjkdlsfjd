import 'package:flutter/material.dart';
import '../models/app_config.dart';
import '../services/ads_service.dart';
import '../services/track_service.dart';
import '../utils/anti_addiction.dart';
import '../utils/prefs.dart';
import '../pages/privacy_page.dart';
import '../pages/compliance_page.dart';
import '../pages/realname_page.dart';
import '../pages/guide_page.dart';
import '../pages/main_navigation.dart';

/// 启动流程调度：隐私 → 合规 → 实名 → 首屏弹窗（加群引导）→ 主页
///
/// 注意：每一步都必须用**当前页面自己的 context** 调 _next，
/// 不能用 start() 时缓存的 context（页面 pushReplacement 后旧 context 已卸载，导航会静默失效）。
class FlowController {
  static final FlowController _instance = FlowController._internal();
  factory FlowController() => _instance;
  FlowController._internal();

  late AppConfig _config;

  void start(BuildContext context, AppConfig config) {
    _config = config;

    // 记录本次启动时间戳（防沉迷计时基准，见 AntiAddictionScope）
    Prefs().setInt(Prefs.keyAppStartTime, DateTime.now().millisecondsSinceEpoch);

    // 已同意隐私政策时，每次冷启动都必须初始化巨量转化SDK（进程级：
    // 负责激活事件/归因clickid/上报管线；跳过则深度事件后台收不到）。
    // 未同意时不初始化，由 PrivacyPage 同意后初始化。
    if (Prefs().getBool(Prefs.keyPrivacyAccepted) ?? false) {
      AdsService.initAds().then((_) {
        TrackService().onSdkReady();
        TrackService().fire('app_start');
      });
    }

    _next(context);
  }

  void _next(BuildContext context) {
    final nav = Navigator.of(context);

    // 隐私协议
    if (_config.privacyEnable && !(Prefs().getBool(Prefs.keyPrivacyAccepted) ?? false)) {
      nav.pushReplacement(MaterialPageRoute(builder: (_) => PrivacyPage(config: _config)));
      return;
    }

    // 合规提示（适龄提示 + 健康忠告，任一开启且未展示过时显示）
    if (_shouldShowCompliance() && !(Prefs().getBool(Prefs.keyComplianceDone) ?? false)) {
      nav.pushReplacement(MaterialPageRoute(builder: (_) => CompliancePage(config: _config)));
      return;
    }

    // 实名认证（审核模式强制跳过，与加群引导一致：audit_mode 即审核安全态）
    if (!_config.auditMode && _config.realnameEnable && !(Prefs().getBool(Prefs.keyRealnameDone) ?? false)) {
      nav.pushReplacement(MaterialPageRoute(builder: (_) => RealnamePage(config: _config)));
      return;
    }

    // 首屏弹窗（加群引导）：必须有QQ号或Key才展示；
    // 审核模式（auditMode）下强制不展示，不管后台怎么配置（渠道检测用）
    if (!_config.auditMode &&
        _config.guideEnable &&
        (_config.guideQqNumber.isNotEmpty || _config.guideQqKey.isNotEmpty)) {
      nav.pushReplacement(MaterialPageRoute(builder: (_) => GuidePage(config: _config)));
      return;
    }

    // 进入主界面（包一层防沉迷计时）
    nav.pushReplacement(MaterialPageRoute(
      builder: (_) => AntiAddictionScope(config: _config, child: const MainNavigation()),
    ));
  }

  bool _shouldShowCompliance() {
    return _config.ageRatingEnable || _config.healthTipEnable;
  }

  /// 隐私页同意后调用（SDK 初始化/审核模式事件由 PrivacyPage 自己完成）
  void onPrivacyAccepted(BuildContext context) {
    _next(context);
  }

  void onComplianceDone(BuildContext context) {
    _next(context);
  }

  void onRealnameDone(BuildContext context) {
    _next(context);
  }

  void onGuideDone(BuildContext context) {
    _next(context);
  }
}
