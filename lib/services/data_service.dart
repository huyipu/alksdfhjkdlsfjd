import 'dart:convert';
import 'package:flutter/services.dart';

/// 装备图鉴条目
class Equipment {
  final int id;
  final String name;
  final String slot; // 部位：武器/帽子/衣服/护腕/鞋子/项链/戒指/护符/腰带
  final int level;
  final String quality; // green/blue/purple/orange
  final String set; // 套装名（散件为空）
  final List<String> attrs;
  final String source; // 出处
  final String desc;
  final String icon; // 图标 assets 相对路径（空则显示默认图标）

  Equipment({
    required this.id,
    required this.name,
    required this.slot,
    required this.level,
    required this.quality,
    this.set = '',
    this.attrs = const [],
    this.source = '',
    this.desc = '',
    this.icon = '',
  });

  factory Equipment.fromJson(Map<String, dynamic> j) => Equipment(
        id: j['id'] ?? 0,
        name: j['name'] ?? '',
        slot: j['slot'] ?? '',
        level: j['level'] ?? 0,
        quality: j['quality'] ?? '',
        set: j['set'] ?? '',
        attrs: (j['attrs'] as List?)?.map((e) => e.toString()).toList() ?? [],
        source: j['source'] ?? '',
        desc: j['desc'] ?? '',
        icon: j['icon'] ?? '',
      );
}

/// 坐骑图鉴条目
class Beast {
  final int id;
  final String name;
  final String school; // 门派
  final String icon;
  final String source; // 出处/获取方式
  final String desc;

  Beast({required this.id, required this.name, this.school = '', this.icon = '', this.source = '', this.desc = ''});

  factory Beast.fromJson(Map<String, dynamic> j) => Beast(
        id: j['id'] ?? 0,
        name: j['name'] ?? '',
        school: j['school'] ?? '',
        icon: j['icon'] ?? '',
        source: j['source'] ?? '',
        desc: j['desc'] ?? '',
      );
}

/// 宝石图鉴条目
class Gem {
  final int id;
  final String name;
  final String icon;
  final String attr; // 属性加成说明
  final String desc;

  Gem({required this.id, required this.name, this.icon = '', this.attr = '', this.desc = ''});

  factory Gem.fromJson(Map<String, dynamic> j) => Gem(
        id: j['id'] ?? 0,
        name: j['name'] ?? '',
        icon: j['icon'] ?? '',
        attr: j['attr'] ?? '',
        desc: j['desc'] ?? '',
      );
}

/// 经典道具条目
class Item {
  final int id;
  final String name;
  final String icon;
  final String desc;

  Item({required this.id, required this.name, this.icon = '', this.desc = ''});

  factory Item.fromJson(Map<String, dynamic> j) => Item(
        id: j['id'] ?? 0,
        name: j['name'] ?? '',
        icon: j['icon'] ?? '',
        desc: j['desc'] ?? '',
      );
}

/// 攻略文章
class Article {
  final int id;
  final String category; // paoshang/fuben/menpai/zhenshou/other
  final String title;
  final String summary;
  final String content; // markdown
  final String updated;

  Article({
    required this.id,
    required this.category,
    required this.title,
    this.summary = '',
    this.content = '',
    this.updated = '',
  });

  factory Article.fromJson(Map<String, dynamic> j) => Article(
        id: j['id'] ?? 0,
        category: j['category'] ?? 'other',
        title: j['title'] ?? '',
        summary: j['summary'] ?? '',
        content: j['content'] ?? '',
        updated: j['updated'] ?? '',
      );
}

/// 跑商商线
class MerchantRoute {
  final String name;
  final int minLevel;
  final List<MerchantGood> goods;
  final String note;

  MerchantRoute({required this.name, required this.minLevel, this.goods = const [], this.note = ''});

  factory MerchantRoute.fromJson(Map<String, dynamic> j) => MerchantRoute(
        name: j['name'] ?? '',
        minLevel: j['minLevel'] ?? 0,
        goods: (j['goods'] as List?)?.map((e) => MerchantGood.fromJson(e)).toList() ?? [],
        note: j['note'] ?? '',
      );
}

class MerchantGood {
  final String name;
  final double buyPrice; // 买入价（银两；数据可能带小数，如 0.8）
  final double sellPrice; // 卖出价（银两）
  final String note;

  MerchantGood({required this.name, required this.buyPrice, required this.sellPrice, this.note = ''});

  factory MerchantGood.fromJson(Map<String, dynamic> j) => MerchantGood(
        name: j['name'] ?? '',
        buyPrice: (j['buyPrice'] as num?)?.toDouble() ?? 0,
        sellPrice: (j['sellPrice'] as num?)?.toDouble() ?? 0,
        note: j['note'] ?? '',
      );

  double get profit => sellPrice - buyPrice;
}

/// 每日回忆数据（assets/data/memories.json）
/// 用法：home 页按今天 MM-DD 查 events（历史上的今天）；没有则用
/// (dayOfYear % pool.length) 从 pool 轮转取一条，保证 365 天都有内容。
class MemoryData {
  final Map<String, String> events; // 键 "MM-DD" -> 当日大事件文案
  final List<String> pool; // 无固定日期的怀旧小事池

  MemoryData({this.events = const {}, this.pool = const []});

  factory MemoryData.fromJson(Map<String, dynamic> j) => MemoryData(
        events: (j['events'] as Map?)?.map((k, v) => MapEntry(k.toString(), v.toString())) ?? {},
        pool: (j['pool'] as List?)?.map((e) => e.toString()).toList() ?? [],
      );
}

