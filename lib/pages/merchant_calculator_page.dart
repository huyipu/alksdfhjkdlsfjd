import 'package:flutter/material.dart';
import '../services/data_service.dart';
import '../utils/theme.dart';

/// 跑商时辰计算器：选商线 → 商品价格表、预计收益、满票提示
class MerchantCalculatorPage extends StatefulWidget {
  const MerchantCalculatorPage({super.key});

  @override
  State<MerchantCalculatorPage> createState() => _MerchantCalculatorPageState();
}

class _MerchantCalculatorPageState extends State<MerchantCalculatorPage> {
  bool _loading = true;
  int _routeIndex = 0;
  final _capitalController = TextEditingController(text: '20000');

  @override
  void initState() {
    super.initState();
    DataService().load().then((_) {
      if (mounted) setState(() => _loading = false);
    });
  }

  @override
  void dispose() {
    _capitalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final routes = DataService().merchantRoutes;
    return Scaffold(
      appBar: AppBar(title: const Text('跑商时辰计算器')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : routes.isEmpty
              ? Center(child: Text('跑商数据整理中', style: TextStyle(color: AppColors.of(context).inkLight)))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildRouteSelector(routes),
                    const SizedBox(height: 16),
                    _buildCapitalInput(),
                    const SizedBox(height: 16),
                    _buildGoodsTable(routes[_routeIndex]),
                    const SizedBox(height: 16),
                    _buildTips(),
                    const SizedBox(height: 12),
                    Center(
                      child: Text('价格为攻略参考价，以怀旧服实测为准', style: TextStyle(fontSize: 11, color: AppColors.of(context).inkLight)),
                    ),
                  ],
                ),
    );
  }

  Widget _buildRouteSelector(List<MerchantRoute> routes) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('选择商线', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.of(context).ink)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: List.generate(routes.length, (i) {
            final r = routes[i];
            final selected = _routeIndex == i;
            return ChoiceChip(
              label: Text('${r.name}（Lv.${r.minLevel}+）', style: TextStyle(fontSize: 12, color: selected ? Colors.white : AppColors.of(context).ink)),
              selected: selected,
              selectedColor: AppColors.primary,
              onSelected: (_) => setState(() => _routeIndex = i),
            );
          }),
        ),
        if (routes[_routeIndex].note.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(routes[_routeIndex].note, style: TextStyle(fontSize: 12, color: AppColors.of(context).inkLight, height: 1.5)),
          ),
      ],
    );
  }

  Widget _buildCapitalInput() {
    return TextField(
      controller: _capitalController,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: '本金（银两）',
        hintText: '输入你的跑商本金',
        filled: true,
        fillColor: AppColors.of(context).card,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
      onChanged: (_) => setState(() {}),
    );
  }

  // 价格格式化：整数不带小数点，小数保留原样（如 0.8）
  static String _fmt(double v) => v == v.roundToDouble() ? v.toInt().toString() : v.toString();

  Widget _buildGoodsTable(MerchantRoute route) {
    final capital = int.tryParse(_capitalController.text) ?? 0;
    final goods = List<MerchantGood>.from(route.goods)..sort((a, b) => b.profit.compareTo(a.profit));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('商品价格与收益（按利润排序）', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.of(context).ink)),
            const SizedBox(height: 8),
            Table(
              columnWidths: const {0: FlexColumnWidth(2), 1: FlexColumnWidth(1.3), 2: FlexColumnWidth(1.3), 3: FlexColumnWidth(1.5)},
              children: [
                TableRow(
                  decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.black12))),
                  children: [
                    Padding(padding: EdgeInsets.symmetric(vertical: 6), child: Text('商品', style: TextStyle(fontSize: 12, color: AppColors.of(context).inkLight))),
                    Padding(padding: EdgeInsets.symmetric(vertical: 6), child: Text('买入', style: TextStyle(fontSize: 12, color: AppColors.of(context).inkLight))),
                    Padding(padding: EdgeInsets.symmetric(vertical: 6), child: Text('卖出', style: TextStyle(fontSize: 12, color: AppColors.of(context).inkLight))),
                    Padding(padding: EdgeInsets.symmetric(vertical: 6), child: Text('可购/收益', style: TextStyle(fontSize: 12, color: AppColors.of(context).inkLight))),
                  ],
                ),
                ...goods.map((g) {
                  final count = g.buyPrice > 0 ? (capital / g.buyPrice).floor() : 0;
                  final profit = count * g.profit;
                  return TableRow(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(g.name, style: TextStyle(fontSize: 13, color: AppColors.of(context).ink)),
                            if (g.note.isNotEmpty)
                              Text(g.note, style: TextStyle(fontSize: 10, color: AppColors.of(context).inkLight)),
                          ],
                        ),
                      ),
                      Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text(g.buyPrice > 0 ? _fmt(g.buyPrice) : '-', style: const TextStyle(fontSize: 13))),
                      Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text(g.sellPrice > 0 ? _fmt(g.sellPrice) : '-', style: const TextStyle(fontSize: 13))),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          count > 0 ? '$count 件 / +${_fmt(profit)}' : '-',
                          style: TextStyle(fontSize: 13, color: profit > 0 ? AppColors.qGreen : AppColors.of(context).inkLight, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  );
                }),
              ],
            ),
            if (goods.isEmpty)
              Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: Text('该商线价格数据待补充', style: TextStyle(color: AppColors.of(context).inkLight))),
              ),
            Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text('注：怀旧服价格随时辰波动，以游戏内实测为准', style: TextStyle(fontSize: 11, color: AppColors.of(context).inkLight)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTips() {
    final tips = DataService().merchantTips;
    if (tips.isEmpty) return const SizedBox.shrink();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('满票技巧与翻车点', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.of(context).ink)),
            const SizedBox(height: 8),
            ...tips.map((t) => Padding(
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
}
