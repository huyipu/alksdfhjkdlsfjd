import 'package:flutter/material.dart';
import '../utils/theme.dart';

/// 珍兽繁殖估算器
///
/// 规则来源：
/// - 官方资料（tlbb-guide/05-门派与珍兽.md §3.2）：繁殖门槛 30 级首次、之后每次 +20 级；
///   条件为同种宝宝、性别不同、快乐度 100、寿命 ≥1000、非变异/二代/成年、非出战等；
///   繁殖成功后 48 小时内需组队到苏州云霏霏处领取，逾期亲代与二代全部消失。
/// - 二代成长率 = 父母成长率的平均值【官方公众号/TapTap 官方号确认】；
///   父母双完美 → 二代必为完美（《天龙八部·归来》官方资料站）。
/// - 二代资质与父母资质的关系【存疑】：玩家社区主流说法是"与父母资质基本无关，
///   主要由变异等级决定，变异越高资质范围越高"（百度知道/B 站专栏多方一致）；
///   也有"父母资质高更容易出好二代"的经验之谈。本页估算以父母平均资质为参照系，
///   按变异等级给出区间，仅为经验估计，以游戏内实测为准。
/// - 变异概率 / 二代性格：官方未公布精确数值【存疑】。
class BreedingCalculatorPage extends StatefulWidget {
  const BreedingCalculatorPage({super.key});

  @override
  State<BreedingCalculatorPage> createState() => _BreedingCalculatorPageState();
}

class _BreedingCalculatorPageState extends State<BreedingCalculatorPage> {
  /// 成长率五档（官方确定档位名称）
  static const List<String> _growthTiers = ['普通', '优秀', '杰出', '卓越', '完美'];

  final _fatherQualController = TextEditingController(text: '1600');
  final _motherQualController = TextEditingController(text: '1600');

  int _fatherGrowth = 3; // 卓越
  int _motherGrowth = 3;

  @override
  void dispose() {
    _fatherQualController.dispose();
    _motherQualController.dispose();
    super.dispose();
  }

  int get _fatherQual => int.tryParse(_fatherQualController.text) ?? 0;
  int get _motherQual => int.tryParse(_motherQualController.text) ?? 0;

  /// 二代成长率档位：父母平均值（官方确定的继承规则）
  int get _childGrowthTier => ((_fatherGrowth + _motherGrowth) / 2).round();

