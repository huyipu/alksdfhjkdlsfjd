import 'dart:math';

import 'package:flutter/material.dart';
import '../services/track_service.dart';
import '../utils/theme.dart';

/// 珍兽悟性模拟器
///
/// 规则来源：tlbb-guide/05-门派与珍兽.md §3.3
/// - 保底机制【官方确定】：悟性到 4 / 7 / 9 后失败不会跌回该节点以下
/// - 根骨丹档位【官方确定】：低级 0-2 / 中级 3-5 / 高级 6-9
/// - 成功率【存疑】：官方未公布精确数值，本页数值为按资料民间说法取的估计值，以游戏内实测为准
class WuxingSimulatorPage extends StatefulWidget {
  const WuxingSimulatorPage({super.key});

  @override
  State<WuxingSimulatorPage> createState() => _WuxingSimulatorPageState();
}

class _WuxingSimulatorPageState extends State<WuxingSimulatorPage> {
  static const int _maxWuxing = 10;
  static const int _batchLimit = 1000;
  static const List<int> _floors = [4, 7, 9]; // 保底节点

  /// 各等级"提悟性"成功率（从 key 级提到 key+1 级）。
  /// 【存疑】官方未公布精确成功率，资料仅有"界面显示83%也当一半一半看"等民间说法，
  /// 此处按"等级越高越难提"的经验取递减估计值，以游戏内实测为准。
  static const Map<int, double> _successRates = {
    1: 0.90,
    2: 0.75,
    3: 0.60,
    4: 0.50,
    5: 0.40,
    6: 0.32,
    7: 0.25,
    8: 0.18,
    9: 0.12,
  };

  final Random _random = Random();

  int _wuxing = 1;
  int _attempts = 0;
  int _pillsLow = 0; // 低级根骨丹（悟性 0-2）
  int _pillsMid = 0; // 中级根骨丹（悟性 3-5）
  int _pillsHigh = 0; // 高级根骨丹（悟性 6-9）

  bool? _lastSuccess;
  String _lastMessage = '点击下方按钮，开始提悟性';
  int _resultTick = 0; // 驱动结果反馈动画重播

  @override
  void initState() {
    super.initState();
    TrackService().fire('tool_wuxing_open');
  }

  int get _totalPills => _pillsLow + _pillsMid + _pillsHigh;

  double get _currentRate => _successRates[_wuxing] ?? 0;

  bool get _isFloor => _floors.contains(_wuxing);

  String get _pillTier {
    if (_wuxing <= 2) return '低级根骨丹';
    if (_wuxing <= 5) return '中级根骨丹';
    return '高级根骨丹';
  }

  /// 模拟一次提悟性，返回 (是否成功, 变化前等级, 变化后等级)
  (bool, int, int) _rollOnce() {
    final from = _wuxing;
    final success = _random.nextDouble() < _currentRate;
    if (success) {
      _wuxing = min(_maxWuxing, _wuxing + 1);
    } else if (!_isFloor) {
      _wuxing = max(1, _wuxing - 1);
    }
    return (success, from, _wuxing);
  }

  void _consumePill(int level) {
    if (level <= 2) {
      _pillsLow++;
    } else if (level <= 5) {
      _pillsMid++;
    } else {
      _pillsHigh++;
    }
  }

  void _tryOnce() {
    if (_wuxing >= _maxWuxing) return;
    setState(() {
      _attempts++;
      _consumePill(_wuxing);
      final (success, from, to) = _rollOnce();
      _lastSuccess = success;
      _resultTick++;
      if (success) {
        _lastMessage = to >= _maxWuxing ? '悟性提升到 $to！圆满毕业！' : '悟性提升成功！$from → $to';
      } else if (to == from) {
        _lastMessage = '提升失败，$from 级为保底节点，不掉级';
      } else {
        _lastMessage = '提升失败，悟性掉落 $from → $to';
      }
    });
  }

