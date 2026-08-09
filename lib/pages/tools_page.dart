import 'package:flutter/material.dart';
import '../services/track_service.dart';
import '../utils/theme.dart';
import 'book_planner_page.dart';
import 'breeding_calculator_page.dart';
import 'forge_simulator_page.dart';
import 'gem_calculator_page.dart';
import 'merchant_calculator_page.dart';
import 'wuxing_simulator_page.dart';

/// 工具箱：跑商时辰计算器、珍兽悟性模拟器、打书规划器、装备强化模拟器、宝石合成计算器、珍兽繁殖估算器
class ToolsPage extends StatelessWidget {
  const ToolsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('工具箱')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildToolCard(
            context,
            icon: Icons.calculate,
            color: AppColors.primary,
            title: '跑商时辰计算器',
            subtitle: '选商线 → 满票路线、买卖价格、预计收益',
            ready: true,
            onTap: () {
              TrackService().fire('tool_merchant_open');
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MerchantCalculatorPage()));
            },
          ),
          _buildToolCard(
            context,
            icon: Icons.pets,
            color: AppColors.qPurple,
            title: '珍兽悟性模拟器',
            subtitle: '模拟提悟性过程，保底节点与根骨丹消耗统计',
            ready: true,
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const WuxingSimulatorPage()));
            },
          ),
          _buildToolCard(
            context,
            icon: Icons.auto_fix_high,
            color: AppColors.qBlue,
            title: '打书规划器',
            subtitle: '7 技能格规划打书方案，标记破军/开阳位，支持本地保存',
            ready: true,
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const BookPlannerPage()));
            },
          ),
          _buildToolCard(
            context,
            icon: Icons.construction,
            color: AppColors.accent,
            title: '装备强化模拟器',
            subtitle: '按成功率模拟强化 +1~+9，保底节点与消耗统计',
            ready: true,
            onTap: () {
              TrackService().fire('tool_forge_open');
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ForgeSimulatorPage()));
            },
          ),
          _buildToolCard(
            context,
            icon: Icons.diamond,
            color: AppColors.qOrange,
            title: '宝石合成计算器',
            subtitle: '5 合 1 计算 1 级宝石需求，附官方 8 级属性对照表',
            ready: true,
            onTap: () {
              TrackService().fire('tool_gem_open');
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const GemCalculatorPage()));
            },
          ),
          _buildToolCard(
            context,
            icon: Icons.favorite,
            color: AppColors.qGreen,
            title: '珍兽繁殖估算器',
            subtitle: '父母资质/成长率 → 二代成长率与变异资质区间估算',
            ready: true,
            onTap: () {
              TrackService().fire('tool_breeding_open');
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const BreedingCalculatorPage()));
            },
          ),
        ],
      ),
    );
  }

  Widget _buildToolCard(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    bool ready = false,
    VoidCallback? onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: ready ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.of(context).ink)),
                        if (!ready) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(color: AppColors.of(context).inkLight.withOpacity(0.15), borderRadius: BorderRadius.circular(4)),
                            child: Text('敬请期待', style: TextStyle(fontSize: 10, color: AppColors.of(context).inkLight)),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(subtitle, style: TextStyle(fontSize: 12, color: AppColors.of(context).inkLight)),
                  ],
                ),
              ),
              if (ready) Icon(Icons.chevron_right, color: AppColors.of(context).inkLight),
            ],
          ),
        ),
      ),
    );
  }
}
