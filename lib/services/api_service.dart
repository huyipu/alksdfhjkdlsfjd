import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/app_config.dart';
import '../utils/prefs.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  late final Dio _dio;
  bool _inited = false;
  AppConfig? _config;

  /// 后台 app_code（与 tlbb-admin「APP管理」一致，双端共用一个）
  static const String appCode = 'tlbb';

  /// 后台接口密钥（tlbb-admin → APP管理 → 接口密钥；空则后台跳过签名校验）
  static const String appSecret = '3d3b182228bcddb95ecccc7eba0f4835a5919241a0b3560b';

  AppConfig? get config => _config;
  String get baseUrl => _dio.options.baseUrl;

  /// 平台标记：android / ios（统计与配置平台覆盖都靠它）
  /// Web 端不支持 Platform，按 android 上报以保证后台配置/统计兼容
  static String get platform {
    if (kIsWeb) return 'android';
    return Platform.isIOS ? 'ios' : 'android';
  }

  /// 接口地址：默认本机局域网调试地址；打包/部署用 --dart-define=API_BASE_URL=xxx 覆盖
  static const String _baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://192.168.0.102:3010',
  );

  void init() {
    if (_inited) return; // 幂等：无网络重试时 _boot 会再次调用
    _inited = true;
    _dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ));
  }

  // ---------------- HMAC 签名（见 docs/App端接口签名对接指南.md） ----------------

  Map<String, String> _signedHeaders(String rawBody) {
    if (appSecret.isEmpty) return {};
    final ts = (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();
    final bodyHash = sha256.convert(utf8.encode(rawBody)).toString();
    final sign = Hmac(sha256, utf8.encode(appSecret))
        .convert(utf8.encode('$appCode\n$ts\n$bodyHash'))
        .toString();
    return {
      'X-App-Code': appCode,
      'X-Timestamp': ts,
      'X-Sign': sign,
    };
  }

  // ---------------- 配置 ----------------

  Future<AppConfig?> fetchConfig() async {
    try {
      final response = await _dio.get(
        '/api/v1/config',
        queryParameters: {'app_code': appCode, 'platform': platform},
        options: Options(headers: _signedHeaders('')),
      );
      if (response.statusCode == 200 &&
          response.data != null &&
          response.data is Map &&
          response.data['code'] == 0) {
        _config = AppConfig.fromJson(response.data);
        return _config;
      }
      // 业务码非 0（如签名失败 401）：按失败处理，走重试/退出弹窗
      print('fetchConfig rejected: ${response.data}');
    } catch (e) {
      print('fetchConfig error: $e');
    }
    return null;
  }

  // ---------------- 设备与统计 ----------------

  Future<String> getDeviceId() async {
    await Prefs().init();
    String? deviceId = Prefs().getString(Prefs.keyDeviceId);
    if (deviceId == null || deviceId.isEmpty) {
      deviceId = _generateDeviceId();
      await Prefs().setString(Prefs.keyDeviceId, deviceId);
      await reportStat('device');
    }
    return deviceId;
  }

  Future<void> reportStat(String field) async {
    try {
      final body = jsonEncode({
        'app_code': appCode,
        'field': field,
        'platform': platform,
      });
      await _dio.post('/api/app/stats',
          data: body,
          options: Options(
            contentType: Headers.jsonContentType,
            headers: _signedHeaders(body),
          ));
    } catch (e) {
      print('reportStat error: $e');
    }
  }

  /// 事件名 → 触发来源映射（TrackService/检测模式写入，日志上报时读取）
  final Map<String, String> eventSources = {};

  /// 上报 SDK 事件发送日志到后台（受后台 log_report_enable 开关控制）
  Future<void> reportEventLog(
    String eventName, {
    String? requestId,
    bool success = true,
    int? reason,
  }) async {
    if (_config?.logReportEnable != true) return;
    try {
      var deviceId = Prefs().getString(Prefs.keyDeviceId) ?? '';
      if (deviceId.isEmpty) {
        deviceId = await getDeviceId();
      }
      final payload = <String, dynamic>{
        'app_code': appCode,
        'event_name': eventName,
        'request_id': requestId,
        'success': success,
        'reason': reason,
        'device_id': deviceId,
        'platform': platform,
        'source': eventSources[eventName] ??
            (eventName == 'init' ||
                    eventName.startsWith('launch_app') ||
                    eventName == 'play_session' ||
                    eventName == 'session_sync'
                ? 'sdk_auto'
                : ''),
        'client_time': DateTime.now().toIso8601String(),
      };
      if (!Platform.isIOS) {
        payload['android_id'] = Prefs().getString(Prefs.keyAndroidId) ?? '';
      }
      final body = jsonEncode(payload);
      await _dio.post('/api/app/event-log',
          data: body,
          options: Options(
            contentType: Headers.jsonContentType,
            headers: _signedHeaders(body),
          ));
    } catch (e) {
      print('reportEventLog error: $e');
    }
  }

  // ---------------- 意见反馈 ----------------

  /// 提交意见反馈，成功返回 true（后台 code==0）
  Future<bool> submitFeedback({
    required String category,
    required String content,
    String contact = '',
  }) async {
    try {
      final body = jsonEncode({
        'app_code': appCode,
        'platform': platform,
        'category': category,
        'content': content,
        'contact': contact,
        'device_id': Prefs().getString(Prefs.keyDeviceId) ?? '',
      });
      final response = await _dio.post('/api/app/feedback',
          data: body,
          options: Options(
            contentType: Headers.jsonContentType,
            headers: _signedHeaders(body),
          ));
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data is Map ? response.data : jsonDecode(response.data.toString());
        return data['code'] == 0;
      }
    } catch (e) {
      print('submitFeedback error: $e');
    }
    return false;
  }

  String _generateDeviceId() {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final rand = Random.secure();
    return List.generate(16, (_) => chars[rand.nextInt(chars.length)]).join();
  }
}
