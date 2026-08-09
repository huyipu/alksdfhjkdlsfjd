import 'dart:convert';

import 'package:flutter/material.dart';
import '../services/track_service.dart';
import '../utils/prefs.dart';
import '../utils/theme.dart';

/// 打书规划器
///
/// 规则来源：tlbb-guide/05-门派与珍兽.md §3.6
/// - 宝宝最多 7 技能 = 2 手动 + 5 自动【官方确定】
/// - 手动分破军、开阳两类，只有不同类才不互顶【官方确定】
/// - 自身特性类只能存在 1 本；攻击技能只上 1 本；辅主技能可共存 3 本【攻略观点】
/// - 资料未明确的互顶关系，页面统一注明"以游戏内实测为准"
class BookPlannerPage extends StatefulWidget {
  const BookPlannerPage({super.key});

  @override
  State<BookPlannerPage> createState() => _BookPlannerPageState();
}

class _SkillGroup {
  final String title;
  final List<String> skills;
  const _SkillGroup(this.title, this.skills);
}

class _BookPlannerPageState extends State<BookPlannerPage> {
  static const String _prefsKey = 'book_planner_plan';
  static const int _slotCount = 7;

  /// 技能池（按资料 §3.6 提及的经典技能整理，分组为规划辅助，非官方分类）
  static const String _groupPojun = '破军类（手动 · 攻击向）';
  static const String _groupKaiyang = '开阳类（手动 · 辅助向）';
  static const List<_SkillGroup> _skillGroups = [
    _SkillGroup(_groupPojun, [
      '五雷轰顶', '烈火燎原', '冰天雪地', '血毒万里', // 新群
      '劫火焚杀', '极冰凝杀', '腐毒蚀杀', '玄雷击杀', // 老群（冷却短伤害高，书贵）
      '咆哮', '冰爆', '附身',
    ]),
    _SkillGroup(_groupKaiyang, [
      '高级嗜血', '高级血祭', '神佑', '高级净化', '净化', '重生', '肉墙', '解穴',
    ]),
    _SkillGroup('攻击类（自动）', [
      '猛击', '痛击', '连击', '打怒', '反击', '反震', '摔绊', '虚弱', '破绽', '吸气',
    ]),
    _SkillGroup('辅主类（自动 · 可共存 3 本）', [
      '强身', '凝神', '瞬影', '迟钝（大智若愚）', '灵气', '忠心', '识破', '灵动', '借力', '移魂',
    ]),
    _SkillGroup('特性/咒类（自动）', [
      '狡猾', '蛮力', '法魂', '拼命', // 自身特性类：只能存在 1 本【攻略观点】
      '力拔山河', '神游四海',
      '烈火咒', '玄雷咒', '寒冰咒', '天雷咒', '嗜毒咒',
      '毒罡', '冰精', '冰魂', '冰罡', '毒魂', '火灵',
    ]),
  ];

  /// 自身特性类：资料称"只能存在 1 本"【攻略观点】
  static const Set<String> _traitSkills = {'狡猾', '蛮力', '法魂', '拼命', '迟钝（大智若愚）'};

  final List<String?> _slots = List.filled(_slotCount, null);
  String? _selectedSkill;
  final _nameController = TextEditingController(text: '方案一');

  @override
  void initState() {
    super.initState();
    TrackService().fire('tool_book_open');
    _loadSilently();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  bool _isPojun(String skill) => _skillGroups[0].skills.contains(skill);
  bool _isKaiyang(String skill) => _skillGroups[1].skills.contains(skill);

  String _slotLabel(int index) {
    if (index == 0) return '破军位';
    if (index == 1) return '开阳位';
    return '自动 ${index - 1}';
  }

  void _toast(String msg, {bool warning = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(msg),
        backgroundColor: warning ? AppColors.accent : AppColors.of(context).ink,
        duration: const Duration(seconds: 2),
      ));
  }

  void _onSkillTap(String skill) {
    setState(() => _selectedSkill = _selectedSkill == skill ? null : skill);
  }

  void _onSlotTap(int index) {
    final skill = _selectedSkill;
    if (skill == null) {
      if (_slots[index] != null) {
        setState(() => _slots[index] = null);
        _toast('已移除「${_slotLabel(index)}」的技能');
      } else {
        _toast('先在下方技能池选择一本技能书，再点格子打书');
      }
      return;
    }

    // 格子已被占用
    if (_slots[index] != null) {
      _toast('该格已有技能，先点一次格子移除再打书', warning: true);
      return;
    }
    // 同一技能不可重复
    if (_slots.contains(skill)) {
      _toast('「$skill」已经在方案里了，同一技能不可重复打', warning: true);
      return;
    }
    // 破军位 / 开阳位类别校验（手动技能不同类才不互顶【官方确定】）
    if (index == 0 && !_isPojun(skill)) {
      _toast('破军位只能打破军类手动技能', warning: true);
      return;
    }
    if (index == 1 && !_isKaiyang(skill)) {
      _toast('开阳位只能打开阳类手动技能', warning: true);
      return;
    }
    if (index >= 2 && (_isPojun(skill) || _isKaiyang(skill))) {
      _toast('手动技能只能打在破军位/开阳位', warning: true);
      return;
    }
    // 互顶警告：自身特性类只能存在 1 本【攻略观点】
    if (_traitSkills.contains(skill)) {
      final existing = _slots.whereType<String>().where((s) => _traitSkills.contains(s)).toList();
      if (existing.isNotEmpty) {
        _toast('警告：自身特性类只能存在 1 本（攻略观点），已有「${existing.first}」，可能与「$skill」互顶，以游戏内实测为准', warning: true);
      }
    }

    setState(() {
      _slots[index] = skill;
      _selectedSkill = null;
    });
  }

