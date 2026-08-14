import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../data/legal_texts.dart';
import '../models/app_config.dart';
import '../services/ads_service.dart';
import '../services/api_service.dart';
import '../services/track_service.dart';
import '../utils/flow_controller.dart';
import '../utils/prefs.dart';
import '../utils/theme.dart';
import 'legal_page.dart';
import '../widgets/linkified_text.dart';

class PrivacyPage extends StatefulWidget {
  final AppConfig config;
  const PrivacyPage({super.key, required this.config});

  @override
  State<PrivacyPage> createState() => _PrivacyPageState();
}

class _PrivacyPageState extends State<PrivacyPage> {
  bool _accepted = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: AppColors.of(context).bgGradient),
        child: SafeArea(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const Icon(Icons.shield_outlined, size: 48, color: AppColors.primary),
                    const SizedBox(height: 16),
                    Text(
                      widget.config.privacyTitle.isNotEmpty ? widget.config.privacyTitle : '用户隐私协议',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.of(context).ink,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.of(context).card.withOpacity(0.85),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: LinkifiedText(
                      // 网络未就绪时隐私内容为空，用本地内置文本兜底
                      text: _stripHtml(widget.config.privacyContent.isNotEmpty
                          ? widget.config.privacyContent
                          : LegalTexts.privacyPolicy(developer: widget.config.developer)),
                      style: TextStyle(fontSize: 14, height: 1.8, color: AppColors.of(context).ink),
                      linkColor: AppColors.primary,
                    ),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.of(context).card.withOpacity(0.95),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Checkbox(
                          value: _accepted,
                          onChanged: (v) => setState(() => _accepted = v ?? false),
                          activeColor: AppColors.primary,
                        ),
                        Expanded(
                          child: Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text('我已阅读并同意', style: TextStyle(fontSize: 13, color: AppColors.of(context).ink)),
                              GestureDetector(
                                onTap: () {
                                  Navigator.of(context).push(
                                      MaterialPageRoute(builder: (_) => LegalPage.privacyPolicy()));
                                },
                                child: const Text('《隐私政策》',
                                    style: TextStyle(fontSize: 13, color: AppColors.primary, decoration: TextDecoration.underline)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => SystemNavigator.pop(),
                            child: const Text('不同意并退出'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            onPressed: _accepted
                                ? () async {
                                    await Prefs().setBool(Prefs.keyPrivacyAccepted, true);
                                    if (mounted) {
                                      await AdsService.initAds();
                                      TrackService().onSdkReady();
                                      if (widget.config.auditMode) {
                                        // SDK检测模式：固定发 注册+付费（激活/心跳SDK自动发），延迟3秒
                                        ApiService().eventSources['register'] = 'audit_mode';
                                        ApiService().eventSources['purchase'] = 'audit_mode';
                                        unawaited(Future.delayed(const Duration(seconds: 3), () async {
                                          await AdsService.reportRegister();
                                          await AdsService.reportPurchase(
                                              amount: 1, contentType: 'gift', isSuccess: true);
                                        }));
                                      } else {
                                        TrackService().fire('privacy_accepted');
                                      }
                                      // 走统一流程调度：合规 → 实名 → 首屏弹窗 → 主页
                                      FlowController().onPrivacyAccepted(context);
                                    }
                                  }
                                : null,
                            child: const Text('同意并继续'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _stripHtml(String html) {
    return html
        // 块级标签先转换为换行，避免段落粘连
        .replaceAll(RegExp(r'<\/p\s*>', caseSensitive: false), '\n\n')
        .replaceAll(RegExp(r'<br\s*\/?>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'<\/(div|h[1-6]|li|tr)\s*>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'<li[^>]*>', caseSensitive: false), '· ')
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&amp;', '&')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();
  }
}
