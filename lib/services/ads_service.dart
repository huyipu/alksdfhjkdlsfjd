import 'package:flutter/services.dart';

import 'api_service.dart';

class AdsService {
  // 注意：渠道名固定为 com.tlbb.host/ads，与应用包名(applicationId)无关，
  // 改包名时这里不需要动，需与 MainActivity.kt 中的 CHANNEL 保持一致。
  static const MethodChannel _channel =
      MethodChannel('com.tlbb.host/ads');

  static bool _callbackRegistered = false;

  /// 注册原生 → Dart 的事件发送结果回调（用于后台日志上报），幂等
  static void _ensureCallback() {
    if (_callbackRegistered) return;
    _callbackRegistered = true;
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onEventResult') {
        final args = Map<dynamic, dynamic>.from(call.arguments ?? {});
        ApiService().reportEventLog(
          args['eventName']?.toString() ?? '',
          requestId: args['requestId']?.toString(),
          success: args['success'] == true,
          reason: args['reason'] is int ? args['reason'] as int : null,
        );
      }
    });
  }

  /// Initialize BDConvert SDK (should be called after user accepts privacy policy)
  /// [autoSendLaunchEvent] default true - automatically send launch event after init
  /// [enableOAID] default true - collect OAID
  /// [enableLog] default true - enable SDK debug logs (联调排查期打开)
  static Future<bool> initAds({
    bool autoSendLaunchEvent = true,
    bool enableOAID = true,
    bool enableLog = true,
  }) async {
    try {
      _ensureCallback();
      final result = await _channel.invokeMethod<bool>('initAds', {
        'autoSendLaunchEvent': autoSendLaunchEvent,
        'enableOAID': enableOAID,
        'enableLog': enableLog,
      });
      print('[AdsService] initAds result: $result');
      return result ?? false;
    } catch (e) {
      print('[AdsService] initAds error: $e');
      return false;
    }
  }

  /// 获取系统 android_id（与巨量归因使用的设备ID一致）
  static Future<String?> getAndroidId() async {
    try {
      return await _channel.invokeMethod<String>('getAndroidId');
    } catch (e) {
      print('[AdsService] getAndroidId error: $e');
      return null;
    }
  }

  /// Send launch event manually (for mode B: when autoSendLaunchEvent is false)
  static Future<bool> sendLaunchEvent() async {
    try {
      final result = await _channel.invokeMethod<bool>('sendLaunchEvent');
      print('[AdsService] sendLaunchEvent result: $result');
      return result ?? false;
    } catch (e) {
      print('[AdsService] sendLaunchEvent error: $e');
      return false;
    }
  }

  static Future<bool> reportRegister({
    String channel = 'default',
    bool success = true,
  }) async {
    try {
      final result = await _channel.invokeMethod<bool>('reportRegister', {
        'channel': channel,
        'success': success,
      });
      print('[AdsService] reportRegister(channel: $channel, success: $success) result: $result');
      return result ?? false;
    } catch (e) {
      print('[AdsService] reportRegister error: $e');
      return false;
    }
  }

  static Future<bool> reportLogin({
    String method = 'default',
    bool success = true,
  }) async {
    try {
      final result = await _channel.invokeMethod<bool>('reportLogin', {
        'method': method,
        'success': success,
      });
      print('[AdsService] reportLogin(method: $method, success: $success) result: $result');
      return result ?? false;
    } catch (e) {
      print('[AdsService] reportLogin error: $e');
      return false;
    }
  }

  static Future<bool> reportPurchase({
    required double amount,
    String contentType = '',
    String contentName = '',
    String contentId = '',
    int contentNumber = 1,
    String paymentChannel = '',
    String currency = '¥',
    bool isSuccess = true,
  }) async {
    try {
      final result = await _channel.invokeMethod<bool>('reportPurchase', {
        'contentType': contentType,
        'contentName': contentName,
        'contentId': contentId,
        'contentNumber': contentNumber,
        'paymentChannel': paymentChannel,
        'currency': currency,
        'isSuccess': isSuccess,
        'currencyAmount': amount.toInt(),
      });
      print('[AdsService] reportPurchase(amount: $amount, currency: $currency) result: $result');
      return result ?? false;
    } catch (e) {
      print('[AdsService] reportPurchase error: $e');
      return false;
    }
  }

  /// 唤起 QQ 加群（原生实现：优先 qqKey 的 qm.qq.com scheme，其次 qqNumber 的 mqqapi）
  static Future<bool> openQQGroup({
    String qqNumber = '',
    String qqKey = '',
  }) async {
    try {
      final result = await _channel.invokeMethod<bool>('openQQGroup', {
        'qqNumber': qqNumber,
        'qqKey': qqKey,
      });
      print('[AdsService] openQQGroup(qqNumber: $qqNumber) result: $result');
      return result ?? false;
    } catch (e) {
      print('[AdsService] openQQGroup error: $e');
      return false;
    }
  }

  static Future<bool> reportCustomEvent({
    required String eventName,
    Map<String, dynamic> params = const {},
  }) async {
    try {
      final result = await _channel.invokeMethod<bool>('reportCustomEvent', {
        'eventName': eventName,
        'params': params,
      });
      print('[AdsService] reportCustomEvent(eventName: $eventName) result: $result');
      return result ?? false;
    } catch (e) {
      print('[AdsService] reportCustomEvent error: $e');
      return false;
    }
  }
}
