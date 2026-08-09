import 'dart:math';

import 'package:flutter/material.dart';
import '../utils/theme.dart';

/// 装备强化模拟器
///
/// 规则来源：
/// - 官方资料站·装备强化（https://tl.changyou.com/data/mission/zbqh.shtml）：
///   强化材料为地煞强化精华（40级以下装备）/天罡强化精华（≥40级）/天罡强化露（≥40级，最多11次）；
///   强化等级升高后失败会降级；强化到 1、5、7 后不再回退；强化卷轴·5级/7级 可 100% 强化到 +5/+7。
/// - 百度经验（⚠️ 细节可能随版本调整）：保底节点另有 "+8" 的说法（1/5/7/8）。
/// - 成功率 / 单次费用 / 失败掉级幅度【存疑】：官方未公布精确数值，
///   本页数值为按"等级越高越难"经验取的递减估计值，以游戏内实测为准。
class ForgeSimulatorPage extends StatefulWidget {
  const ForgeSimulatorPage({super.key});

  @override
  State<ForgeSimulatorPage> createState() => _ForgeSimulatorPageState();
}

class _ForgeSimulatorPageState extends State<ForgeSimulatorPage> {
  static const int _maxLevel = 9;
  static const int _batchLimit = 500;

  /// 保底节点【官方资料站确定】：强化到 1 / 5 / 7 后失败不再回退到该节点以下
  static const List<int> _floors = [1, 5, 7];

  /// 各等级强化成功率（从 key 级强化到 key+1 级）。
  /// 【存疑】官方未公布精确成功率，此处按"等级越高越难强化"的经验取递减估计值，
  /// 0→1 按必定成功处理（官方规则中 +1 为首个保底节点），以游戏内实测为准。
  static const Map<int, double> _successRates = {
    0: 1.00,
    1: 0.85,
    2: 0.75,
    3: 0.65,
    4: 0.55,
    5: 0.45,
    6: 0.35,
    7: 0.25,
    8: 0.15,
  };

  /// 单次强化金币消耗（从 key 级强化到 key+1 级）。
  /// 【存疑】官方未公布统一费用表（费用与装备等级挂钩），此处为估计值，以游戏内实测为准。
  static const Map<int, int> _goldCosts = {
    0: 10,
    1: 20,
    2: 40,
    3: 70,
    4: 110,
    5: 160,
    6: 230,
    7: 320,
    8: 450,
  };

  final Random _random = Random();

  int _level = 0;
  int _attempts = 0;
  int _goldSpent = 0;
  int _essenceSpent = 0; // 强化精华消耗（每次 1 个）
  int _maxReached = 0;

  bool? _lastSuccess;
  String _lastMessage = '选择起始等级，点击下方按钮开始强化';
  int _resultTick = 0; // 驱动结果反馈动画重播

  double get _currentRate => _successRates[_level] ?? 0;

  int get _currentCost => _goldCosts[_level] ?? 0;

  bool get _isFloor => _floors.contains(_level);

  /// 模拟一次强化，返回 (是否成功, 变化前等级, 变化后等级)
  (bool, int, int) _rollOnce() {
    final from = _level;
    final success = _random.nextDouble() < _currentRate;
    if (success) {
      _level = min(_maxLevel, _level + 1);
    } else if (!_isFloor && _level > 0) {
      // 【存疑】民间通行说法为失败掉 1 级（官方仅说明"失败会降级"），以实测为准
      _level = _level - 1;
    }
    if (_level > _maxReached) _maxReached = _level;
    return (success, from, _level);
  }

  void _consume(int level) {
    _goldSpent += _goldCosts[level] ?? 0;
    _essenceSpent++;
  }

  void _tryOnce() {
    if (_level >= _maxLevel) return;
    setState(() {
      _attempts++;
      _consume(_level);
      final (success, from, to) = _rollOnce();
      _lastSuccess = success;
      _resultTick++;
      if (success) {
        _lastMessage = to >= _maxLevel ? '强化成功！+$to 圆满毕业！' : '强化成功！+$from → +$to';
      } else if (to == from) {
        _lastMessage = from == 0 ? '强化失败，+0 不会掉级' : '强化失败，+$from 为保底节点，不掉级';
      } else {
        _lastMessage = '强化失败，等级掉落 +$from → +$to';
      }
    });
  }

