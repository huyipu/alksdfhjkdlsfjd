import 'dart:async';

import '../models/app_config.dart';
import '../utils/prefs.dart';
import 'ads_service.dart';
import 'api_service.dart';

/// 配置驱动的事件上报调度器
///
/// 后台 events 配置组下发规则（见 AppConfig.trackRules），
/// 客户端在各业务点调用 fire(trigger)，由本类按规则执行上报。
/// SDK 未初始化完成前触发的事件会进入队列，初始化完成后补发。
class TrackService {
  static final TrackService _instance = TrackService._internal();
  factory TrackService() => _instance;
  TrackService._internal();

  bool _enable = false;
  List<TrackRule> _rules = [];
  bool _sdkReady = false;
  final Set<String> _sessionFired = {};
  final List<String> _pendingTriggers = [];

  /// splash 拉取到配置后调用
  void init(AppConfig config) {
    // SDK检测模式下不走配置规则，固定只发 激活/心跳/注册/付费 四个事件
    _enable = config.eventsEnable && !config.auditMode;
    _rules = config.trackRules;
    _sdkReady = false;
    _sessionFired.clear();
    _pendingTriggers.clear();
    print('[TrackService] init: enable=$_enable, rules=${_rules.length}');
  }

  /// 巨量 SDK 初始化完成后调用（FlowController / PrivacyPage）
  void onSdkReady() {
    if (_sdkReady) return;
    _sdkReady = true;
    if (_pendingTriggers.isNotEmpty) {
      print('[TrackService] flush pending triggers: $_pendingTriggers');
      for (final t in List.of(_pendingTriggers)) {
        _fireNow(t);
      }
      _pendingTriggers.clear();
    }
  }

  /// 业务触发点。SDK 未就绪时自动排队，init 完成后补发。
  void fire(String trigger) {
    if (!_enable) return;
    if (!_sdkReady) {
      _pendingTriggers.add(trigger);
      return;
    }
    _fireNow(trigger);
  }

  void _fireNow(String trigger) {
    for (final rule in _rules.where((r) => r.trigger == trigger)) {
      unawaited(_execute(rule));
    }
  }

  Future<void> _execute(TrackRule rule) async {
    if (!await _checkAndMarkOnce(rule)) {
      print('[TrackService] skip rule=${rule.id} (once=${rule.once} already fired)');
      return;
    }
    if (rule.delaySeconds > 0) {
      await Future.delayed(Duration(seconds: rule.delaySeconds));
    }
    print('[TrackService] fire rule=${rule.id} type=${rule.type} event=${rule.eventName}');
    // 记录触发来源，供日志上报时关联（SDK事件名 → 触发点/规则名）
    // 注意：SDK 内部事件名与 type 不完全一致（login → log_in）
    const sdkNameMap = {'register': 'register', 'login': 'log_in', 'purchase': 'purchase'};
    final sdkEventName = rule.type == 'custom'
        ? rule.eventName
        : (sdkNameMap[rule.type] ?? rule.type);
    final source = rule.id.isNotEmpty ? '${rule.trigger}/${rule.id}' : rule.trigger;
    if (sdkEventName.isNotEmpty) {
      ApiService().eventSources[sdkEventName] = source;
      ApiService().eventSources[rule.type] = source; // 双写兜底
    }
    try {
      switch (rule.type) {
        case 'register':
          await AdsService.reportRegister(
            channel: _str(rule.params, 'channel', fallback: 'default'),
            success: _bool(rule.params, 'is_success', fallback: true),
          );
          break;
        case 'purchase':
          await AdsService.reportPurchase(
            amount: _num(rule.params, 'amount', fallback: 0).toDouble(),
            contentType: _str(rule.params, 'content_type'),
            contentName: _str(rule.params, 'content_name'),
            contentId: _str(rule.params, 'content_id'),
            contentNumber: _num(rule.params, 'content_number', fallback: 1).toInt(),
            paymentChannel: _str(rule.params, 'payment_channel'),
            currency: _str(rule.params, 'currency', fallback: '¥'),
            isSuccess: _bool(rule.params, 'is_success', fallback: true),
          );
          break;
        case 'login':
          await AdsService.reportLogin(
            method: _str(rule.params, 'method', fallback: 'default'),
            success: _bool(rule.params, 'is_success', fallback: true),
          );
          break;
        default: // custom
          if (rule.eventName.isEmpty) return;
          await AdsService.reportCustomEvent(
            eventName: rule.eventName,
            params: rule.params,
          );
      }
    } catch (e) {
      print('[TrackService] rule=${rule.id} error: $e');
    }
  }

  /// once 去重：no=每次都报；session=每进程一次；day=每天一次；install=每设备一次
  Future<bool> _checkAndMarkOnce(TrackRule rule) async {
    switch (rule.once) {
      case 'session':
        if (_sessionFired.contains(rule.id)) return false;
        _sessionFired.add(rule.id);
        return true;
      case 'day':
        final key = 'track_once_day_${rule.id}';
        final today = _todayStamp();
        if (Prefs().getString(key) == today) return false;
        await Prefs().setString(key, today);
        return true;
      case 'install':
        final key = 'track_once_install_${rule.id}';
        if (Prefs().getBool(key) ?? false) return false;
        await Prefs().setBool(key, true);
        return true;
      default: // 'no'
        return true;
    }
  }

  String _todayStamp() {
    final now = DateTime.now();
    return '${now.year}-${now.month}-${now.day}';
  }

  String _str(Map<String, dynamic> p, String key, {String fallback = ''}) {
    final v = p[key];
    return v == null ? fallback : v.toString();
  }

  bool _bool(Map<String, dynamic> p, String key, {bool fallback = false}) {
    final v = p[key];
    if (v is bool) return v;
    if (v is String) return v.toLowerCase() == 'true';
    if (v is num) return v != 0;
    return fallback;
  }

  num _num(Map<String, dynamic> p, String key, {num fallback = 0}) {
    final v = p[key];
    if (v is num) return v;
    return num.tryParse(v?.toString() ?? '') ?? fallback;
  }
}
