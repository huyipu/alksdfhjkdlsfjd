import 'package:flutter/material.dart';
import '../services/compare_service.dart';
import '../services/data_service.dart';
import '../services/track_service.dart';
import '../utils/theme.dart';
import '../widgets/equipment_detail_sheet.dart';
import '../widgets/icon_image.dart';
import 'collection_page.dart';
import 'compare_page.dart';

/// 图鉴：装备 / 坐骑 / 宝石 / 道具 四大分类
class EncyclopediaPage extends StatefulWidget {
  const EncyclopediaPage({super.key});

  @override
  State<EncyclopediaPage> createState() => _EncyclopediaPageState();
}

class _EncyclopediaPageState extends State<EncyclopediaPage> {
  bool _loading = true;

  // 装备 Tab 状态
  String _keyword = '';
  String _slot = '';
  String _quality = '';

  // 坐骑 Tab 状态
  String _school = '';

  static const _slots = ['武器', '帽子', '衣服', '护腕', '手套', '护肩', '鞋子', '项链', '戒指', '护符', '腰带'];

  @override
  void initState() {
    super.initState();
    CompareService().addListener(_onCompareChanged);
    DataService().load().then((_) {
      if (mounted) setState(() => _loading = false);
    });
  }

  @override
  void dispose() {
    CompareService().removeListener(_onCompareChanged);
    super.dispose();
  }

  void _onCompareChanged() {
    if (mounted) setState(() {});
  }

  List<Equipment> get _filtered {
    return DataService().equipment.where((e) {
      if (_keyword.isNotEmpty &&
          !e.name.contains(_keyword) &&
          !e.set.contains(_keyword) &&
          !e.source.contains(_keyword)) {
        return false;
      }
      if (_slot.isNotEmpty && e.slot != _slot) return false;
      if (_quality.isNotEmpty && e.quality != _quality) return false;
      return true;
    }).toList();
  }

