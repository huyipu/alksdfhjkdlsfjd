import 'dart:async';

import 'package:flutter/material.dart';
import '../services/data_service.dart';
import '../services/history_service.dart';
import '../services/track_service.dart';
import '../utils/theme.dart';
import '../widgets/equipment_detail_sheet.dart';
import '../widgets/icon_image.dart';
import 'article_detail_page.dart';

/// 全站搜索：装备 / 坐骑 / 宝石 / 道具 / 攻略 统一模糊检索
class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _controller = TextEditingController();
  Timer? _debounce;
  String _keyword = '';
  final Set<String> _expanded = {}; // 已展开"查看全部"的分组

  static const _hotWords = ['燕王套', '秦皇套', '缥缈峰', '燕子坞', '跑商', '丐帮', '红宝石', '重楼'];

  @override
  void initState() {
    super.initState();
    TrackService().fire('page_enter:search');
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _keyword = v.trim());
    });
  }

  void _searchNow(String v) {
    _debounce?.cancel();
    _controller.text = v;
    _controller.selection = TextSelection.collapsed(offset: v.length);
    setState(() => _keyword = v.trim());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: '搜索装备 / 攻略 / 宝石…',
            hintStyle: TextStyle(fontSize: 15, color: AppColors.of(context).inkLight),
            border: InputBorder.none,
            suffixIcon: _keyword.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 20),
                    onPressed: () {
                      _controller.clear();
                      setState(() => _keyword = '');
                    },
                  )
                : null,
          ),
          onChanged: _onChanged,
          onSubmitted: _searchNow,
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_keyword.isEmpty) return _buildHotWords();
    final r = DataService().search(_keyword);
    if (r.isEmpty) {
      return Center(
        child: Text('没有找到「$_keyword」相关内容', style: TextStyle(color: AppColors.of(context).inkLight)),
      );
    }
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        if (r.equipment.isNotEmpty) _buildSection('equipment', '装备', r.equipment.length, r.equipment.map(_buildEquipmentTile)),
        if (r.beasts.isNotEmpty) _buildSection('beasts', '坐骑', r.beasts.length, r.beasts.map(_buildBeastTile)),
        if (r.gems.isNotEmpty) _buildSection('gems', '宝石', r.gems.length, r.gems.map(_buildGemTile)),
        if (r.items.isNotEmpty) _buildSection('items', '道具', r.items.length, r.items.map(_buildItemTile)),
        if (r.articles.isNotEmpty) _buildSection('articles', '攻略', r.articles.length, r.articles.map(_buildArticleTile)),
      ],
    );
  }

  // ---------------- 空关键词：热门搜索 ----------------

  Widget _buildHotWords() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('热门搜索', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.of(context).inkLight)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _hotWords
              .map((w) => ActionChip(
                    label: Text(w, style: TextStyle(fontSize: 13, color: AppColors.of(context).ink)),
                    backgroundColor: AppColors.of(context).card,
                    onPressed: () => _searchNow(w),
                  ))
              .toList(),
        ),
      ],
    );
  }

  // ---------------- 分组 ----------------

  Widget _buildSection(String key, String title, int total, Iterable<Widget> tiles) {
    final expanded = _expanded.contains(key);
    final list = expanded ? tiles.toList() : tiles.take(5).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary)),
        ),
        ...list,
        if (!expanded && total > 5)
          InkWell(
            onTap: () => setState(() => _expanded.add(key)),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Center(
                child: Text('查看全部 $total 条', style: const TextStyle(fontSize: 13, color: AppColors.primary)),
              ),
            ),
          ),
      ],
    );
  }

  Widget _tile({
    required String icon,
    required IconData fallback,
    required Color fallbackColor,
    required String name,
    required String subtitle,
    Color? nameColor,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: IconImage(icon: icon, size: 36, fallbackColor: fallbackColor, fallback: fallback),
      title: Text(name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: nameColor ?? AppColors.of(context).ink)),
      subtitle: subtitle.isNotEmpty
          ? Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: AppColors.of(context).inkLight))
          : null,
      onTap: onTap,
    );
  }

  // ---------------- 各类条目 ----------------

  Widget _buildEquipmentTile(Equipment e) {
    final qc = AppColors.qualityColor(e.quality);
    return _tile(
      icon: e.icon,
      fallback: Icons.shield_outlined,
      fallbackColor: qc,
      name: e.name,
      nameColor: qc,
      subtitle: [AppColors.qualityName(e.quality), if (e.slot.isNotEmpty) e.slot, if (e.level > 0) 'Lv.${e.level}'].join(' · '),
      onTap: () {
        TrackService().fire('equipment_view');
        showEquipmentDetail(context, e);
      },
    );
  }

  Widget _buildBeastTile(Beast b) {
    return _tile(
      icon: b.icon,
      fallback: Icons.pets_outlined,
      fallbackColor: AppColors.primary,
      name: b.name,
      subtitle: b.school.isNotEmpty ? '${b.school}门派坐骑' : '坐骑',
      onTap: () => _showSimpleDetail(
        icon: b.icon,
        fallback: Icons.pets,
        title: b.name,
        subtitle: b.school.isNotEmpty ? '${b.school}门派坐骑' : '坐骑',
        fields: [if (b.source.isNotEmpty) ('获取方式', b.source)],
        desc: b.desc,
      ),
    );
  }

  Widget _buildGemTile(Gem g) {
    return _tile(
      icon: g.icon,
      fallback: Icons.diamond_outlined,
      fallbackColor: AppColors.primary,
      name: g.name,
      subtitle: g.attr,
      onTap: () => _showSimpleDetail(
        icon: g.icon,
        fallback: Icons.diamond,
        title: g.name,
        subtitle: '宝石（1～9级）',
        fields: [if (g.attr.isNotEmpty) ('属性加成', g.attr)],
        desc: g.desc,
      ),
    );
  }

  Widget _buildItemTile(Item i) {
    return _tile(
      icon: i.icon,
      fallback: Icons.inventory_2_outlined,
      fallbackColor: AppColors.primary,
      name: i.name,
      subtitle: '经典道具',
      onTap: () => _showSimpleDetail(
        icon: i.icon,
        fallback: Icons.inventory_2,
        title: i.name,
        subtitle: '经典道具',
        fields: const [],
        desc: i.desc,
      ),
    );
  }

  Widget _buildArticleTile(Article a) {
    final catName = DataService.categories[a.category] ?? '综合';
    return _tile(
      icon: '',
      fallback: Icons.article_outlined,
      fallbackColor: AppColors.primary,
      name: a.title,
      subtitle: '$catName · ${a.summary}',
      onTap: () {
        TrackService().fire('article_open');
        HistoryService().record(a.id);
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => ArticleDetailPage(article: a)));
      },
    );
  }

  // ---------------- 简易详情弹层（与图鉴一致） ----------------

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
