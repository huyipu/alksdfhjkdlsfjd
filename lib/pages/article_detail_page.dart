import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../services/data_service.dart';
import '../services/history_service.dart';
import '../utils/theme.dart';

/// 攻略文章详情：markdown 渲染 + 相关攻略推荐
class ArticleDetailPage extends StatelessWidget {
  final Article article;
  const ArticleDetailPage({super.key, required this.article});

  @override
  Widget build(BuildContext context) {
    final related = DataService()
        .articles
        .where((a) => a.category == article.category && a.id != article.id)
        .take(3)
        .toList();
    final catName = DataService.categories[article.category] ?? '综合';

    return Scaffold(
      appBar: AppBar(title: Text(catName)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(article.title, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.of(context).ink, height: 1.4)),
          const SizedBox(height: 8),
          Text(article.updated, style: TextStyle(fontSize: 12, color: AppColors.of(context).inkLight)),
          const Divider(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: MarkdownBody(
                data: article.content,
                styleSheet: MarkdownStyleSheet(
                  p: TextStyle(fontSize: 14, height: 1.8, color: AppColors.of(context).ink),
                  h2: const TextStyle(fontSize: 16, height: 2.2, fontWeight: FontWeight.bold, color: AppColors.primary),
                  h3: TextStyle(fontSize: 15, height: 2.0, fontWeight: FontWeight.bold, color: AppColors.of(context).ink),
                  listBullet: TextStyle(fontSize: 14, height: 1.8, color: AppColors.of(context).ink),
                  strong: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.accent),
                ),
              ),
            ),
          ),
          if (related.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text('相关攻略', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.of(context).ink)),
            const SizedBox(height: 8),
            ...related.map((a) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    dense: true,
                    title: Text(a.title, style: TextStyle(fontSize: 13, color: AppColors.of(context).ink)),
                    trailing: Icon(Icons.chevron_right, size: 18, color: AppColors.of(context).inkLight),
                    onTap: () {
                      HistoryService().record(a.id);
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => ArticleDetailPage(article: a)),
                      );
                    },
                  ),
                )),
          ],
        ],
      ),
    );
  }
}