  void _batchSimulate() {
    if (_wuxing >= _maxWuxing) return;
    int tries = 0;
    int pills = 0;
    int worstFrom = _wuxing;
    int worstTo = _wuxing;
    int failStreak = 0;
    int maxFailStreak = 0;

    while (_wuxing < _maxWuxing && tries < _batchLimit) {
      tries++;
      pills++;
      _consumePill(_wuxing);
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
      _lastSuccess = _wuxing >= _maxWuxing ? true : null;
      _resultTick++;
      _lastMessage = _wuxing >= _maxWuxing
          ? '批量模拟完成：$tries 次尝试后悟性到 10'
          : '达到 $_batchLimit 次上限，悟性停在 $_wuxing';
    });

    final reached = _wuxing >= _maxWuxing;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.of(context).card,
        title: Text(reached ? '批量模拟结果' : '未能在上限内到 10', style: TextStyle(color: AppColors.of(context).ink)),
        content: Text(
          '共尝试 $tries 次\n消耗根骨丹 $pills 个\n'
          '最长连败 $maxFailStreak 次\n'
          '最惨一次：从 $worstFrom 掉到 $worstTo',
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
      _wuxing = 1;
      _attempts = 0;
      _pillsLow = 0;
      _pillsMid = 0;
      _pillsHigh = 0;
      _lastSuccess = null;
      _lastMessage = '已重置，重新开始提悟性';
      _resultTick++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('珍兽悟性模拟器')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildIntro(),
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
            Text('悟性规则速览', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.of(context).ink)),
            const SizedBox(height: 8),
            ...[
              '悟性按比例加成珍兽资质，悟性越高加成越多（官方未公布精确加成比例，以游戏内实测为准）',
              '提悟性用根骨丹：低级（悟性 0-2）、中级（3-5）、高级（6-9），每点一次无论成败消耗 1 个',
              '保底节点：悟性到 4 / 7 / 9 后，失败不会跌回该节点以下；其余等级失败掉 1 级',
              '民间经验：材料珍兽根骨与当前悟性越接近成功率越高；8 上 9、9 上 10 是公认的烧钱坑（玄学成分高，仅供参考）',
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

  Widget _buildSimulator() {
    final maxed = _wuxing >= _maxWuxing;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text('当前悟性', style: TextStyle(fontSize: 12, color: AppColors.of(context).inkLight)),
            const SizedBox(height: 4),
            Text(
              '$_wuxing',
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
            // 成功/失败反馈（成功金色 / 失败灰色，带动画）
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
              maxed ? '悟性已满 10 级' : '当前成功率约 ${(_currentRate * 100).toStringAsFixed(0)}%（存疑，以实测为准）· 消耗 $_pillTier',
              style: TextStyle(fontSize: 12, color: AppColors.of(context).inkLight),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: maxed ? null : _tryOnce,
                    icon: const Icon(Icons.auto_fix_high, size: 18),
                    label: const Text('提悟性'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: maxed ? null : _batchSimulate,
                    icon: const Icon(Icons.fast_forward, size: 18),
                    label: const Text('批量模拟'),
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
            Text('本次模拟统计', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.of(context).ink)),
            const SizedBox(height: 12),
            Row(
              children: [
                _statItem('尝试次数', '$_attempts'),
                _statItem('根骨丹总数', '$_totalPills'),
                _statItem('低/中/高级丹', '$_pillsLow/$_pillsMid/$_pillsHigh'),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text('悟性进度', style: TextStyle(fontSize: 12, color: AppColors.of(context).inkLight)),
                const SizedBox(width: 8),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: _wuxing / _maxWuxing,
                      minHeight: 8,
                      backgroundColor: AppColors.of(context).inkLight.withOpacity(0.15),
                      valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text('$_wuxing/$_maxWuxing', style: TextStyle(fontSize: 12, color: AppColors.of(context).ink)),
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
            Text('各等级成功率（模拟用）', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.of(context).ink)),
            const SizedBox(height: 4),
            Text(
              '【存疑】官方未公布精确成功率，下表按资料中民间说法取的递减估计值，以游戏内实测为准',
              style: TextStyle(fontSize: 11, color: AppColors.of(context).inkLight, height: 1.5),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _successRates.entries.map((e) {
                final current = e.key == _wuxing;
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: current ? AppColors.primary.withOpacity(0.15) : AppColors.of(context).inkLight.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(8),
                    border: current ? Border.all(color: AppColors.primary) : null,
                  ),
                  child: Text(
                    '${e.key}→${e.key + 1}：${(e.value * 100).toStringAsFixed(0)}%',
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