  void _batchSimulate() {
    if (_level >= _maxLevel) return;
    int tries = 0;
    int gold = 0;
    int essence = 0;
    int worstFrom = _level;
    int worstTo = _level;
    int failStreak = 0;
    int maxFailStreak = 0;

    while (_level < _maxLevel && tries < _batchLimit) {
      tries++;
      gold += _goldCosts[_level] ?? 0;
      essence++;
      final (success, from, to) = _rollOnce();
      if (success) {
        failStreak = 0;
      } else {
        failStreak++;
        if (failStreak > maxFailStreak) maxFailStreak = failStreak;
        if (from - to > worstFrom - worstTo) {
          worstFrom = from;
          worstTo = to;
        }
      }
    }

    setState(() {
      _attempts += tries;
      _goldSpent += gold;
      _essenceSpent += essence;
      _lastSuccess = _level >= _maxLevel ? true : null;
      _resultTick++;
      _lastMessage = _level >= _maxLevel ? '批量模拟完成：$tries 次尝试后强化到 +9' : '达到 $_batchLimit 次上限，强化停在 +$_level';
    });

    final reached = _level >= _maxLevel;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.of(context).card,
        title: Text(reached ? '批量模拟结果' : '未能在上限内到 +9', style: TextStyle(color: AppColors.of(context).ink)),
        content: Text(
          '共尝试 $tries 次\n消耗金币 $gold · 强化精华 $essence 个\n'
          '最长连败 $maxFailStreak 次\n'
          '最惨一次：从 +$worstFrom 掉到 +$worstTo',
          style: TextStyle(color: AppColors.of(context).ink, height: 1.8),
        ),
        actions: [
          FilledButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('知道了')),
        ],
      ),
    );
  }

  void _reset() {
    setState(() {
      _level = 0;
      _attempts = 0;
      _goldSpent = 0;
      _essenceSpent = 0;
      _maxReached = 0;
      _lastSuccess = null;
      _lastMessage = '已重置，重新开始强化';
      _resultTick++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('装备强化模拟器')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildIntro(),
          const SizedBox(height: 16),
          _buildLevelSelector(),
          const SizedBox(height: 16),
          _buildSimulator(),
          const SizedBox(height: 16),
          _buildStats(),
          const SizedBox(height: 16),
          _buildRateTable(),
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
            Text('强化规则速览', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.of(context).ink)),
            const SizedBox(height: 8),
            ...[
              '强化 NPC：苏州欧冶子（355,234）；材料：地煞强化精华（40级以下装备）、天罡强化精华/天罡强化露（≥40级装备）【官方资料站】',
              '保底节点【官方】：强化到 +1 / +5 / +7 后，失败不再回退到该节点以下；另有 "+8 也保底" 的说法（百度经验，可能随版本调整，存疑）',
              '强化卷轴·5级/7级【官方】：可将低于 +5/+7 的装备 100% 强化到 +5/+7，冲高级前用卷轴打底最稳',
              '失败惩罚：官方仅说明"强化等级升高后失败会降级"，本模拟按民间通行的"失败掉 1 级"处理【存疑】',
              '成功率与费用：官方未公布精确数值，本页为估计值，以游戏内实测为准',
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

  Widget _buildLevelSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('选择当前强化等级', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.of(context).ink)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: List.generate(_maxLevel + 1, (i) {
            final selected = _level == i;
            return ChoiceChip(
              label: Text('+$i', style: TextStyle(fontSize: 12, color: selected ? Colors.white : AppColors.of(context).ink)),
              selected: selected,
              selectedColor: AppColors.primary,
              onSelected: (_) => setState(() {
                _level = i;
                _lastSuccess = null;
                _lastMessage = '已切换到 +$i，点击"强化"继续';
                _resultTick++;
              }),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildSimulator() {
    final maxed = _level >= _maxLevel;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text('当前强化等级', style: TextStyle(fontSize: 12, color: AppColors.of(context).inkLight)),
            const SizedBox(height: 4),
            Text(
              '+$_level',
              style: TextStyle(
                fontSize: 56,
                fontWeight: FontWeight.bold,
                color: maxed ? AppColors.primary : AppColors.of(context).ink,
              ),
            ),
            if (_isFloor && !maxed)
              Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text('保底节点：失败不掉级', style: TextStyle(fontSize: 11, color: AppColors.primary)),
              ),
            const SizedBox(height: 12),
            TweenAnimationBuilder<double>(
              key: ValueKey(_resultTick),
              tween: Tween(begin: 0.6, end: 1.0),
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOutBack,
              builder: (context, value, child) => Opacity(
                opacity: value.clamp(0.0, 1.0),
                child: Transform.scale(scale: value, child: child),
              ),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: _lastSuccess == null
                      ? AppColors.of(context).inkLight.withOpacity(0.08)
                      : _lastSuccess!
                          ? AppColors.primary.withOpacity(0.15)
                          : AppColors.of(context).inkLight.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _lastSuccess == null
                        ? AppColors.of(context).inkLight.withOpacity(0.3)
                        : _lastSuccess!
                            ? AppColors.primary
                            : AppColors.of(context).inkLight,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _lastSuccess == null
                          ? Icons.info_outline
                          : _lastSuccess!
                              ? Icons.emoji_events
                              : Icons.heart_broken,
                      size: 18,
                      color: _lastSuccess == null
                          ? AppColors.of(context).inkLight
                          : _lastSuccess!
                              ? AppColors.primary
                              : AppColors.of(context).inkLight,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _lastMessage,
                        style: TextStyle(
                          fontSize: 13,
                          color: _lastSuccess == true ? AppColors.primary : AppColors.of(context).ink,
                          fontWeight: _lastSuccess == true ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              maxed
                  ? '已强化到 +$_maxLevel 满级'
                  : '成功率约 ${(_currentRate * 100).toStringAsFixed(0)}%（存疑，以实测为准）· 本次消耗 金币$_currentCost + 强化精华×1',
              style: TextStyle(fontSize: 12, color: AppColors.of(context).inkLight),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: maxed ? null : _tryOnce,
                    icon: const Icon(Icons.construction, size: 18),
                    label: const Text('强化'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: maxed ? null : _batchSimulate,
                    icon: const Icon(Icons.fast_forward, size: 18),
                    label: const Text('连续强化到9'),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: _reset,
                  child: const Text('重置'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStats() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('累计统计', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.of(context).ink)),
            const SizedBox(height: 12),
            Row(
              children: [
                _statItem('尝试次数', '$_attempts'),
                _statItem('金币总消耗', '$_goldSpent'),
                _statItem('精华总消耗', '$_essenceSpent'),
                _statItem('最高到达', '+$_maxReached'),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text('强化进度', style: TextStyle(fontSize: 12, color: AppColors.of(context).inkLight)),
                const SizedBox(width: 8),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: _level / _maxLevel,
                      minHeight: 8,
                      backgroundColor: AppColors.of(context).inkLight.withOpacity(0.15),
                      valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text('+$_level/+$_maxLevel', style: TextStyle(fontSize: 12, color: AppColors.of(context).ink)),
              ],
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

  Widget _buildRateTable() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('各等级成功率与消耗（模拟用）', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.of(context).ink)),
            const SizedBox(height: 4),
            Text(
              '【存疑】官方未公布精确成功率与费用，下表按资料中民间说法取的递减估计值，以游戏内实测为准；标"保"的为官方保底节点',
              style: TextStyle(fontSize: 11, color: AppColors.of(context).inkLight, height: 1.5),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _successRates.entries.map((e) {
                final current = e.key == _level;
                final floor = _floors.contains(e.key);
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: current ? AppColors.primary.withOpacity(0.15) : AppColors.of(context).inkLight.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(8),
                    border: current ? Border.all(color: AppColors.primary) : null,
                  ),
                  child: Text(
                    '+${e.key}→+${e.key + 1}：${(e.value * 100).toStringAsFixed(0)}% · 金币${_goldCosts[e.key]}${floor ? ' · 保' : ''}',
                    style: TextStyle(fontSize: 12, color: current ? AppColors.primary : AppColors.of(context).ink),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
