import 'dart:async';
import 'package:flutter/material.dart';
import '../models/app_config.dart';
import 'prefs.dart';
import 'theme.dart';

/// 防沉迷提醒容器：包裹主界面，App 启动后累计使用达到
/// [AppConfig.antiAddictionTime] 分钟时弹一次提醒对话框，
/// 每次启动最多提醒一次（以 keyAppStartTime 为启动标识）。
class AntiAddictionScope extends StatefulWidget {
  final AppConfig config;
  final Widget child;

  const AntiAddictionScope({
    super.key,
    required this.config,
    required this.child,
  });

  @override
  State<AntiAddictionScope> createState() => _AntiAddictionScopeState();
}

class _AntiAddictionScopeState extends State<AntiAddictionScope> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _schedule();
  }

  void _schedule() {
    final c = widget.config;
    if (!c.antiAddictionEnable || c.antiAddictionText.isEmpty) return;

    final startTime = Prefs().getInt(Prefs.keyAppStartTime) ?? 0;
    if (startTime <= 0) return;

    // 本次启动已提醒过则不再提醒
    if ((Prefs().getInt(Prefs.keyAddictionWarned) ?? 0) == startTime) return;

    final elapsed = DateTime.now().millisecondsSinceEpoch - startTime;
    final remaining = c.antiAddictionTime * 60 * 1000 - elapsed;
    if (remaining <= 0) {
      // 已进入主界面时就已超过时长，首帧后立即提醒
      WidgetsBinding.instance.addPostFrameCallback((_) => _warn());
    } else {
      _timer = Timer(Duration(milliseconds: remaining), _warn);
    }
  }

  Future<void> _warn() async {
    if (!mounted) return;
    // 标记本次启动已提醒（与 keyAppStartTime 对应）
    await Prefs().setInt(
      Prefs.keyAddictionWarned,
      Prefs().getInt(Prefs.keyAppStartTime) ?? 0,
    );
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('温馨提示'),
        content: Text(
          widget.config.antiAddictionText,
          style: TextStyle(fontSize: 14, height: 1.6, color: AppColors.of(ctx).ink),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('我知道了'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
