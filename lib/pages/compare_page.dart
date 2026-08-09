import 'package:flutter/material.dart';
import '../services/compare_service.dart';
import '../services/data_service.dart';
import '../services/track_service.dart';
import '../utils/theme.dart';
import '../widgets/icon_image.dart';

/// 装备对比：双栏对照两件装备，同名属性数值不同才高亮
class ComparePage extends StatefulWidget {
  const ComparePage({super.key});

  @override
  State<ComparePage> createState() => _ComparePageState();
}

class _ComparePageState extends State<ComparePage> {
  @override
  void initState() {
    super.initState();
    TrackService().fire('page_enter:compare');
    CompareService().addListener(_onChanged);
  }

  @override
  void dispose() {
    CompareService().removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    if (!mounted) return;
    if (CompareService().items.length < 2) {
      Navigator.of(context).pop();
    } else {
      setState(() {});
    }
  }

  /// 属性按冒号前的属性名配对：返回 属性名 -> 数值
  Map<String, String> _parseAttrs(List<String> attrs) {
    final map = <String, String>{};
    for (final a in attrs) {
      var idx = a.indexOf('：');
      if (idx < 0) idx = a.indexOf(':');
      if (idx > 0) {
        map[a.substring(0, idx).trim()] = a.substring(idx + 1).trim();
      } else {
        map[a.trim()] = '';
      }
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final p = AppColors.of(context);
    final items = CompareService().items;
    return Scaffold(
      appBar: AppBar(
        title: const Text('装备对比'),
        actions: [
          if (items.isNotEmpty)
            IconButton(tooltip: '清空对比', icon: const Icon(Icons.delete_outline), onPressed: () => CompareService().clear()),
        ],
      ),
      body: items.length < 2
          ? Center(child: Text('请在图鉴中选择两件装备加入对比', style: TextStyle(color: p.inkLight)))
          : _buildCompare(items[0], items[1]),
    );
  }

  Widget _buildCompare(Equipment a, Equipment b) {
    final aAttrs = _parseAttrs(a.attrs);
    final bAttrs = _parseAttrs(b.attrs);
    final attrNames = <String>[...aAttrs.keys, ...bAttrs.keys.where((k) => !aAttrs.containsKey(k))];

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _buildHeader(a)),
            const SizedBox(width: 8),
            Expanded(child: _buildHeader(b)),
          ],
        ),
        const SizedBox(height: 12),
        Card(
          margin: EdgeInsets.zero,
          child: Column(
            children: [
              _row('品质', AppColors.qualityName(a.quality), AppColors.qualityName(b.quality),
                  highlight: a.quality != b.quality,
                  colorA: AppColors.qualityColor(a.quality),
                  colorB: AppColors.qualityColor(b.quality)),
              _row('部位', a.slot.isEmpty ? '—' : a.slot, b.slot.isEmpty ? '—' : b.slot),
              _row('等级', a.level > 0 ? 'Lv.${a.level}' : '—', b.level > 0 ? 'Lv.${b.level}' : '—'),
              _row('套装', a.set.isEmpty ? '散件' : a.set, b.set.isEmpty ? '散件' : b.set),
              const Divider(height: 1),
              ...attrNames.map((name) {
                final va = aAttrs[name];
                final vb = bAttrs[name];
                final both = va != null && vb != null;
                return _row(name, va ?? '—', vb ?? '—', highlight: both && va != vb);
              }),
              const Divider(height: 1),
              _row('出处', a.source.isEmpty ? '—' : a.source, b.source.isEmpty ? '—' : b.source),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text('高亮行为两件都有的同名属性但数值不同', style: TextStyle(fontSize: 11, color: AppColors.of(context).inkLight)),
        ),
      ],
    );
  }

  Widget _buildHeader(Equipment e) {
    final p = AppColors.of(context);
    final qc = AppColors.qualityColor(e.quality);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: InkWell(
                onTap: () => CompareService().remove(e.id),
                child: Icon(Icons.close, size: 18, color: p.inkLight),
              ),
            ),
            IconImage(icon: e.icon, size: 56, fallbackColor: qc, fallback: Icons.shield, radius: 10),
            const SizedBox(height: 8),
            Text(
              e.name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: qc),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String va, String vb, {bool highlight = false, Color? colorA, Color? colorB}) {
    final p = AppColors.of(context);
    return Container(
      color: highlight ? AppColors.primary.withOpacity(0.08) : null,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              va,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: colorA ?? (highlight ? AppColors.primary : p.ink),
                fontWeight: highlight ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          SizedBox(
            width: 64,
            child: Text(label, textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: p.inkLight)),
          ),
          Expanded(
            child: Text(
              vb,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: colorB ?? (highlight ? AppColors.primary : p.ink),
                fontWeight: highlight ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