  /// 二代资质估算区间（按变异等级）。
  /// 【存疑】主流说法：二代资质与父母资质基本无关、由变异等级决定；
  /// 此处以父母平均资质为参照基数给出经验区间，变异每高 1 级区间整体上移，以实测为准。
  (int, int) _estimateRange(int variantLevel) {
    final base = (_fatherQual + _motherQual) / 2;
    if (base <= 0) return (0, 0);
    final lowFactor = 1.05 + 0.08 * variantLevel;
    final highFactor = 1.25 + 0.12 * variantLevel;
    return ((base * lowFactor).round(), (base * highFactor).round());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('珍兽繁殖估算器')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildIntro(),
          const SizedBox(height: 16),
          _buildInputs(),
          const SizedBox(height: 16),
          _buildResult(),
          const SizedBox(height: 16),
          _buildVariantTable(),
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
            Text('繁殖规则速览', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.of(context).ink)),
            const SizedBox(height: 8),
            ...[
              '繁殖门槛【官方】：首次 30 级，之后每繁殖过 1 次 +20 级（50/70/90）；同种宝宝、性别不同、快乐度 100、寿命 ≥1000、非变异/二代/成年、非出战，队长金钱 ≥2 金',
              '领取【官方】：繁殖成功后系统发邮件，双方组队到苏州云霏霏处领取；48 小时无人领取，亲代与二代全部消失；单人可用"爱心小窝"繁殖（留 4 个珍兽位）',
              '二代成长率 = 父母成长率的平均值【官方确认】；父母双完美则二代必为完美——繁殖前建议先用还童天书把成长率洗到"卓越"以上',
              '二代资质【存疑】：社区主流说法是与父母资质基本无关、主要由变异等级决定（变异越高资质范围越高）；也有"高资质父母更易出好二代"的经验说，以游戏内实测为准',
              '变异概率、二代性格规律【存疑】：官方未公布，"勇猛+忠诚=精明"等配方仅为玩家说法',
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

  Widget _buildInputs() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('父母资质与成长率', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.of(context).ink)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _qualInput(_fatherQualController, '父方主资质')),
                const SizedBox(width: 12),
                Expanded(child: _qualInput(_motherQualController, '母方主资质')),
              ],
            ),
            const SizedBox(height: 16),
            _growthSelector('父方成长率', _fatherGrowth, (v) => setState(() => _fatherGrowth = v)),
            const SizedBox(height: 12),
            _growthSelector('母方成长率', _motherGrowth, (v) => setState(() => _motherGrowth = v)),
          ],
        ),
      ),
    );
  }

  Widget _qualInput(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        hintText: '如 1600',
        filled: true,
        fillColor: AppColors.of(context).card,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
      onChanged: (_) => setState(() {}),
    );
  }

  Widget _growthSelector(String label, int value, ValueChanged<int> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: AppColors.of(context).inkLight)),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: List.generate(_growthTiers.length, (i) {
            final selected = value == i;
            return ChoiceChip(
              label: Text(_growthTiers[i], style: TextStyle(fontSize: 12, color: selected ? Colors.white : AppColors.of(context).ink)),
              selected: selected,
              selectedColor: AppColors.primary,
              onSelected: (_) => onChanged(i),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildResult() {
    final childTier = _childGrowthTier;
    final bothPerfect = _fatherGrowth == 4 && _motherGrowth == 4;
    final base = (_fatherQual + _motherQual) / 2;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('二代估算结果', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.of(context).ink)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        _growthTiers[childTier],
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary),
                      ),
                      const SizedBox(height: 2),
                      Text('二代成长率（平均继承）', style: TextStyle(fontSize: 11, color: AppColors.of(context).inkLight)),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        base > 0 ? base.toStringAsFixed(0) : '-',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.of(context).ink),
                      ),
                      const SizedBox(height: 2),
                      Text('父母平均资质（参照基数）', style: TextStyle(fontSize: 11, color: AppColors.of(context).inkLight)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (bothPerfect)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('父母双完美 → 二代成长率必为完美【官方】', style: TextStyle(fontSize: 12, color: AppColors.primary)),
              )
            else
              Text(
                '提示：一方成长率偏低会拉低二代成长率，繁殖前建议用还童天书洗到"卓越"以上再生',
                style: TextStyle(fontSize: 12, color: AppColors.of(context).inkLight, height: 1.5),
              ),
            const SizedBox(height: 8),
            Text(
              '二代资质：官方未公布计算公式，社区主流说法为"与父母资质基本无关、由变异等级决定"。下表以父母平均资质为参照给出经验区间【存疑，以实测为准】。',
              style: TextStyle(fontSize: 11, color: AppColors.of(context).inkLight, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVariantTable() {
    final valid = _fatherQual > 0 && _motherQual > 0;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('按变异等级的资质区间估算', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.of(context).ink)),
            const SizedBox(height: 4),
            Text(
              '【存疑】经验估计：非变异二代约为参照基数的 1.05~1.25 倍，变异每高 1 级区间整体上移；变异概率官方未公布，顶变极稀有',
              style: TextStyle(fontSize: 11, color: AppColors.of(context).inkLight, height: 1.5),
            ),
            const SizedBox(height: 8),
            Table(
              columnWidths: const {0: FlexColumnWidth(1.4), 1: FlexColumnWidth(1.6), 2: FlexColumnWidth(2)},
              children: [
                TableRow(
                  decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Colors.black12))),
                  children: [
                    Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Text('变异等级', style: TextStyle(fontSize: 12, color: AppColors.of(context).inkLight))),
                    Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Text('估算区间', style: TextStyle(fontSize: 12, color: AppColors.of(context).inkLight))),
                    Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Text('说明', style: TextStyle(fontSize: 12, color: AppColors.of(context).inkLight))),
                  ],
                ),
                ...List.generate(5, (v) {
                  final (low, high) = _estimateRange(v);
                  final name = v == 0 ? '非变异' : '变异 $v 级';
                  final note = switch (v) {
                    0 => '最常见的结果',
                    1 => '小变异，略有提升',
                    2 => '资质区间明显上移',
                    3 => '如 3 变老虎=黑老虎',
                    _ => '高变/顶变，市场价值高',
                  };
                  return TableRow(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(name, style: TextStyle(fontSize: 12, color: AppColors.of(context).ink, fontWeight: v >= 3 ? FontWeight.bold : FontWeight.normal)),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          valid ? '$low ~ $high' : '-',
                          style: TextStyle(fontSize: 12, color: v >= 3 ? AppColors.primary : AppColors.of(context).ink),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(note, style: TextStyle(fontSize: 12, color: AppColors.of(context).inkLight)),
                      ),
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
}
