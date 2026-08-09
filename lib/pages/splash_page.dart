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
    final config = await ApiService().fetchConfig();
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
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: AppColors.accent.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 6)),
                  ],
                ),
                child: const Center(
                  child: Text('龙',
                      style: TextStyle(
                        fontSize: 48,
                        color: Color(0xFFE8D9B0),
                        fontWeight: FontWeight.bold,
                        fontFamilyFallback: ['STKaiti', 'KaiTi', 'SimSun'],
                      )),
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
