# 巨量引擎广告 SDK
-keep class com.bytedance.ads.convert.** { *; }
-keep class com.bytedance.ad.** { *; }
-dontwarn com.bytedance.ads.convert.**
-dontwarn com.bytedance.ad.**

# Flutter 原生桥接（包名固定 com.tlbb.host，与 applicationId 无关）
-keep class com.tlbb.host.** { *; }
-keep class io.flutter.embedding.android.FlutterActivity { *; }
