import 'package:flutter/material.dart';
import '../services/data_service.dart';
import '../services/favorites_service.dart';
import '../services/track_service.dart';
import '../utils/theme.dart';
import '../widgets/equipment_detail_sheet.dart';

/// 我的收藏：收藏的装备网格（复用图鉴卡片样式）
class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    TrackService().fire('page_enter:favorites');
    FavoritesService().addListener(_onChanged);
    Future.wait([DataService().load(), FavoritesService().load()]).then((_) {
      if (mounted) setState(() => _loading = false);
    });
  }

  @override
  void dispose() {
    FavoritesService().removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  List<Equipment> get _favorites {
    final ids = FavoritesService().ids.toSet();
    return DataService().equipment.where((e) => ids.contains(e.id)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final list = _favorites;
    return Scaffold(
      appBar: AppBar(title: const Text('我的收藏')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : list.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.favorite_outline, size: 48, color: AppColors.of(context).inkLight),
                      const SizedBox(height: 12),
                      Text('还没有收藏，去图鉴看看', style: TextStyle(color: AppColors.of(context).inkLight)),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('去图鉴看看'),
                      ),
                    ],
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 0.82,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: list.length,
                  itemBuilder: (_, i) => _buildCard(list[i]),
                ),
    );
  }

  Widget _buildCard(Equipment e) {
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
            Icon(Icons.shield_outlined, size: 32, color: qc),
            const SizedBox(height: 8),
            Text(
              e.name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: qc),
            ),
            const SizedBox(height: 4),
            Text('Lv.${e.level} ${e.slot}', style: TextStyle(fontSize: 10, color: AppColors.of(context).inkLight)),
          ],
        ),
      ),
    );
  }
}
