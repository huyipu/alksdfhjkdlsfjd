import 'package:flutter/material.dart';
import '../models/app_config.dart';
import '../services/track_service.dart';
import '../utils/flow_controller.dart';
import '../utils/prefs.dart';
import '../utils/theme.dart';

/// 合规提示页：适龄提示 + 健康游戏忠告（移植自 xxddtt_app，主题已适配）
class CompliancePage extends StatefulWidget {
  final AppConfig config;
  const CompliancePage({super.key, required this.config});

  @override
  State<CompliancePage> createState() => _CompliancePageState();
}

class _CompliancePageState extends State<CompliancePage> {
  @override
  void initState() {
    super.initState();
    TrackService().fire('page_enter:compliance');
  }

  @override
  Widget build(BuildContext context) {
    final config = widget.config;
    final showAgeRating = config.ageRatingEnable;
    final showHealthTip = config.healthTipEnable;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: AppColors.of(context).bgGradient),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 48),
              const Icon(
                Icons.verified_user_outlined,
                size: 56,
                color: AppColors.primary,
              ),
              const SizedBox(height: 16),
              Text(
                '合规提示',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.of(context).ink,
                ),
              ),
              const SizedBox(height: 32),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      if (showAgeRating) ...[
                        _buildAgeRating(config),
                        const SizedBox(height: 32),
                      ],
                      if (showHealthTip) ...[
                        _buildHealthTip(config),
                      ],
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: FilledButton(
                    onPressed: _onConfirm,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      '我知道了',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 官方适龄提示 12+ 图标（参照中国音像与数字出版协会规范）
  Widget _buildAgeRating(AppConfig config) {
    return Column(
      children: [
        // 12+ 官方样式徽章
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: const Color(0xFF2196F3), // 12+ 标准蓝色
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2196F3).withOpacity(0.4),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // 内圈装饰
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              // 数字
              const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '12',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      height: 0.9,
                    ),
                  ),
                  Text(
                    '+',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      height: 0.9,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          '适龄提示',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.of(context).inkLight,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          config.ageRatingText.isNotEmpty
              ? config.ageRatingText
              : '本游戏适用于12周岁及以上用户',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.of(context).ink,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildHealthTip(AppConfig config) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.of(context).card.withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primaryLight.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            config.healthTipTitle.isNotEmpty
                ? config.healthTipTitle
                : '健康游戏忠告',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.of(context).ink,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            config.healthTip.isNotEmpty
                ? config.healthTip
                : '抵制不良游戏，拒绝盗版游戏。注意自我保护，谨防受骗上当。适度游戏益脑，沉迷游戏伤身。合理安排时间，享受健康生活。',
            style: TextStyle(
              fontSize: 13,
              height: 1.8,
              color: AppColors.of(context).inkLight,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _onConfirm() async {
    await Prefs().setBool(Prefs.keyComplianceDone, true);
    if (mounted) {
      FlowController().onComplianceDone(context);
    }
  }
}