  List<Beast> get _filteredBeasts {
    return DataService().beasts.where((b) => _school.isEmpty || b.school == _school).toList();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('图鉴'),
          bottom: const TabBar(
            tabs: [
              Tab(text: '装备'),
              Tab(text: '坐骑'),
              Tab(text: '宝石'),
              Tab(text: '道具'),
            ],
          ),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  _buildEquipmentTab(),
                  _buildBeastsTab(),
                  _buildGridTab(DataService().gems, (g) => _showGemDetail(g), Icons.diamond_outlined),
                  _buildGridTab(DataService().items, (i) => _showItemDetail(i), Icons.inventory_2_outlined),
                ],
              ),
      ),
    );
  }

  // ---------------- 装备 Tab ----------------

  Widget _buildEquipmentTab() {
    final list = _filtered;
    final hasCompare = CompareService().items.isNotEmpty;
    return Stack(
      children: [
        Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: TextField(
                decoration: InputDecoration(
                  hintText: '搜索装备 / 套装（如：燕王）',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: AppColors.of(context).card,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                ),
                onChanged: (v) => setState(() => _keyword = v.trim()),
              ),
            ),
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                children: [
                  _chip('全部部位', _slot.isEmpty, () => setState(() => _slot = '')),
                  ..._slots.map((s) => _chip(s, _slot == s, () => setState(() => _slot = _slot == s ? '' : s))),
                  const VerticalDivider(width: 20),
                  _chip('全部品质', _quality.isEmpty, () => setState(() => _quality = '')),
                  ...['green', 'blue', 'purple', 'orange'].map(
                    (q) => _chip(AppColors.qualityName(q), _quality == q, () => setState(() => _quality = _quality == q ? '' : q), color: AppColors.qualityColor(q)),
                  ),
                  const VerticalDivider(width: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ActionChip(
                      avatar: const Icon(Icons.checklist, size: 16, color: AppColors.primary),
                      label: Text('套装收集', style: TextStyle(fontSize: 12, color: AppColors.of(context).ink)),
                      onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CollectionPage())),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: list.isEmpty
                  ? Center(
                      child: Text(_keyword.isEmpty ? '图鉴数据整理中' : '没有找到「$_keyword」相关装备',
                          style: TextStyle(color: AppColors.of(context).inkLight)),
                    )
                  : GridView.builder(
                      padding: EdgeInsets.fromLTRB(12, 12, 12, hasCompare ? 76 : 12),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        childAspectRatio: 0.82,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                      ),
                      itemCount: list.length,
                      itemBuilder: (_, i) => _buildEquipmentCard(list[i]),
                    ),
            ),
          ],
        ),
        if (hasCompare) Positioned(left: 12, right: 12, bottom: 12, child: _buildCompareBar()),
      ],
    );
  }

  /// 底部悬浮对比条：已选 1 件时提示再选一件，可清空
  Widget _buildCompareBar() {
    final p = AppColors.of(context);
    final items = CompareService().items;
    final full = items.length >= 2;
    return Material(
      elevation: 6,
      borderRadius: BorderRadius.circular(12),
      color: p.card,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: full ? () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ComparePage())) : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Row(
            children: [
              const Icon(Icons.compare_arrows, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  full ? '已选 2 件，点击查看对比' : '已选 ${items.first.name}，再选一件对比',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13, color: p.ink),
                ),
              ),
              TextButton(onPressed: () => CompareService().clear(), child: const Text('清空')),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ChoiceChip(
        label: Text(label, style: TextStyle(fontSize: 12, color: selected ? Colors.white : color ?? AppColors.of(context).ink)),
        selected: selected,
        selectedColor: color ?? AppColors.primary,
        onSelected: (_) => onTap(),
      ),
    );
  }

  Widget _buildEquipmentCard(Equipment e) {
    final qc = AppColors.qualityColor(e.quality);
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        TrackService().fire('equipment_view');
        showEquipmentDetail(context, e);
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.of(context).card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: qc.withOpacity(0.6), width: 1.5),
        ),
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconImage(icon: e.icon, size: 40, fallbackColor: qc),
            const SizedBox(height: 8),
            Text(
              e.name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: qc),
            ),
            const SizedBox(height: 4),
            Text(
              [if (e.level > 0) 'Lv.${e.level}', if (e.slot.isNotEmpty) e.slot].join(' '),
              style: TextStyle(fontSize: 10, color: AppColors.of(context).inkLight),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------- 坐骑 Tab ----------------

  Widget _buildBeastsTab() {
    final schools = DataService().beasts.map((b) => b.school).toSet().toList();
    final list = _filteredBeasts;
    return Column(
      children: [
        SizedBox(
          height: 44,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            children: [
              _chip('全部门派', _school.isEmpty, () => setState(() => _school = '')),
              ...schools.map((s) => _chip(s, _school == s, () => setState(() => _school = _school == s ? '' : s))),
            ],
          ),
        ),
        Expanded(
          child: list.isEmpty
              ? Center(child: Text('坐骑数据整理中', style: TextStyle(color: AppColors.of(context).inkLight)))
              : GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 0.82,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: list.length,
                  itemBuilder: (_, i) => _buildBeastCard(list[i]),
                ),
        ),
      ],
    );
  }

  Widget _buildBeastCard(Beast b) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => _showBeastDetail(b),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.of(context).card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primary.withOpacity(0.4), width: 1.5),
        ),
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconImage(icon: b.icon, size: 44, fallbackColor: AppColors.primary, fallback: Icons.pets_outlined),
            const SizedBox(height: 8),
            Text(
              b.name,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.of(context).ink),
            ),
            const SizedBox(height: 4),
            Text(b.school, style: TextStyle(fontSize: 10, color: AppColors.of(context).inkLight)),
          ],
        ),
      ),
    );
  }

  // ---------------- 宝石 / 道具 通用网格 ----------------

  Widget _buildGridTab(List<dynamic> list, void Function(dynamic) onTap, IconData fallback) {
    if (list.isEmpty) {
      return Center(child: Text('数据整理中', style: TextStyle(color: AppColors.of(context).inkLight)));
    }
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.82,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: list.length,
      itemBuilder: (_, i) {
        final e = list[i];
        return InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => onTap(e),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.of(context).card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primary.withOpacity(0.4), width: 1.5),
            ),
            padding: const EdgeInsets.all(8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconImage(icon: e.icon as String, size: 40, fallbackColor: AppColors.primary, fallback: fallback),
                const SizedBox(height: 8),
                Text(
                  e.name as String,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.of(context).ink),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ---------------- 详情弹层 ----------------

  void _showBeastDetail(Beast b) {
    _showSimpleDetail(
      icon: b.icon,
      fallback: Icons.pets,
      title: b.name,
      subtitle: '${b.school}门派坐骑',
      fields: [
        if (b.source.isNotEmpty) ('获取方式', b.source),
      ],
      desc: b.desc,
    );
  }

  void _showGemDetail(Gem g) {
    _showSimpleDetail(
      icon: g.icon,
      fallback: Icons.diamond,
      title: g.name,
      subtitle: '宝石（1～9级）',
      fields: [
        if (g.attr.isNotEmpty) ('属性加成', g.attr),
      ],
      desc: g.desc,
    );
  }

  void _showItemDetail(Item i) {
    _showSimpleDetail(
      icon: i.icon,
      fallback: Icons.inventory_2,
      title: i.name,
      subtitle: '经典道具',
      fields: const [],
      desc: i.desc,
    );
  }

  void _showSimpleDetail({
    required String icon,
    required IconData fallback,
    required String title,
    required String subtitle,
    required List<(String, String)> fields,
    required String desc,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.of(context).card,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        maxChildSize: 0.9,
        minChildSize: 0.35,
        expand: false,
        builder: (sheetContext, controller) => ListView(
          controller: controller,
          padding: const EdgeInsets.all(20),
          children: [
            Center(
              child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                IconImage(icon: icon, size: 56, fallbackColor: AppColors.primary, fallback: fallback, radius: 10),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.of(sheetContext).ink)),
                      Text(subtitle, style: TextStyle(fontSize: 12, color: AppColors.of(sheetContext).inkLight)),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 32),
            ...fields.expand((f) => [
                  Text(f.$1, style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.of(sheetContext).ink)),
                  const SizedBox(height: 8),
                  Text(f.$2, style: TextStyle(fontSize: 14, color: AppColors.of(sheetContext).ink, height: 1.6)),
                  const SizedBox(height: 16),
                ]),
            if (desc.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppColors.of(sheetContext).bg, borderRadius: BorderRadius.circular(10)),
                child: Text(desc,
                    style: TextStyle(fontSize: 13, color: AppColors.of(sheetContext).inkLight, height: 1.7, fontStyle: FontStyle.italic)),
              ),
          ],
        ),
      ),
    );
  }
}
