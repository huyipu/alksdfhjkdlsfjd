import 'package:flutter/material.dart';
import '../utils/theme.dart';

/// 宝石合成计算器
///
/// 规则来源：
/// - 官方资料站·合成宝石（https://tl.changyou.com/data/mission/hcbs.shtml）：
///   合成 2-7 级宝石需最少 3 颗、最多 5 颗同级宝石 + 宝石合成符，放入越多成功率越高，
///   失败则宝石与合成符全部被扣除；合成 8 级宝石为 4 颗 7 级 + 超级宝石合成符（4 颗 75%，加符 100%）。
/// - "5 颗合成 100% 成功"（3 颗约 60%、4 颗约 80%）为民间通行说法【存疑】，
///   本页按 5 合 1 的稳妥算法计算：N 级宝石需 5^(N-1) 颗 1 级宝石。
/// - 宝石分类与属性：怀旧服新手教程（叶子猪转载官方资料）；怀旧服宝石上限为 7 级，
///   8-9 级为新天龙后期版本内容，数量仍按 5 合 1 理想算法推算，以游戏内实测为准。
/// - 属性对照表采用官方资料站 8 级宝石属性表（https://tl.changyou.com/data/mission/8jbshc.shtml），
///   其余等级数值官方未集中公布，以游戏内实测为准。
class GemCalculatorPage extends StatefulWidget {
  const GemCalculatorPage({super.key});

  @override
  State<GemCalculatorPage> createState() => _GemCalculatorPageState();
}

/// 宝石定义：名称、类别、加成属性、8 级官方属性值（空串表示官方表未列出/待补）
class _Gem {
  final String name;
  final String category;
  final String attr;
  final String level8Value;

  const _Gem(this.name, this.category, this.attr, this.level8Value);
}

class _GemCalculatorPageState extends State<GemCalculatorPage> {
  static const int _maxLevel = 9;

  /// 25 种宝石（与 image/宝石 目录一致），8 级属性来自官方资料站
  static const List<_Gem> _gems = [
    _Gem('血精石', '命运宝石', '血上限', '+18113'),
    _Gem('红宝石', '命运宝石', '体力', '+329'),
    _Gem('黄宝石', '命运宝石', '力量', '+332'),
    _Gem('蓝宝石', '命运宝石', '灵气', '+332'),
    _Gem('绿宝石', '命运宝石', '身法', '+179'),
    _Gem('黑宝石', '命运宝石', '定力', '+329'),
    _Gem('猫眼石', '希望宝石', '内功攻击', '+3198'),
    _Gem('虎眼石', '希望宝石', '外功攻击', '+3198'),
    _Gem('黄晶石', '智慧宝石', '玄攻击', '+45'),
    _Gem('蓝晶石', '智慧宝石', '冰攻击', '+45'),
    _Gem('红晶石', '智慧宝石', '火攻击', '+45'),
    _Gem('绿晶石', '智慧宝石', '毒攻击', '+45'),
    _Gem('紫玉', '玄微宝石', '命中', '+3559'),
    _Gem('变石', '幻冥宝石', '会心', '+25'),
    _Gem('石榴石', '生命宝石', '内功防御', '+3183'),
    _Gem('尖晶石', '生命宝石', '外功防御', '+3183'),
    _Gem('黄玉', '魅力宝石', '玄抗性', '+18'),
    _Gem('皓石', '魅力宝石', '冰抗性', '+18'),
    _Gem('月光石', '魅力宝石', '火抗性', '+18'),
    _Gem('碧玺', '魅力宝石', '毒抗性', '+18'),
    _Gem('祖母绿', '天机宝石', '闪避', '+1186'),
    _Gem('蓝冥石', '胜利宝石', '忽略目标冰抗', '+120'),
    _Gem('红冥石', '胜利宝石', '忽略目标火抗', '+120'),
    _Gem('黄冥石', '胜利宝石', '忽略目标玄抗', '+120'),
    _Gem('绿冥石', '胜利宝石', '忽略目标毒抗', '+120'),
  ];

  int _gemIndex = 0;
  int _targetLevel = 3;

  _Gem get _gem => _gems[_gemIndex];

