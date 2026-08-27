import 'dart:io';
import 'package:flutter/material.dart';
import '../data/legal_texts.dart';
import '../services/api_service.dart';
import '../utils/theme.dart';
import '../widgets/linkified_text.dart';

/// 法律文本页：用户协议 / 隐私政策
class LegalPage extends StatelessWidget {
  final String title;
  final String content;
  const LegalPage({super.key, required this.title, required this.content});

  /// 开发者署名读后台 basic.developer；没配/离线时落款自动隐去该行
  static String get _developer => ApiService().config?.developer ?? '';

  static Widget userAgreement() =>
      LegalPage(title: '用户协议', content: LegalTexts.userAgreement(developer: _developer));
  static Widget privacyPolicy() => LegalPage(
        title: '隐私政策',
        content: Platform.isIOS
            ? LegalTexts.privacyPolicyIOS(developer: _developer)
            : LegalTexts.privacyPolicy(developer: _developer),
      );

  @override
  Widget build(BuildContext context) {
    final p = AppColors.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: LinkifiedText(
                text: content,
                style: TextStyle(fontSize: 14, height: 1.9, color: p.ink),
                linkColor: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
