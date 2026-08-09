import 'package:flutter/material.dart';
import '../services/data_service.dart';
import '../services/history_service.dart';
import '../services/track_service.dart';
import '../utils/theme.dart';
import 'article_detail_page.dart';
import 'chronicle_page.dart';
import 'search_page.dart';

/// 首页：情怀横幅 + 每日回忆 + 内容流（攻略/怀旧混排，无广告）
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _loading = true;
  String _egg = ''; // 下拉刷新彩蛋文案

  static const _eggTexts = ['正在跑商路上…', '洛阳城的雪还在下…', '雁南的茶快凉了…', '帮战的号角又响了…'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await DataService().load();
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _refresh() async {
    setState(() => _egg = (_eggTexts..shuffle()).first);
    await Future.delayed(const Duration(milliseconds: 900));
    if (mounted) setState(() => _egg = '');
  }

  @override
  Widget build(BuildContext context) {
    final articles = DataService().articles;
    return Scaffold(
      appBar: AppBar(
        title: const Text('天龙亿旧',
            style: TextStyle(fontFamilyFallback: ['STKaiti', 'KaiTi', 'SimSun'], fontWeight: FontWeight.bold)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                '${DateTime.now().month}月${DateTime.now().day}日',
                style: TextStyle(color: AppColors.of(context).inkLight, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildSearchBar(),
            const SizedBox(height: 12),
            _buildBanner(),
            if (_egg.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Center(child: Text(_egg, style: const TextStyle(color: AppColors.primary, fontSize: 13))),
              ),
            const SizedBox(height: 16),
            if (DataService().memoryOf(DateTime.now()).isNotEmpty) ...[
              _buildMemoryCard(),
              const SizedBox(height: 16),
            ],
            _buildChronicleCard(),
            const SizedBox(height: 16),
            Text('攻略与回忆', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.of(context).ink)),
            const SizedBox(height: 8),
            if (_loading)
              const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()))
            else if (articles.isEmpty)
              Card(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: Text('内容整理中，敬请期待', style: TextStyle(color: AppColors.of(context).inkLight))),
                ),
              )
            else
              ...articles.map(_buildArticleCard),
          ],
        ),
      ),
    );
  }

  /// 搜索入口栏：仿搜索框，点击跳全站搜索页
  Widget _buildSearchBar() {
    return Material(
      color: AppColors.of(context).card,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SearchPage())),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Icon(Icons.search, size: 20, color: AppColors.of(context).inkLight),
              const SizedBox(width: 8),
              Text('搜索装备 / 攻略 / 宝石…', style: TextStyle(fontSize: 14, color: AppColors.of(context).inkLight)),
            ],
          ),
        ),
      ),
    );
  }

  /// 版本编年史横幅卡
  Widget _buildChronicleCard() {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ChroniclePage())),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.timeline, color: AppColors.accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('版本编年史', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.of(context).ink)),
                    const SizedBox(height: 4),
                    Text(
                      '2007-2020，你的青春在这里',
                      style: TextStyle(fontSize: 13, color: AppColors.of(context).inkLight, height: 1.5),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: AppColors.of(context).inkLight),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBanner() {
    return Container(
      height: 140,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF3A3A4A), Color(0xFF1F1F2B)],
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text('回到 2007',
              style: TextStyle(
                fontSize: 26,
                color: Color(0xFFE8D9B0),
                fontWeight: FontWeight.bold,
                fontFamilyFallback: ['STKaiti', 'KaiTi', 'SimSun'],
                letterSpacing: 4,
              )),
          SizedBox(height: 6),
          Text('洛阳的雪、雁南的茶、帮战的号角，都还在这里', style: TextStyle(color: Colors.white70, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildMemoryCard() {
    final memory = DataService().memoryOf(DateTime.now());
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primaryLight.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.history, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('每日回忆', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.of(context).ink)),
                  const SizedBox(height: 4),
                  Text(
                    memory,
                    style: TextStyle(fontSize: 13, color: AppColors.of(context).inkLight, height: 1.5),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArticleCard(Article a) {
    final catName = DataService.categories[a.category] ?? '综合';
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          TrackService().fire('article_open');
          HistoryService().record(a.id);
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => ArticleDetailPage(article: a)));
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(catName, style: const TextStyle(fontSize: 11, color: AppColors.primary)),
                  ),
                  const Spacer(),
                  Text(a.updated, style: TextStyle(fontSize: 11, color: AppColors.of(context).inkLight)),
                ],
              ),
              const SizedBox(height: 8),
              Text(a.title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.of(context).ink)),
              if (a.summary.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(a.summary,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 13, color: AppColors.of(context).inkLight, height: 1.5)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
