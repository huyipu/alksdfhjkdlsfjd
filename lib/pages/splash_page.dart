import 'package:flutter/material.dart';
import '../models/app_config.dart';
import '../services/api_service.dart';
import '../services/track_service.dart';
import '../utils/flow_controller.dart';
import '../utils/prefs.dart';
import '../utils/theme.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    await Prefs().init();
    ApiService().init();
    // 首次安装启动会触发 iOS「无线数据」授权弹窗，授权未完成前请求会失败。
    // 在启动页停留并间隔重试：用户完成授权后即可拿到配置，再进入隐私页，
    // 避免隐私页内容为空；全部失败则用本地兜底配置继续。
    AppConfig? config;
    for (var attempt = 0; attempt < 6 && config == null; attempt++) {
      if (attempt > 0) {
        await Future.delayed(const Duration(seconds: 2));
        if (!mounted) return;
      }
      config = await ApiService().fetchConfig();
    }
    final cfg = config ?? AppConfig(appName: '天龙亿旧', privacyEnable: true);
    TrackService().init(cfg);
    if (!mounted) return;
    // 启动页最短停留，给品牌露出
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    FlowController().start(context, cfg);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: AppColors.of(context).bgGradient),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: AppColors.accent.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 6)),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.asset('assets/logo/app_logo.png', width: 88, height: 88, fit: BoxFit.cover),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                '天龙亿旧',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 6,
                  color: AppColors.of(context).ink,
                  fontFamilyFallback: ['STKaiti', 'KaiTi', 'SimSun'],
                ),
              ),
              const SizedBox(height: 8),
              Text('经典网游怀旧图鉴攻略', style: TextStyle(fontSize: 13, color: AppColors.of(context).inkLight, letterSpacing: 2)),
            ],
          ),
        ),
      ),
    );
  }
}
