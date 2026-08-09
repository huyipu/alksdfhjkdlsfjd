import 'package:flutter/material.dart';
import '../data/legal_texts.dart';
import '../utils/theme.dart';
import '../widgets/linkified_text.dart';

/// 法律文本页：用户协议 / 隐私政策
class LegalPage extends StatelessWidget {
  final String title;
  final String content;
  const LegalPage({super.key, required this.title, required this.content});

  static Widget userAgreement() => const LegalPage(title: '用户协议', content: LegalTexts.userAgreement);
  static Widget privacyPolicy() => const LegalPage(title: '隐私政策', content: LegalTexts.privacyPolicy);

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
