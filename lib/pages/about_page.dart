import 'package:flutter/material.dart';
import '../data/app_meta.dart';
import '../services/api_service.dart';
import '../services/data_service.dart';
import '../utils/theme.dart';
import '../widgets/app_logo.dart';

/// 关于页：版本信息 + 数据统计 + 品牌信息
class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  @override
  void initState() {
    super.initState();
    DataService().load().then((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = AppColors.of(context);
    final ds = DataService();
    // 底部信息接后台 basic 配置（footer_enable 总开关 + 逐行独立显隐）：
    // 开发者/软著/备案号均后台有值才显示对应行；断网或没配就只隐去那一行，不做静态兜底
    final cfg = ApiService().config;
    final showFooter = cfg == null || cfg.footerEnable;
    final developer = cfg?.developer ?? '';
    final softCertNo = cfg?.softCertNo ?? '';
    final icpNo = cfg?.icpNo ?? '';
    final copyrightOwner = cfg?.copyrightOwner ?? '';
    return Scaffold(
      appBar: AppBar(title: const Text('关于')),
      body: ListView(
        children: [
          const SizedBox(height: 24),
          _buildRow(context, '版本', AppMeta.version),
          _buildRow(context, '装备图鉴', '${ds.equipment.length} 件'),
          _buildRow(context, '攻略文章', '${ds.articles.length} 篇'),
          _buildRow(context, '实用工具', '6 个'),
          _buildRow(context, '网络状态', '离线可用'),
          _buildRow(context, '功能数量', '图鉴 · 攻略 · 工具 · 收藏 · 历史'),
          const SizedBox(height: 48),
          Center(
            child: Container(
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
          ),
          const SizedBox(height: 16),
          Center(
            child: Text('天龙亿旧',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: p.ink, letterSpacing: 4)),
          ),
          const SizedBox(height: 16),
          if (showFooter) ...[
            if (developer.isNotEmpty) ...[
              Center(child: Text('开发者：$developer', style: TextStyle(fontSize: 13, color: p.inkLight))),
              const SizedBox(height: 4),
            ],
            Center(child: Text('生效日期：${AppMeta.effectiveDate}', style: TextStyle(fontSize: 13, color: p.inkLight))),
            if (softCertNo.isNotEmpty) ...[
              const SizedBox(height: 4),
              Center(child: Text('软著登记号：$softCertNo', style: TextStyle(fontSize: 13, color: p.inkLight))),
            ],
            if (icpNo.isNotEmpty) ...[
              const SizedBox(height: 4),
              Center(child: Text('备案号：$icpNo', style: TextStyle(fontSize: 13, color: p.inkLight))),
            ],
            if (copyrightOwner.isNotEmpty) ...[
              const SizedBox(height: 4),
              Center(
                child: Text('© ${DateTime.now().year} $copyrightOwner All Rights Reserved',
                    style: TextStyle(fontSize: 12, color: p.inkLight)),
              ),
            ],
          ],
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildRow(BuildContext context, String label, String value) {
    final p = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: p.inkLight.withOpacity(0.15), width: 0.5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 15, color: p.inkLight)),
          Text(value, style: TextStyle(fontSize: 15, color: p.ink, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
