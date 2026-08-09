import 'dart:convert';
import '../utils/prefs.dart';

/// 单条浏览记录
class HistoryEntry {
  final int articleId;
  final DateTime time;

  HistoryEntry({required this.articleId, required this.time});

  factory HistoryEntry.fromJson(Map<String, dynamic> j) => HistoryEntry(
        articleId: (j['article_id'] as num?)?.toInt() ?? 0,
        time: DateTime.tryParse(j['time']?.toString() ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0),
      );

  Map<String, dynamic> toJson() => {
        'article_id': articleId,
        'time': time.toIso8601String(),
      };
}

/// 浏览历史：攻略文章浏览记录（JSON 数组，最新在前，去重，上限 100 条）
class HistoryService {
  static final HistoryService _instance = HistoryService._internal();
  factory HistoryService() => _instance;
  HistoryService._internal();

  static const int maxCount = 100;

  List<HistoryEntry> _list = [];
  bool _loaded = false;

  List<HistoryEntry> get list => List.unmodifiable(_list);

  Future<void> load() async {
    if (_loaded) return;
    _loaded = true;
    await Prefs().init();
    final raw = Prefs().getString(Prefs.keyHistory);
    if (raw != null && raw.isNotEmpty) {
      try {
        _list = (jsonDecode(raw) as List)
            .map((e) => HistoryEntry.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (e) {
        print('load history error: $e');
      }
    }
  }

  /// 记录一次浏览（去重置顶，超出上限截断）
  Future<void> record(int articleId) async {
    await load();
    _list.removeWhere((e) => e.articleId == articleId);
    _list.insert(0, HistoryEntry(articleId: articleId, time: DateTime.now()));
    if (_list.length > maxCount) {
      _list = _list.sublist(0, maxCount);
    }
    await _save();
  }

  Future<void> clear() async {
    await load();
    _list = [];
    await _save();
  }

  Future<void> _save() async {
    await Prefs().setString(Prefs.keyHistory, jsonEncode(_list.map((e) => e.toJson()).toList()));
  }
}
