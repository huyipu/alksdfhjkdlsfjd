import 'package:flutter/material.dart';
import '../services/collection_service.dart';
import '../services/data_service.dart';
import '../services/track_service.dart';
import '../utils/theme.dart';
import '../widgets/icon_image.dart';
import '../widgets/share_card.dart';

/// 套装收集：总进度 + 按套装分组的收集进度列表
class CollectionPage extends StatefulWidget {
  const CollectionPage({super.key});

  @override
  State<CollectionPage> createState() => _CollectionPageState();
}

class _CollectionPageState extends State<CollectionPage> {
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    TrackService().fire('page_enter:collection');
    CollectionService().addListener(_onChanged);
    Future.wait([DataService().load(), CollectionService().load()]).then((_) {
      if (mounted) setState(() => _loading = false);
    });
  }

  @override
  void dispose() {
    CollectionService().removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  Map<String, List<Equipment>> get _sets {
    final map = <String, List<Equipment>>{};
    for (final e in DataService().equipment) {
      if (e.set.isEmpty) continue;
      map.putIfAbsent(e.set, () => []).add(e);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final all = DataService().equipment;
    final ids = CollectionService().ids;
    final owned = all.where((e) => ids.contains(e.id)).length;
    final sets = _sets.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
    return Scaffold(
      appBar: AppBar(title: const Text('套装收集')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildTotalCard(owned, all.length),
                const SizedBox(height: 8),
                if (sets.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(32),
                    child: Center(child: Text('套装数据整理中', style: TextStyle(color: AppColors.of(context).inkLight))),
                  )
                else
                  ...sets.map((s) => _buildSetRow(s.key, s.value)),
              ],
            ),
    );
  }

  Widget _buildTotalCard(int owned, int total) {
    final p = AppColors.of(context);
    final progress = total == 0 ? 0.0 : owned / total;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.checklist, color: AppColors.primary),
                const SizedBox(width: 8),
                Text('收集总进度', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: p.ink)),
                const Spacer(),
                Text('$owned / $total', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.primary)),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: p.bg,
                valueColor: const AlwaysStoppedAnimation(AppColors.primary),
              ),
            ),
            const SizedBox(height: 8),
            Text('已拥有 ${(progress * 100).toStringAsFixed(0)}% 的图鉴装备，点套装可逐件标记「已拥有」',
                style: TextStyle(fontSize: 11, color: p.inkLight)),
          ],
        ),
      ),
    );
  }

  Widget _buildSetRow(String setName, List<Equipment> items) {
    final p = AppColors.of(context);
    final owned = items.where((e) => CollectionService().isCollected(e.id)).length;
    final full = items.isNotEmpty && owned == items.length;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => _SetDetailPage(setName: setName, items: items))),
        title: Row(
          children: [
            Expanded(child: Text(setName, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: p.ink))),
            if (full) const Icon(Icons.emoji_events, size: 16, color: AppColors.primary),
            const SizedBox(width: 4),
            Text('$owned/${items.length}',
                style: TextStyle(fontSize: 12, color: full ? AppColors.primary : p.inkLight, fontWeight: full ? FontWeight.bold : FontWeight.normal)),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: items.isEmpty ? 0 : owned / items.length,
              minHeight: 5,
              backgroundColor: p.bg,
              valueColor: AlwaysStoppedAnimation(full ? AppColors.qOrange : AppColors.primary),
            ),
          ),
        ),
        trailing: Icon(Icons.chevron_right, color: p.inkLight),
      ),
    );
  }
}

/// 套装详情：该套装全部单件网格，点击切换"已拥有"
class _SetDetailPage extends StatefulWidget {
  final String setName;
  final List<Equipment> items;

  const _SetDetailPage({required this.setName, required this.items});

  @override
  State<_SetDetailPage> createState() => _SetDetailPageState();
}

class _SetDetailPageState extends State<_SetDetailPage> {
  @override
  void initState() {
    super.initState();
    CollectionService().addListener(_onChanged);
  }

  @override
  void dispose() {
    CollectionService().removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final p = AppColors.of(context);
    final items = widget.items;
    final owned = items.where((e) => CollectionService().isCollected(e.id)).length;
    final full = items.isNotEmpty && owned == items.length;
    return Scaffold(
      appBar: AppBar(title: Text(widget.setName)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Column(
              children: [
                Row(
                  children: [
                    Text('已拥有 $owned/${items.length} 件', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: p.ink)),
                    const Spacer(),
                    if (full)
                      FilledButton.icon(
                        icon: const Icon(Icons.share_outlined, size: 18),
                        label: const Text('分享成就'),
                        onPressed: () => ShareCards.shareAchievement(context: context, setName: widget.setName, collected: owned, total: items.length),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: items.isEmpty ? 0 : owned / items.length,
                    minHeight: 8,
                    backgroundColor: p.card,
                    valueColor: AlwaysStoppedAnimation(full ? AppColors.qOrange : AppColors.primary),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 0.78,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: items.length,
              itemBuilder: (_, i) => _buildItem(items[i]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItem(Equipment e) {
    final p = AppColors.of(context);
    final owned = CollectionService().isCollected(e.id);
    final qc = AppColors.qualityColor(e.quality);
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => CollectionService().toggle(e.id),
      child: Opacity(
        opacity: owned ? 1 : 0.45,
        child: Container(
          decoration: BoxDecoration(
            color: p.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: owned ? qc.withOpacity(0.8) : p.inkLight.withOpacity(0.3), width: 1.5),
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
                owned ? '已拥有 ✓' : '点击标记拥有',
                style: TextStyle(fontSize: 10, color: owned ? AppColors.qGreen : p.inkLight),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
