import 'package:flutter/material.dart';
import '../data/app_meta.dart';
import '../services/api_service.dart';
import '../utils/prefs.dart';
import '../utils/theme.dart';
import 'about_page.dart';
import 'collection_page.dart';
import 'favorites_page.dart';
import 'feedback_page.dart';
import 'history_page.dart';
import 'legal_page.dart';

/// 我的：收藏/历史 + 反馈 + 设置 + 关于
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final config = ApiService().config;
    return Scaffold(
      appBar: AppBar(title: const Text('我的')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(14)),
                    child: const Center(
                      child: Text('龙',
                          style: TextStyle(fontSize: 28, color: Color(0xFFE8D9B0), fontWeight: FontWeight.bold, fontFamilyFallback: ['STKaiti', 'KaiTi', 'SimSun'])),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(config?.appName.isNotEmpty == true ? config!.appName : '天龙亿旧',
                            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.of(context).ink)),
                        const SizedBox(height: 4),
                        Text('老天龙玩家的随身图鉴与时光机', style: TextStyle(fontSize: 12, color: AppColors.of(context).inkLight)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          _buildSectionHeader(context, '功能'),
          _buildItem(context, Icons.favorite_outline, '我的收藏', '收藏的装备图鉴', onTap: () {
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => const FavoritesPage()));
          }),
          _buildItem(context, Icons.history, '浏览历史', '最近浏览的攻略文章', onTap: () {
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => const HistoryPage()));
          }),
          _buildItem(context, Icons.checklist, '套装收集', '标记已拥有装备，追踪套装进度', onTap: () {
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CollectionPage()));
          }),
          _buildItem(context, Icons.feedback_outlined, '意见反馈', '欢迎提建议和纠错', onTap: () {
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => const FeedbackPage()));
          }),
          _buildSectionHeader(context, '通用'),
          _buildItem(context, Icons.dark_mode_outlined, '外观设置', '当前：${ThemeController.label(ThemeController().mode.value)}', onTap: () {
            showDialog(
              context: context,
              builder: (ctx) => SimpleDialog(
                title: const Text('外观设置'),
                children: [ThemeMode.system, ThemeMode.light, ThemeMode.dark].map((m) {
                  return RadioListTile<ThemeMode>(
                    title: Text(ThemeController.label(m)),
                    value: m,
                    groupValue: ThemeController().mode.value,
                    onChanged: (v) {
                      if (v != null) ThemeController().setMode(v);
                      Navigator.of(ctx).pop();
                    },
                  );
                }).toList(),
              ),
            ).then((_) {
              // 刷新副标题显示
              (context as Element).markNeedsBuild();
            });
          }),
          _buildItem(context, Icons.cleaning_services_outlined, '清除本地数据', '清除收藏、浏览历史等本机缓存', onTap: () async {
            final ok = await showDialog<bool>(
              context: context,
              builder: (_) => AlertDialog(
                title: const Text('清除本地数据？'),
                content: const Text('将清除本机保存的收藏、浏览历史与缓存数据，此操作不可恢复。'),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('取消')),
                  FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('确认清除')),
                ],
              ),
            );
            if (ok == true) {
              await Prefs().remove(Prefs.keyPrivacyAccepted);
              await Prefs().remove(Prefs.keyDeviceId);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('本地数据已清除')));
              }
            }
          }),
          _buildSectionHeader(context, '隐私'),
          _buildItem(context, Icons.privacy_tip_outlined, '隐私政策', '', onTap: () {
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => LegalPage.privacyPolicy()));
          }),
          _buildItem(context, Icons.description_outlined, '用户协议', '', onTap: () {
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => LegalPage.userAgreement()));
          }),
          _buildItem(context, Icons.info_outline, '关于', 'v${AppMeta.version} · 无广告 · 离线可用', onTap: () {
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AboutPage()));
          }),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
      child: Text(title, style: TextStyle(fontSize: 13, color: AppColors.of(context).inkLight)),
    );
  }

  Widget _buildItem(BuildContext context, IconData icon, String title, String subtitle, {VoidCallback? onTap}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: AppColors.primary),
        title: Text(title, style: TextStyle(fontSize: 14, color: AppColors.of(context).ink)),
        subtitle: Text(subtitle, style: TextStyle(fontSize: 11, color: AppColors.of(context).inkLight)),
        trailing: onTap != null ? Icon(Icons.chevron_right, color: AppColors.of(context).inkLight) : null,
        onTap: onTap,
      ),
    );
  }
}
