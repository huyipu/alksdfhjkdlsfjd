import 'package:flutter/material.dart';
import '../services/data_service.dart';
import '../services/history_service.dart';
import '../services/track_service.dart';
import '../utils/theme.dart';
import 'article_detail_page.dart';

/// 攻略：分类 Tab + 文章列表
class GuidesPage extends StatefulWidget {
  const GuidesPage({super.key});

  @override
  State<GuidesPage> createState() => _GuidesPageState();
}

class _GuidesPageState extends State<GuidesPage> with SingleTickerProviderStateMixin {
  late final TabController _tab;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: DataService.categories.length, vsync: this);
    DataService().load().then((_) {
      if (mounted) setState(() => _loading = false);
    });
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cats = DataService.categories.entries.toList();
    return Scaffold(
      appBar: AppBar(
        title: const Text('攻略'),
        bottom: TabBar(
          controller: _tab,
          isScrollable: true,
          tabs: cats.map((c) => Tab(text: c.value)).toList(),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tab,
              children: cats.map((c) => _buildList(c.key)).toList(),
            ),
    );
  }

  Widget _buildList(String category) {
    final list = DataService().articles.where((a) => a.category == category).toList();
    if (list.isEmpty) {
      return Center(child: Text('内容整理中，敬请期待', style: TextStyle(color: AppColors.of(context).inkLight)));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      itemBuilder: (_, i) {
        final a = list[i];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            title: Text(a.title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.of(context).ink)),
            subtitle: a.summary.isNotEmpty
                ? Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(a.summary, maxLines: 2, overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12, color: AppColors.of(context).inkLight)),
                  )
                : null,
            trailing: Icon(Icons.chevron_right, color: AppColors.of(context).inkLight),
            onTap: () {
              TrackService().fire('article_open');
              HistoryService().record(a.id);
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => ArticleDetailPage(article: a)));
            },
          ),
        );
      },
    );
  }
}