  /// N 级宝石需要的 1 级宝石数量：5^(N-1)
  int _level1Needed(int level) {
    int n = 1;
    for (int i = 1; i < level; i++) {
      n *= 5;
    }
    return n;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('宝石合成计算器')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildIntro(),
          const SizedBox(height: 16),
          _buildGemSelector(),
          const SizedBox(height: 16),
          _buildLevelSelector(),
          const SizedBox(height: 16),
          _buildResult(),
          const SizedBox(height: 16),
          _buildAttrTable(),
        ],
      ),
    );
  }

  Widget _buildIntro() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('合成规则速览', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.of(context).ink)),
            const SizedBox(height: 8),
            ...[
              '合成 NPC：洛阳彭怀玉（280,322）、楼兰克里木（279,198）、束河古镇荆嵌实（135,85）；仅限同种宝石合成【官方】',
              '合成 2-7 级：最少 3 颗、最多 5 颗同级宝石 + 宝石合成符，放入越多成功率越高；失败则宝石和合成符全部被扣除【官方】',
              '民间通行说法【存疑】：3 颗约 60%、4 颗约 80%、5 颗 100%——本页按 5 合 1 稳妥算法计算（N 级 = 5^(N-1) 颗 1 级）',
              '合成 8 级：4 颗 7 级宝石成功率 75%，加 1 个超级宝石合成符可达 100%【官方资料站】',
              '怀旧服宝石上限为 7 级；8-9 级属新天龙后期版本，本页数量仍按 5 合 1 推算，以游戏内实测为准',
            ].map((t) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('· ', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                      Expanded(child: Text(t, style: TextStyle(fontSize: 13, color: AppColors.of(context).ink, height: 1.6))),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildGemSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('选择宝石', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.of(context).ink)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: List.generate(_gems.length, (i) {
            final g = _gems[i];
            final selected = _gemIndex == i;
            return ChoiceChip(
              label: Text(g.name, style: TextStyle(fontSize: 12, color: selected ? Colors.white : AppColors.of(context).ink)),
              selected: selected,
              selectedColor: AppColors.primary,
              onSelected: (_) => setState(() => _gemIndex = i),
            );
          }),
        ),
        const SizedBox(height: 8),
        Text(
          '${_gem.category} · 加成：${_gem.attr}（8 级官方值 ${_gem.attr}${_gem.level8Value}）',
          style: TextStyle(fontSize: 12, color: AppColors.of(context).inkLight, height: 1.5),
        ),
      ],
    );
  }

  Widget _buildLevelSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('目标等级', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.of(context).ink)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: List.generate(_maxLevel, (i) {
            final level = i + 1;
            final selected = _targetLevel == level;
            return ChoiceChip(
              label: Text('$level 级', style: TextStyle(fontSize: 12, color: selected ? Colors.white : AppColors.of(context).ink)),
              selected: selected,
              selectedColor: AppColors.primary,
              onSelected: (_) => setState(() => _targetLevel = level),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildResult() {
    final total = _level1Needed(_targetLevel);
    // 中间产物：合成到 target 级过程中，需要 k 级宝石 5^(target-k) 颗（k = 1..target-1）
    final steps = <String>[];
    for (int k = 1; k < _targetLevel; k++) {
      steps.add('$k 级 × ${_level1Needed(_targetLevel - k + 1)}');
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('合成方案（5 合 1 稳妥算法）', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.of(context).ink)),
            const SizedBox(height: 12),
            Row(
              children: [
                _statItem('1 级${_gem.name}', '$total 颗'),
                _statItem('目标', '$_targetLevel 级'),
                _statItem('合成次数', '${_targetLevel > 1 ? (total - 1) ~/ 4 : 0} 次≈'),
              ],
            ),
            if (_targetLevel > 1) ...[
              const SizedBox(height: 12),
              Text('中间产物（逐级合成）', style: TextStyle(fontSize: 12, color: AppColors.of(context).inkLight)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: steps
                    .map((s) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.of(context).inkLight.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(s, style: TextStyle(fontSize: 12, color: AppColors.of(context).ink)),
                        ))
                    .toList(),
              ),
            ],
            const SizedBox(height: 12),
            Text(
              '注：每次合成还需宝石合成符 ×1（8 级需超级宝石合成符）；若用 3-4 颗拼概率可省宝石，但失败会全部扣除，风险自负。怀旧服上限 7 级，8-9 级为推算值，以游戏内实测为准。',
              style: TextStyle(fontSize: 11, color: AppColors.of(context).inkLight, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statItem(String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.of(context).ink)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 11, color: AppColors.of(context).inkLight)),
        ],
      ),
    );
  }

  Widget _buildAttrTable() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('宝石属性对照（8 级官方数据）', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.of(context).ink)),
            const SizedBox(height: 4),
            Text(
              '来源：官方资料站 8 级宝石合成页；其余等级数值官方未集中公布，等级越高加成越多，以游戏内实测为准',
              style: TextStyle(fontSize: 11, color: AppColors.of(context).inkLight, height: 1.5),
            ),
            const SizedBox(height: 8),
            Table(
              columnWidths: const {0: FlexColumnWidth(1.2), 1: FlexColumnWidth(1.4), 2: FlexColumnWidth(1.6), 3: FlexColumnWidth(1.2)},
              children: [
                TableRow(
                  decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Colors.black12))),
                  children: [
                    _th('宝石'),
                    _th('类别'),
                    _th('加成属性'),
                    _th('8 级数值'),
                  ],
                ),
                ..._gems.map((g) {
                  final selected = g.name == _gem.name;
                  return TableRow(
                    decoration: selected ? BoxDecoration(color: AppColors.primary.withOpacity(0.08)) : null,
                    children: [
                      _td(g.name, bold: selected),
                      _td(g.category),
                      _td(g.attr),
                      _td(g.level8Value, bold: selected),
                    ],
                  );
                }),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _th(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Text(text, style: TextStyle(fontSize: 12, color: AppColors.of(context).inkLight)),
    );
  }

  Widget _td(String text, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        text,
        style: TextStyle(fontSize: 12, color: AppColors.of(context).ink, fontWeight: bold ? FontWeight.bold : FontWeight.normal),
      ),
    );
  }
}
