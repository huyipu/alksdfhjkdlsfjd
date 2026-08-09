import 'package:flutter/material.dart';
import '../services/data_service.dart';
import '../services/history_service.dart';
import '../services/track_service.dart';
import '../utils/theme.dart';
import 'article_detail_page.dart';

/// 浏览历史：攻略文章浏览记录（时间倒序）
class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    TrackService().fire('page_enter:history');
    Future.wait([DataService().load(), HistoryService().load()]).then((_) {
      if (mounted) setState(() => _loading = false);
    });
  }

  String _formatTime(DateTime t) {
    final now = DateTime.now();
    String two(int v) => v.toString().padLeft(2, '0');
    if (t.year == now.year && t.month == now.month && t.day == now.day) {
      return '${two(t.hour)}:${two(t.minute)}';
    }
    return '${two(t.month)}-${two(t.day)}';
  }

  Future<void> _confirmClear() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('清空浏览历史？'),
        content: const Text('清空后无法恢复。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('取消')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('确认清空')),
        ],
      ),
    );
    if (ok == true) {
      await HistoryService().clear();
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final entries = HistoryService().list;
    return Scaffold(
      appBar: AppBar(
        title: const Text('浏览历史'),
        actions: [
          if (entries.isNotEmpty)
            IconButton(
              tooltip: '清空',
              icon: const Icon(Icons.delete_outline),
              onPressed: _confirmClear,
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : entries.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history, size: 48, color: AppColors.of(context).inkLight),
                      SizedBox(height: 12),
                      Text('还没有浏览记录，去看几篇攻略吧', style: TextStyle(color: AppColors.of(context).inkLight)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: entries.length,
                  itemBuilder: (_, i) {
                    final entry = entries[i];
                    Article? article;
                    for (final a in DataService().articles) {
                      if (a.id == entry.articleId) {
                        article = a;
                        break;
                      }
                    }
                    if (article == null) return const SizedBox.shrink();
                    final a = article;
                    final catName = DataService.categories[a.category] ?? '综合';
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        title: Text(a.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.of(context).ink)),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text('$catName · ${_formatTime(entry.time)}',
                              style: TextStyle(fontSize: 12, color: AppColors.of(context).inkLight)),
                        ),
                        trailing: Icon(Icons.chevron_right, color: AppColors.of(context).inkLight),
                        onTap: () {
                          HistoryService().record(a.id).then((_) {
                            if (mounted) setState(() {});
                          });
                          Navigator.of(context).push(MaterialPageRoute(builder: (_) => ArticleDetailPage(article: a)));
                        },
                      ),
                    );
                  },
                ),
    );
  }
}
