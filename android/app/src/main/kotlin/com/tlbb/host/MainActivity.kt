package com.tlbb.host

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.util.Log
import org.json.JSONObject

/**
 * Flutter MethodChannel 桥接层
 * 巨量引擎 SDK 调用委托给 BDSdkHelper.java，避免 Kotlin-Java 互操作编译问题
 */
class MainActivity : FlutterActivity() {
    companion object {
        // 渠道名固定，与应用包名(applicationId)无关，需与 ads_service.dart 保持一致
        private const val CHANNEL = "com.tlbb.host/ads"
        private const val TAG = "MainActivity"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        val channel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL
        )

        // SDK事件发送结果回调 → 转发到 Flutter 层（用于后台日志上报）
        BDSdkHelper.setEventListener { eventName, requestId, success, reason ->
            runOnUiThread {
                channel.invokeMethod(
                    "onEventResult",
                    mapOf(
                        "eventName" to eventName,
                        "requestId" to requestId,
                        "success" to success,
                        "reason" to reason
                    )
                )
            }
        }

        channel.setMethodCallHandler { call, result ->
            Log.d(TAG, "onMethodCall: method=${call.method}, args=${call.arguments}")
            when (call.method) {
                "initAds" -> {
                    try {
                        val enableLog = call.argument<Boolean>("enableLog") ?: false
                        val enableOAID = call.argument<Boolean>("enableOAID") ?: true
                        val autoSendLaunchEvent = call.argument<Boolean>("autoSendLaunchEvent") ?: true
                        BDSdkHelper.initAds(this, enableLog, enableOAID, autoSendLaunchEvent)
                        result.success(true)
                    } catch (t: Throwable) {
                        Log.e(TAG, "initAds error: ${t.message}", t)
                        result.success(false)
                    }
                }
                "getAndroidId" -> {
                    try {
                        val id = android.provider.Settings.Secure.getString(
                            contentResolver,
                            android.provider.Settings.Secure.ANDROID_ID
                        )
                        result.success(id)
                    } catch (t: Throwable) {
                        Log.e(TAG, "getAndroidId error: ${t.message}", t)
                        result.success(null)
                    }
                }
                "sendLaunchEvent" -> {                    try {
                        BDSdkHelper.sendLaunchEvent(this)
                        result.success(true)
                    } catch (t: Throwable) {
                        Log.e(TAG, "sendLaunchEvent error: ${t.message}", t)
                        result.success(false)
                    }
                }
                "reportRegister" -> {
                    try {
                        val channel = call.argument<String>("channel") ?: "default"
                        val success = call.argument<Boolean>("success") ?: true
                        BDSdkHelper.reportRegister(channel, success)
                        result.success(true)
                    } catch (t: Throwable) {
                        Log.e(TAG, "reportRegister error: ${t.message}", t)
                        result.success(false)
                    }
                }
                "reportLogin" -> {
                    try {
                        val method = call.argument<String>("method") ?: "default"
                        val success = call.argument<Boolean>("success") ?: true
                        BDSdkHelper.reportLogin(method, success)
                        result.success(true)
                    } catch (t: Throwable) {
                        Log.e(TAG, "reportLogin error: ${t.message}", t)
                        result.success(false)
                    }
                }
                "reportPurchase" -> {
                    try {
                        val contentType = call.argument<String>("contentType") ?: ""
                        val contentName = call.argument<String>("contentName") ?: ""
                        val contentId = call.argument<String>("contentId") ?: ""
                        val contentNumber = call.argument<Int>("contentNumber") ?: 1
                        val paymentChannel = call.argument<String>("paymentChannel") ?: ""
                        val currency = call.argument<String>("currency") ?: ""
                        val isSuccess = call.argument<Boolean>("isSuccess") ?: true
                        val currencyAmount = call.argument<Int>("currencyAmount") ?: 0
                        BDSdkHelper.reportPurchase(
                            contentType, contentName, contentId,
                            contentNumber, paymentChannel, currency, isSuccess, currencyAmount
                        )
                        result.success(true)
                    } catch (t: Throwable) {
                        Log.e(TAG, "reportPurchase error: ${t.message}", t)
                        result.success(false)
                    }
                }
                "reportCustomEvent" -> {
                    try {
                        val eventName = call.argument<String>("eventName") ?: ""
                        val params = call.argument<Map<String, Any>>("params") ?: emptyMap()
                        val jsonObject = JSONObject()
                        for ((key, value) in params) {
                            jsonObject.put(key, value)
                        }
                        BDSdkHelper.reportCustomEvent(eventName, jsonObject)
                        result.success(true)
                    } catch (t: Throwable) {
                        Log.e(TAG, "reportCustomEvent error: ${t.message}", t)
                        result.success(false)
                    }
                }
                "openQQGroup" -> {
                    try {
                        val qqNumber = call.argument<String>("qqNumber") ?: ""
                        val qqKey = call.argument<String>("qqKey") ?: ""

                        val intent = android.content.Intent()
                        val uriString = if (qqKey.isNotEmpty()) {
                            "mqqopensdkapi://bizAgent/qm/qr?url=http%3A%2F%2Fqm.qq.com%2Fcgi-bin%2Fqm%2Fqr%3Ffrom%3Dapp%26p%3Dandroid%26jump_from%3Dwebapi%26k%3D$qqKey"
                        } else {
                            "mqqapi://card/show_pslcard?src_type=internal&version=1&uin=$qqNumber&card_type=group&source=qrcode"
                        }
                        intent.data = android.net.Uri.parse(uriString)

                        try {
                            startActivity(intent)
                            result.success(true)
                        } catch (t: Throwable) {
                            Log.e(TAG, "openQQGroup startActivity failed: ${t.message}")
                            result.success(false)
                        }
                    } catch (t: Throwable) {
                        Log.e(TAG, "openQQGroup error: ${t.message}", t)
                        result.success(false)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }
}
