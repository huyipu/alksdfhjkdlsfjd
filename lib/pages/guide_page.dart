import 'package:flutter/material.dart';
import '../models/app_config.dart';
import '../services/ads_service.dart';
import '../services/api_service.dart';
import '../services/track_service.dart';
import '../utils/flow_controller.dart';
import '../utils/prefs.dart';
import '../utils/theme.dart';

String _imageUrl(String path) {
  if (path.isEmpty) return '';
  if (path.startsWith('http')) return path;
  return '${ApiService().baseUrl}$path';
}

/// 首屏弹窗（加群引导页，移植自 xxddtt_app，主题已适配）。
/// 审核模式（auditMode）下由 FlowController 保证不进入此页。
class GuidePage extends StatefulWidget {
  final AppConfig config;
  const GuidePage({super.key, required this.config});

  @override
  State<GuidePage> createState() => _GuidePageState();
}

class _GuidePageState extends State<GuidePage> {
  @override
  void initState() {
    super.initState();
    TrackService().fire('page_enter:guide');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: AppColors.of(context).bgGradient),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const SizedBox(height: 40),
                const Icon(Icons.groups_outlined, size: 56, color: AppColors.primary),
                const SizedBox(height: 24),
                Text(
                  widget.config.guideTitle.isNotEmpty
                      ? widget.config.guideTitle
                      : '加入官方群聊',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.of(context).ink,
                  ),
                ),
                if (widget.config.guideText.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    widget.config.guideText,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.6,
                      color: AppColors.of(context).inkLight,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
                if (widget.config.guideImage.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      _imageUrl(widget.config.guideImage),
                      height: 200,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),
                  ),
                ],
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _onJoinPressed,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('加入群聊', style: TextStyle(fontSize: 16)),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _onSkip,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      foregroundColor: AppColors.of(context).inkLight,
                    ),
                    child: const Text('暂不加入', style: TextStyle(fontSize: 16)),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _onSkip() async {
    await Prefs().setBool(Prefs.keyGuideDone, true);
    if (mounted) {
      FlowController().onGuideDone(context);
    }
  }

  /// 点"加入群聊"：后台配置了 verify_answer 时先答对问题，否则直接唤起QQ
  void _onJoinPressed() {
    if (widget.config.verifyAnswer.isNotEmpty &&
        !(Prefs().getBool(Prefs.keyVerifyDone) ?? false)) {
      _showVerifyDialog();
    } else {
      _openQQGroup();
    }
  }

  /// 答题验证对话框（移植自 xxddtt_app verify 交互）
  void _showVerifyDialog() {
    final controller = TextEditingController();
    String? error;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(
            widget.config.verifyTitle.isNotEmpty
                ? widget.config.verifyTitle
                : '验证',
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.config.guideImage.isNotEmpty) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    _imageUrl(widget.config.guideImage),
                    height: 120,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              if (widget.config.verifyDesc.isNotEmpty)
                Text(widget.config.verifyDesc),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: widget.config.verifyPlaceholder.isNotEmpty
                      ? widget.config.verifyPlaceholder
                      : '请输入答案',
                  errorText: error,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () {
                if (controller.text.trim() == widget.config.verifyAnswer) {
                  Navigator.of(ctx).pop();
                  Prefs().setBool(Prefs.keyVerifyDone, true);
                  // 问答确认数统计（与后台"问答确认数"对应）
                  ApiService().reportStat('verify_done');
                  _openQQGroup();
                } else {
                  setDialogState(() => error = '答案错误，请重新输入');
                }
              },
              child: const Text('确认'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openQQGroup() async {
    // 触发QQ群点击事件（由后台 events 规则决定上报内容）
    TrackService().fire('guide_qq_click');
    await ApiService().reportStat('qq_clicked');

    final ok = await AdsService.openQQGroup(
      qqNumber: widget.config.guideQqNumber,
      qqKey: widget.config.guideQqKey,
    );
    if (!ok) {
      _showFallbackSnackBar();
    }
  }

  void _showFallbackSnackBar([String? message]) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message ?? '未能唤起QQ，请手动搜索群号：${widget.config.guideQqNumber}',
          ),
        ),
      );
    }
  }
}
