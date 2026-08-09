import 'package:flutter/material.dart';
import '../pages/compare_page.dart';
import '../services/collection_service.dart';
import '../services/compare_service.dart';
import '../services/data_service.dart';
import '../services/favorites_service.dart';
import '../utils/theme.dart';
import 'icon_image.dart';
import 'share_card.dart';

/// 装备详情底部弹层（图鉴页 / 收藏页共用，内含收藏按钮）
void showEquipmentDetail(BuildContext context, Equipment e) {
  final qc = AppColors.qualityColor(e.quality);
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.of(context).card,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (_) => DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      minChildSize: 0.4,
      expand: false,
      builder: (_, controller) => ListView(
        controller: controller,
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(2))),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              IconImage(icon: e.icon, size: 48, fallbackColor: qc, fallback: Icons.shield),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(e.name, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: qc)),
                    Text(
                        '${AppColors.qualityName(e.quality)} · ${e.level > 0 ? 'Lv.${e.level}' : '等级待定'}${e.slot.isNotEmpty ? ' · ${e.slot}' : ''}',
                        style: TextStyle(fontSize: 12, color: AppColors.of(context).inkLight)),
                  ],
                ),
              ),
              StatefulBuilder(
                builder: (sheetContext, setSheetState) {
                  final fav = FavoritesService().isFavorite(e.id);
                  return IconButton(
                    tooltip: fav ? '取消收藏' : '收藏',
                    icon: Icon(fav ? Icons.favorite : Icons.favorite_outline,
                        color: fav ? Colors.red : AppColors.of(context).inkLight),
                    onPressed: () async {
                      final nowFav = await FavoritesService().toggle(e.id);
                      setSheetState(() {});
                      if (sheetContext.mounted) {
                        ScaffoldMessenger.of(sheetContext).showSnackBar(SnackBar(
                          content: Text(nowFav ? '已收藏' : '已取消收藏'),
                          duration: const Duration(seconds: 1),
                        ));
                      }
                    },
                  );
                },
              ),
            ],
          ),
          if (e.set.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: AppColors.primaryLight.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
              child: Text('套装：${e.set}', style: const TextStyle(fontSize: 12, color: AppColors.primary)),
            ),
          ],
          const SizedBox(height: 12),
          StatefulBuilder(
            builder: (sheetContext, setSheetState) {
              final collected = CollectionService().isCollected(e.id);
              final inCompare = CompareService().contains(e.id);
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _SheetAction(
                    icon: collected ? Icons.check_circle : Icons.check_circle_outline,
                    label: collected ? '已拥有 ✓' : '标记已拥有',
                    active: collected,
                    onTap: () async {
                      final now = await CollectionService().toggle(e.id);
                      setSheetState(() {});
                      if (sheetContext.mounted) {
                        ScaffoldMessenger.of(sheetContext).showSnackBar(SnackBar(
                          content: Text(now ? '已标记为拥有' : '已取消拥有标记'),
                          duration: const Duration(seconds: 1),
                        ));
                      }
                    },
                  ),
                  _SheetAction(
                    icon: Icons.compare_arrows,
                    label: inCompare ? '已加入对比' : '加入对比',
                    active: inCompare,
                    onTap: () {
                      if (CompareService().contains(e.id)) {
                        ScaffoldMessenger.of(sheetContext).showSnackBar(const SnackBar(
                          content: Text('已在对比列表中'),
                          duration: Duration(seconds: 1),
                        ));
                        return;
                      }
                      if (CompareService().isFull) {
                        ScaffoldMessenger.of(sheetContext).showSnackBar(const SnackBar(
                          content: Text('对比最多选 2 件，请先在图鉴页清空'),
                          duration: Duration(seconds: 1),
                        ));
                        return;
                      }
                      final n = CompareService().add(e);
                      setSheetState(() {});
                      if (n >= 2) {
                        // 满 2 件：关弹层并跳转对比页
                        Navigator.of(sheetContext).pop();
                        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ComparePage()));
                      } else {
                        ScaffoldMessenger.of(sheetContext).showSnackBar(SnackBar(
                          content: Text('已加入对比（$n/2）'),
                          duration: const Duration(seconds: 1),
                        ));
                      }
                    },
                  ),
                  _SheetAction(
                    icon: Icons.share_outlined,
                    label: '分享',
                    onTap: () => ShareCards.shareEquipment(context, e),
                  ),
                ],
              );
            },
          ),
          const Divider(height: 32),
          if (e.attrs.isNotEmpty) ...[
            Text('属性', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.of(context).ink)),
            const SizedBox(height: 8),
            ...e.attrs.map((a) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text('· $a', style: TextStyle(fontSize: 14, color: AppColors.of(context).ink, height: 1.6)),
                )),
            const SizedBox(height: 16),
          ],
          if (e.source.isNotEmpty) ...[
            Text('出处', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.of(context).ink)),
            const SizedBox(height: 8),
            Text(e.source, style: TextStyle(fontSize: 14, color: AppColors.of(context).ink, height: 1.6)),
            const SizedBox(height: 16),
          ],
          if (e.desc.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.of(context).bg, borderRadius: BorderRadius.circular(10)),
              child: Text(e.desc, style: TextStyle(fontSize: 13, color: AppColors.of(context).inkLight, height: 1.7, fontStyle: FontStyle.italic)),
            ),
        ],
      ),
    ),
  );
}

/// 详情弹层内的小动作按钮（标记已拥有 / 加入对比 / 分享）
class _SheetAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _SheetAction({required this.icon, required this.label, required this.onTap, this.active = false});

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.primary : AppColors.of(context).inkLight;
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: active ? AppColors.primaryLight.withOpacity(0.15) : null,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(fontSize: 12, color: color, fontWeight: active ? FontWeight.bold : FontWeight.normal)),
          ],
        ),
      ),
    );
  }
}