/// 版本编年史条目（assets/data/chronicle.json，按时间升序）
class ChronicleEntry {
  final int year;
  final String date; // 如 "2007.05"
  final String title;
  final String desc;

  ChronicleEntry({required this.year, this.date = '', this.title = '', this.desc = ''});

  factory ChronicleEntry.fromJson(Map<String, dynamic> j) => ChronicleEntry(
        year: j['year'] ?? 0,
        date: j['date'] ?? '',
        title: j['title'] ?? '',
        desc: j['desc'] ?? '',
      );
}

/// 全站搜索结果（轻量容器，按类别分组）
class SearchResults {
  final List<Equipment> equipment;
  final List<Beast> beasts;
  final List<Gem> gems;
  final List<Item> items;
  final List<Article> articles;

  SearchResults({
    this.equipment = const [],
    this.beasts = const [],
    this.gems = const [],
    this.items = const [],
    this.articles = const [],
  });

  bool get isEmpty =>
      equipment.isEmpty && beasts.isEmpty && gems.isEmpty && items.isEmpty && articles.isEmpty;
}

/// 本地数据仓库：图鉴/攻略/跑商数据离线打包，启动时一次性加载
class DataService {
  static final DataService _instance = DataService._internal();
  factory DataService() => _instance;
  DataService._internal();

  List<Equipment> equipment = [];
  List<Beast> beasts = [];
  List<Gem> gems = [];
  List<Item> items = [];
  List<Article> articles = [];
  List<MerchantRoute> merchantRoutes = [];
  List<String> merchantTips = [];
  MemoryData? memories;
  List<ChronicleEntry> chronicle = [];

  /// 缓存加载中的 Future 而非布尔值：多个页面几乎同时调用 load() 时，
  /// 都等待同一个真实加载完成（否则后到者拿到未完成状态，列表永远空白）
  Future<void>? _loadingFuture;

  Future<void> load() {
    return _loadingFuture ??= _doLoad();
  }

  Future<void> _doLoad() async {
    try {
      final eqRaw = await rootBundle.loadString('assets/data/equipment.json');
      equipment = (jsonDecode(eqRaw) as List).map((e) => Equipment.fromJson(e)).toList();
    } catch (e) {
      print('load equipment.json error: $e');
    }
    try {
      final bRaw = await rootBundle.loadString('assets/data/beasts.json');
      beasts = (jsonDecode(bRaw) as List).map((e) => Beast.fromJson(e)).toList();
    } catch (e) {
      print('load beasts.json error: $e');
    }
    try {
      final gRaw = await rootBundle.loadString('assets/data/gems.json');
      gems = (jsonDecode(gRaw) as List).map((e) => Gem.fromJson(e)).toList();
    } catch (e) {
      print('load gems.json error: $e');
    }
    try {
      final iRaw = await rootBundle.loadString('assets/data/items.json');
      items = (jsonDecode(iRaw) as List).map((e) => Item.fromJson(e)).toList();
    } catch (e) {
      print('load items.json error: $e');
    }
    try {
      final arRaw = await rootBundle.loadString('assets/data/articles.json');
      articles = (jsonDecode(arRaw) as List).map((e) => Article.fromJson(e)).toList();
    } catch (e) {
      print('load articles.json error: $e');
    }
    try {
      final mcRaw = await rootBundle.loadString('assets/data/merchant.json');
      final mc = jsonDecode(mcRaw);
      merchantRoutes = (mc['routes'] as List?)?.map((e) => MerchantRoute.fromJson(e)).toList() ?? [];
      merchantTips = (mc['tips'] as List?)?.map((e) => e.toString()).toList() ?? [];
    } catch (e) {
      print('load merchant.json error: $e');
    }
    try {
      final meRaw = await rootBundle.loadString('assets/data/memories.json');
      memories = MemoryData.fromJson(jsonDecode(meRaw));
    } catch (e) {
      print('load memories.json error: $e');
    }
    try {
      final chRaw = await rootBundle.loadString('assets/data/chronicle.json');
      chronicle = (jsonDecode(chRaw) as List).map((e) => ChronicleEntry.fromJson(e)).toList();
    } catch (e) {
      print('load chronicle.json error: $e');
    }
  }

  /// 每日回忆：先按今天 MM-DD 查 events（历史上的今天），
  /// 没有则按 (dayOfYear % pool.length) 从 pool 轮转取一条
  String memoryOf(DateTime now) {
    final m = memories;
    if (m == null) return '';
    final key = '${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final hit = m.events[key];
    if (hit != null && hit.isNotEmpty) return hit;
    if (m.pool.isEmpty) return '';
    final dayOfYear = now.difference(DateTime(now.year)).inDays + 1;
    return m.pool[dayOfYear % m.pool.length];
  }

  /// 全站检索：名称/标题包含关键词（不区分大小写），文章再匹配 summary，
  /// 装备顺带匹配套装名。内存遍历，空关键词返回空结果。
  SearchResults search(String keyword) {
    final k = keyword.trim().toLowerCase();
    if (k.isEmpty) return SearchResults();
    bool hit(String s) => s.toLowerCase().contains(k);
    return SearchResults(
      equipment: equipment.where((e) => hit(e.name) || hit(e.set)).toList(),
      beasts: beasts.where((b) => hit(b.name)).toList(),
      gems: gems.where((g) => hit(g.name)).toList(),
      items: items.where((i) => hit(i.name)).toList(),
      articles: articles.where((a) => hit(a.title) || hit(a.summary)).toList(),
    );
  }

  static const categories = {
    'paoshang': '跑商',
    'fuben': '副本',
    'menpai': '门派',
    'zhenshou': '珍兽',
    'other': '综合',
  };
}
