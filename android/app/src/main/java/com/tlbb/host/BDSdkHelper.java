package com.tlbb.host;

import android.app.Activity;
import android.content.Context;
import android.util.Log;

import com.bytedance.ads.convert.BDConvert;
import com.bytedance.ads.convert.config.BDConvertConfig;
import com.bytedance.ads.convert.callback.BDConvertLifecycleCallback;
import com.bytedance.ads.convert.event.ConvertReportHelper;

import org.json.JSONObject;

/**
 * 巨量引擎 BDConvert SDK 辅助类（纯 Java 实现）
 * 异常不吞，全部向上抛出，由 Kotlin/Flutter 层处理
 */
public class BDSdkHelper {
    private static final String TAG = "BDSdkHelper";

    /// 事件发送结果监听器（由 MainActivity 注册，转发到 Flutter 层用于日志上报）
    public interface EventCallbackListener {
        void onEventResult(String eventName, String requestId, boolean success, int reason);
    }

    private static EventCallbackListener eventListener;

    public static void setEventListener(EventCallbackListener listener) {
        eventListener = listener;
    }

    private static void notifyEvent(String eventName, String requestId, boolean success, int reason) {
        if (eventListener != null) {
            eventListener.onEventResult(eventName, requestId, success, reason);
        }
    }

    /// 初始化广告 SDK（接入方式A：自动发送启动事件）
    public static void initAds(Activity activity, boolean enableLog, boolean enableOAID, boolean autoSendLaunchEvent) {
        BDConvertConfig config = new BDConvertConfig();
        config.setEnableLog(enableLog);
        config.setEnableOAID(enableOAID);
        config.setAutoSendLaunchEvent(autoSendLaunchEvent);
        config.setPlaySessionEnable(true);

        config.setLifecycleCallback(new BDConvertLifecycleCallback() {
            @Override
            public void onInitSuccess() {
                Log.d(TAG, "BDConvert onInitSuccess");
                notifyEvent("init", "", true, 0);
            }

            @Override
            public void onInitFailure(int reason, Throwable throwable) {
                Log.e(TAG, "BDConvert onInitFailure: reason=" + reason, throwable);
                notifyEvent("init", "", false, reason);
            }

            @Override
            public void onEventSendSuccess(String eventName, String requestId) {
                Log.d(TAG, "BDConvert onEventSendSuccess: eventName=" + eventName + ", requestId=" + requestId);
                notifyEvent(eventName, requestId, true, 0);
            }

            @Override
            public void onEventSendFailure(String eventName, int reason, String requestId, Throwable throwable) {
                Log.e(TAG, "BDConvert onEventSendFailure: eventName=" + eventName + ", reason=" + reason + ", requestId=" + requestId, throwable);
                notifyEvent(eventName, requestId, false, reason);
            }

            @Override
            public void onOtherError(int reason, Throwable throwable) {
                Log.e(TAG, "BDConvert onOtherError: reason=" + reason, throwable);
            }
        });

        BDConvert.INSTANCE.init(activity, config, activity);
        Log.d(TAG, "Ads init success");
    }

    /// 手动发送启动事件（接入方式B）
    public static void sendLaunchEvent(Context context) {
        BDConvert.INSTANCE.sendLaunchEvent(context);
        Log.d(TAG, "Send launch event success");
    }

    /// 上报注册事件
    public static void reportRegister(String channel, boolean success) {
        ConvertReportHelper.onEventRegister(channel, success);
        Log.d(TAG, "Report register: channel=" + channel + ", success=" + success);
    }

    /// 上报登录事件
    public static void reportLogin(String method, boolean success) {
        ConvertReportHelper.onLoginEvent(method, success);
        Log.d(TAG, "Report login: method=" + method + ", success=" + success);
    }

    /// 上报付费事件
    public static void reportPurchase(String contentType, String contentName, String contentId,
                                       int contentNumber, String paymentChannel, String currency,
                                       boolean isSuccess, int currencyAmount) {
        ConvertReportHelper.onEventPurchase(
                contentType, contentName, contentId,
                contentNumber, paymentChannel, currency, isSuccess, currencyAmount
        );
        Log.d(TAG, "Report purchase: amount=" + currencyAmount + ", currency=" + currency);
    }

    /// 上报自定义事件
    public static void reportCustomEvent(String eventName, JSONObject params) {
        ConvertReportHelper.onEventV3(eventName, params);
        Log.d(TAG, "Report custom event: eventName=" + eventName);
    }
}
