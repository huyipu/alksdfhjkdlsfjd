import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/app_config.dart';
import '../services/api_service.dart';
import '../services/track_service.dart';
import '../utils/flow_controller.dart';
import '../utils/prefs.dart';
import '../utils/theme.dart';
import '../widgets/app_logo.dart';

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
    // 避免隐私页内容为空；全部失败则弹窗让用户选择重试或退出（双端一致），
    // 不使用本地兜底配置——保证后台开关（合规/审核模式等）一定生效。
    AppConfig? config;
    for (var attempt = 0; attempt < 6 && config == null; attempt++) {
      if (attempt > 0) {
        await Future.delayed(const Duration(seconds: 2));
        if (!mounted) return;
      }
      config = await ApiService().fetchConfig();
    }
    if (config == null) {
      if (mounted) await _showNetworkErrorDialog();
      return;
    }
    TrackService().init(config);
    if (!mounted) return;
    // 启动页最短停留，给品牌露出
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    FlowController().start(context, config);
  }

  /// 无网络/服务不可达：阻塞弹窗，重试或退出（与隐私页"不同意并退出"同一语义）
  Future<void> _showNetworkErrorDialog() async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('网络连接失败'),
        content: const Text('请检查网络连接后重试。'),
        actions: [
          TextButton(
            onPressed: _exitApp,
            child: const Text('退出应用'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _boot();
            },
            child: const Text('重试'),
          ),
        ],
      ),
    );
  }

  void _exitApp() {
    // iOS 上 SystemNavigator.pop 无效果，直接结束进程（与隐私页退出语义一致）
    if (Platform.isIOS) {
      exit(0);
    } else {
      SystemNavigator.pop();
    }
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
                  child: AppLogo(size: 88),
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