  Future<void> _savePlan() async {
    final name = _nameController.text.trim().isEmpty ? '方案一' : _nameController.text.trim();
    final data = jsonEncode({'name': name, 'slots': _slots});
    await Prefs().setString(_prefsKey, data);
    _toast('方案「$name」已保存到本地');
  }

  void _loadSilently() {
    final raw = Prefs().getString(_prefsKey);
    if (raw == null) return;
    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      final slots = (data['slots'] as List).map((e) => e as String?).toList();
      if (slots.length == _slotCount) {
        setState(() {
          for (var i = 0; i < _slotCount; i++) {
            _slots[i] = slots[i];
          }
          _nameController.text = (data['name'] as String?) ?? '方案一';
        });
      }
    } catch (_) {
      // 本地数据损坏则忽略
    }
  }

  void _loadPlan() {
    final raw = Prefs().getString(_prefsKey);
    if (raw == null) {
      _toast('还没有保存过方案');
      return;
    }
    _loadSilently();
    _toast('已读取保存的方案');
  }

  void _clearPlan() {
    setState(() {
      for (var i = 0; i < _slotCount; i++) {
        _slots[i] = null;
      }
      _selectedSkill = null;
    });
    _toast('已清空当前方案（不影响已保存的方案）');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('打书规划器')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildIntro(),
          const SizedBox(height: 16),
          _buildSlots(),
          const SizedBox(height: 16),
          _buildPlanActions(),
          const SizedBox(height: 16),
          _buildSkillPool(),
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
            Text('打书规则速览', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.of(context).ink)),
            const SizedBox(height: 8),
            ...[
              '宝宝最多学 7 个技能 = 2 个手动 + 5 个自动，洛阳云渺渺处学习',
              '手动技能分破军、开阳两类，只有不同类才不互顶；同类手动互相顶替',
              '学习新技能很大概率顶替原有技能——这就是打书的核心风险',
              '自身特性类只能存在 1 本；攻击技能只上 1 本；辅主技能可共存 3 本（攻略观点）',
              '互顶关系资料整理自玩家攻略，不保证完整；资料未明确的一律以游戏内实测为准',
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

  Widget _buildSlots() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _selectedSkill == null ? '技能格（点技能书 → 点格子打书；点已打格子移除）' : '已选中「$_selectedSkill」，点一个格子打上去',
              style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.of(context).ink, fontSize: 13),
            ),
            const SizedBox(height: 12),
            // 手动位：破军位 + 开阳位
            Row(
              children: [
                Expanded(child: _buildSlot(0, manual: true)),
                const SizedBox(width: 10),
                Expanded(child: _buildSlot(1, manual: true)),
              ],
            ),
            const SizedBox(height: 10),
            // 自动位 5 格
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.7,
              children: List.generate(5, (i) => _buildSlot(i + 2)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlot(int index, {bool manual = false}) {
    final skill = _slots[index];
    final filled = skill != null;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => _onSlotTap(index),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: filled ? AppColors.primary.withOpacity(0.08) : AppColors.of(context).bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: manual ? AppColors.primary : (filled ? AppColors.primaryLight : AppColors.of(context).inkLight.withOpacity(0.3)),
            width: manual ? 1.6 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (manual)
              Container(
                margin: const EdgeInsets.only(bottom: 4),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(4)),
                child: Text(_slotLabel(index), style: const TextStyle(fontSize: 10, color: Colors.white)),
              ),
            if (!manual && !filled)
              Text(_slotLabel(index), style: TextStyle(fontSize: 10, color: AppColors.of(context).inkLight)),
            const SizedBox(height: 2),
            Flexible(
              child: Text(
                skill ?? '空格',
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: filled ? FontWeight.bold : FontWeight.normal,
                  color: filled ? AppColors.of(context).ink : AppColors.of(context).inkLight,
                ),
              ),
            ),
            if (filled) Icon(Icons.close, size: 12, color: AppColors.of(context).inkLight),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanActions() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('方案管理', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.of(context).ink)),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: '方案名称',
                filled: true,
                fillColor: AppColors.of(context).bg,
                isDense: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _savePlan,
                    icon: const Icon(Icons.save, size: 18),
                    label: const Text('保存方案'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _loadPlan,
                    icon: const Icon(Icons.folder_open, size: 18),
                    label: const Text('读取方案'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _clearPlan,
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: const Text('清空'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkillPool() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('技能池（经典技能整理自攻略资料）', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.of(context).ink)),
            const SizedBox(height: 4),
            Text(
              '分组为规划辅助而非官方分类；技能高低级版（如 嗜血/高级嗜血）此处按同名占位，实战以高级书替换低级书',
              style: TextStyle(fontSize: 11, color: AppColors.of(context).inkLight, height: 1.5),
            ),
            const SizedBox(height: 8),
            ..._skillGroups.map((g) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Text(g.title, style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.bold)),
                    ),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: g.skills.map((s) {
                        final selected = _selectedSkill == s;
                        final used = _slots.contains(s);
                        return ChoiceChip(
                          label: Text(
                            s,
                            style: TextStyle(
                              fontSize: 12,
                              color: used
                                  ? AppColors.of(context).inkLight
                                  : selected
                                      ? Colors.white
                                      : AppColors.of(context).ink,
                              decoration: used ? TextDecoration.lineThrough : null,
                            ),
                          ),
                          selected: selected,
                          selectedColor: AppColors.primary,
                          onSelected: used ? null : (_) => _onSkillTap(s),
                        );
                      }).toList(),
                    ),
                  ],
                )),
          ],
        ),
      ),
    );
  }
}
