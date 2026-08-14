import 'dart:convert';

/// 后台配置驱动的事件上报规则
/// type: custom | register | purchase | login
/// once: no(每次) | session(每次启动一次) | day(每天一次) | install(每设备一次)
class TrackRule {
  final String id;
  final String trigger;
  final String type;
  final String eventName;
  final int delaySeconds;
  final String once;
  final Map<String, dynamic> params;

  TrackRule({
    this.id = '',
    this.trigger = '',
    this.type = 'custom',
    this.eventName = '',
    this.delaySeconds = 0,
    this.once = 'no',
    this.params = const {},
  });

  factory TrackRule.fromJson(Map<String, dynamic> json) {
    final rawParams = json['params'];
    return TrackRule(
      id: json['id']?.toString() ?? '',
      trigger: json['trigger']?.toString() ?? '',
      type: json['type']?.toString() ?? 'custom',
      eventName: json['event_name']?.toString() ?? '',
      delaySeconds: int.tryParse(json['delay_seconds']?.toString() ?? '0') ?? 0,
      once: json['once']?.toString() ?? 'no',
      params: rawParams is Map ? Map<String, dynamic>.from(rawParams) : {},
    );
  }

  /// 解析后台 events_rules JSON 字符串，容错：解析失败返回空列表
  static List<TrackRule> parseList(String? raw) {
    if (raw == null || raw.trim().isEmpty) return [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded
            .whereType<Map>()
            .map((e) => TrackRule.fromJson(Map<String, dynamic>.from(e)))
            .where((r) => r.trigger.isNotEmpty)
            .toList();
      }
    } catch (_) {}
    return [];
  }
}

class AppConfig {
  final int appId;
  final String appName;
  final String appSubtitle;
  final String appLogo;
  final String appSplash;
  final bool operationTipEnable;
  final String operationTip;
  final bool footerEnable;
  final String copyrightOwner;
  final String softCertNo;
  final String icpNo;
  final String developer;

  final bool privacyEnable;
  final String privacyTitle;
  final String privacyContent;

  final bool realnameEnable;
  final String realnameTitle;
  final String realnameContent;

  final bool guideEnable;
  final String guideScheme;
  final String guideTitle;
  final String guideText;
  final String guideImage;
  final String guideQqNumber;
  final String guideQqKey;
  final String verifyTitle;
  final String verifyDesc;
  final String verifyPlaceholder;
  final String verifyAnswer;

  final bool ageRatingEnable;
  final String ageRatingText;
  final String ageRatingIcon;
  final bool healthTipEnable;
  final String healthTipTitle;
  final String healthTip;

  final bool auditMode; // SDK检测模式：固定发激活/心跳/注册/付费四事件，弹窗强制关闭，不走events规则
  final bool antiAddictionEnable;
  final String antiAddictionText;
  final int antiAddictionTime;

  final bool eventsEnable; // 配置驱动事件上报总开关
  final List<TrackRule> trackRules; // 事件上报规则列表
  final bool logReportEnable; // SDK事件日志上报后台开关（联调期开启）

  AppConfig({
    this.appId = 0,
    this.appName = '',
    this.appSubtitle = '',
    this.appLogo = '',
    this.appSplash = '',
    this.operationTipEnable = false,
    this.operationTip = '',
    this.footerEnable = false,
    this.copyrightOwner = '',
    this.softCertNo = '',
    this.icpNo = '',
    this.developer = '',
    this.privacyEnable = false,
    this.privacyTitle = '',
    this.privacyContent = '',
    this.realnameEnable = false,
    this.realnameTitle = '',
    this.realnameContent = '',
    this.guideEnable = false,
    this.guideScheme = 'scheme_1',
    this.guideTitle = '',
    this.guideText = '',
    this.guideImage = '',
    this.guideQqNumber = '',
    this.guideQqKey = '',
    this.verifyTitle = '',
    this.verifyDesc = '',
    this.verifyPlaceholder = '',
    this.verifyAnswer = '',
    this.ageRatingEnable = false,
    this.ageRatingText = '',
    this.ageRatingIcon = '',
    this.healthTipEnable = false,
    this.healthTipTitle = '',
    this.healthTip = '',
    this.auditMode = false,
    this.antiAddictionEnable = false,
    this.antiAddictionText = '',
    this.antiAddictionTime = 60,
    this.eventsEnable = false,
    this.trackRules = const [],
    this.logReportEnable = false,
  });

  factory AppConfig.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? {};
    final configs = data['configs'] as Map<String, dynamic>? ?? {};

    final basic = _map(configs['basic']);
    final privacy = _map(configs['privacy']);
    final realname = _map(configs['realname']);
    final guide = _map(configs['guide']);
    final compliance = _map(configs['compliance']);
    final addiction = _map(configs['addiction']);
    final events = _map(configs['events']);

    return AppConfig(
      appId: data['app_id'] ?? 0,
      appName: basic['app_name'] ?? '',
      appSubtitle: basic['app_subtitle'] ?? '',
      appLogo: basic['app_logo'] ?? '',
      appSplash: basic['app_splash'] ?? '',
      operationTipEnable: _bool(basic['operation_tip_enable']),
      operationTip: basic['operation_tip'] ?? '',
      footerEnable: _bool(basic['footer_enable']),
      copyrightOwner: basic['copyright_owner'] ?? '',
      softCertNo: basic['soft_cert_no'] ?? '',
      icpNo: basic['icp_no'] ?? '',
      developer: basic['developer'] ?? '',
      auditMode: _bool(basic['audit_mode']),
      privacyEnable: _bool(privacy['privacy_enable']),
      privacyTitle: privacy['privacy_title'] ?? '',
      privacyContent: privacy['privacy_content'] ?? '',
      realnameEnable: _bool(realname['realname_enable']),
      realnameTitle: realname['realname_title'] ?? '',
      realnameContent: realname['realname_content'] ?? '',
      guideEnable: _bool(guide['guide_enable']),
      guideScheme: guide['guide_scheme'] ?? 'scheme_1',
      guideTitle: guide['guide_title'] ?? '',
      guideText: guide['guide_text'] ?? '',
      guideImage: guide['guide_image'] ?? '',
      guideQqNumber: guide['guide_qq_number'] ?? '',
      guideQqKey: guide['guide_qq_key'] ?? '',
      verifyTitle: guide['verify_title'] ?? '',
      verifyDesc: guide['verify_desc'] ?? '',
      verifyPlaceholder: guide['verify_placeholder'] ?? '',
      verifyAnswer: guide['verify_answer'] ?? '',
      ageRatingEnable: _bool(compliance['age_rating_enable']),
      ageRatingText: compliance['age_rating_text'] ?? '',
      ageRatingIcon: compliance['age_rating_icon'] ?? '',
      healthTipEnable: _bool(compliance['health_tip_enable']),
      healthTipTitle: compliance['health_tip_title'] ?? '',
      healthTip: compliance['health_tip'] ?? '',
      antiAddictionEnable: _bool(addiction['anti_addiction_enable']),
      antiAddictionText: addiction['anti_addiction_text'] ?? '',
      antiAddictionTime: int.tryParse(addiction['anti_addiction_time']?.toString() ?? '60') ?? 60,
      eventsEnable: _bool(events['events_enable']),
      trackRules: TrackRule.parseList(events['events_rules']?.toString()),
      logReportEnable: _bool(events['log_report_enable']),
    );
  }

  static Map<String, dynamic> _map(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    return {};
  }

  static bool _bool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is String) return value.toLowerCase() == 'true';
    return false;
  }
}
