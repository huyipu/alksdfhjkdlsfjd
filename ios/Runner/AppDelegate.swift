import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  private let adsChannelName = "com.tlbb.host/ads"
  private var adsChannel: FlutterMethodChannel?
  private var adsSdkStarted = false

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // 巨量转化SDK：隐私合规要求——先开启延时上报并传入启动参数，
    // 等用户在隐私弹窗点「同意」后（Dart 调 initAds）才真正开始采集上报
    BDASignalManager.enableDelayUpload()
    let bdaLaunchOptions = launchOptions?.reduce(into: [AnyHashable: Any]()) { $0[$1.key] = $1.value }
    BDASignalManager.didFinishLaunching(options: bdaLaunchOptions, connect: nil)

    let controller = window?.rootViewController as! FlutterViewController
    let channel = FlutterMethodChannel(name: adsChannelName, binaryMessenger: controller.binaryMessenger)
    adsChannel = channel
    channel.setMethodCallHandler { [weak self] call, result in
      self?.handleAdsCall(call, result: result)
    }

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // Deeplink 调起时把 URL 交给 SDK 提取 clickid 做归因
  override func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey: Any] = [:]
  ) -> Bool {
    BDASignalManager.anylyseDeeplinkClickid(withOpenUrl: url.absoluteString)
    return super.application(app, open: url, options: options)
  }

  // ---------------- com.tlbb.host/ads 方法通道 ----------------

  private func handleAdsCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    let args = call.arguments as? [String: Any] ?? [:]
    switch call.method {
    case "initAds":
      // 用户已同意隐私协议：注册可选参数并允许 SDK 开始上报（含排队的冷启动事件）
      BDASignalManager.register(withOptionalData: [:])
      BDASignalManager.startSendingEvents()
      adsSdkStarted = true
      notifyEventResult(eventName: "init", success: true)
      result(true)

    case "sendLaunchEvent":
      // 延时上报模式下冷启动事件已在启动时排队，startSendingEvents 后由 SDK 自动补发
      notifyEventResult(eventName: "launch_app", success: true)
      result(true)

    case "reportRegister":
      let channel = args["channel"] as? String ?? "default"
      let success = args["success"] as? Bool ?? true
      BDASignalManager.trackEssentialEvent(
        withName: kBDADSignalSDKEventRegister,
        params: ["channel": channel, "is_success": success]
      )
      notifyEventResult(eventName: "register", success: true)
      result(true)

    case "reportLogin":
      let method = args["method"] as? String ?? "default"
      let success = args["success"] as? Bool ?? true
      // SDK 无内置登录事件，使用自定义事件名 log_in
      BDASignalManager.trackEssentialEvent(
        withName: "log_in",
        params: ["method": method, "is_success": success]
      )
      notifyEventResult(eventName: "log_in", success: true)
      result(true)

    case "reportPurchase":
      var params: [String: Any] = [:]
      // SDK 约定付费金额字段为 pay_amount，单位：分
      params["pay_amount"] = args["currencyAmount"] ?? 0
      for key in ["contentType", "contentName", "contentId", "paymentChannel", "currency"] {
        if let v = args[key] as? String, !v.isEmpty { params[key] = v }
      }
      if let n = args["contentNumber"] { params["contentNumber"] = n }
      if let s = args["isSuccess"] { params["is_success"] = s }
      BDASignalManager.trackEssentialEvent(
        withName: kBDADSignalSDKEventPurchase,
        params: params
      )
      notifyEventResult(eventName: "purchase", success: true)
      result(true)

    case "reportCustomEvent":
      let eventName = args["eventName"] as? String ?? ""
      let params = args["params"] as? [String: Any] ?? [:]
      guard !eventName.isEmpty else {
        result(false)
        return
      }
      BDASignalManager.trackEssentialEvent(withName: eventName, params: params)
      notifyEventResult(eventName: eventName, success: true)
      result(true)

    case "openQQGroup":
      let qqNumber = args["qqNumber"] as? String ?? ""
      let qqKey = args["qqKey"] as? String ?? ""
      result(openQQGroup(number: qqNumber, key: qqKey))

    default:
      result(FlutterMethodNotImplemented)
    }
  }

  /// 回告 Dart 侧事件发送结果 → ApiService.reportEventLog 上传到后台事件日志
  private func notifyEventResult(eventName: String, success: Bool, requestId: String? = nil, reason: Int? = nil) {
    var payload: [String: Any] = ["eventName": eventName, "success": success]
    if let requestId = requestId { payload["requestId"] = requestId }
    if let reason = reason { payload["reason"] = reason }
    DispatchQueue.main.async { [weak self] in
      self?.adsChannel?.invokeMethod("onEventResult", arguments: payload)
    }
  }

  /// 唤起 QQ 加群：优先 qqKey 的 mqqopensdkapi 直拉加群页，
  /// 未装 QQ 退到 qm.qq.com 网页加群，最后兜底 mqqapi 群名片 scheme
  private func openQQGroup(number: String, key: String) -> Bool {
    if !key.isEmpty {
      let inner = "http://qm.qq.com/cgi-bin/qm/qr?from=app&p=ios&jump_from=webapi&k=\(key)"
      if let encoded = inner.addingPercentEncoding(withAllowedCharacters: .alphanumerics),
         let url = URL(string: "mqqopensdkapi://bizAgent/qm/qr?url=\(encoded)"),
         UIApplication.shared.canOpenURL(url) {
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
        return true
      }
      if let url = URL(string: "https://qm.qq.com/q/\(key)") {
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
        return true
      }
    }
    if !number.isEmpty,
       let url = URL(string: "mqqapi://card/show_pslcard?src_type=internal&version=1&card_type=group&source=external&uin=\(number)"),
       UIApplication.shared.canOpenURL(url) {
      UIApplication.shared.open(url, options: [:], completionHandler: nil)
      return true
    }
    return false
  }
}
