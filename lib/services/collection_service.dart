import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../utils/prefs.dart';

/// 套装收集：本地存储"已拥有"装备 id 集合（模式同 FavoritesService）
class CollectionService extends ChangeNotifier {
  static final CollectionService _instance = CollectionService._internal();
  factory CollectionService() => _instance;
  CollectionService._internal();

  Set<int> _ids = {};
  bool _loaded = false;

  Set<int> get ids => Set.unmodifiable(_ids);

  Future<void> load() async {
    if (_loaded) return;
    _loaded = true;
    await Prefs().init();
    final raw = Prefs().getString(Prefs.keyCollected);
    if (raw != null && raw.isNotEmpty) {
      try {
        _ids = (jsonDecode(raw) as List).map((e) => (e as num).toInt()).toSet();
      } catch (e) {
        print('load collected error: $e');
      }
    }
  }

  bool isCollected(int id) => _ids.contains(id);

  /// 切换"已拥有"，返回切换后的状态
  Future<bool> toggle(int id) async {
    await load();
    final nowCollected = !_ids.contains(id);
    if (nowCollected) {
      _ids.add(id);
    } else {
      _ids.remove(id);
    }
    await Prefs().setString(Prefs.keyCollected, jsonEncode(_ids.toList()));
    notifyListeners();
    return nowCollected;
  }
}
