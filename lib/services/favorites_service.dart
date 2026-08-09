import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../utils/prefs.dart';

/// 装备收藏：本地存储收藏装备 id 列表（JSON string 列表，最新在前）
class FavoritesService extends ChangeNotifier {
  static final FavoritesService _instance = FavoritesService._internal();
  factory FavoritesService() => _instance;
  FavoritesService._internal();

  List<int> _ids = [];
  bool _loaded = false;

  List<int> get ids => List.unmodifiable(_ids);

  Future<void> load() async {
    if (_loaded) return;
    _loaded = true;
    await Prefs().init();
    final raw = Prefs().getString(Prefs.keyFavorites);
    if (raw != null && raw.isNotEmpty) {
      try {
        _ids = (jsonDecode(raw) as List).map((e) => (e as num).toInt()).toList();
      } catch (e) {
        print('load favorites error: $e');
      }
    }
  }

  bool isFavorite(int id) => _ids.contains(id);

  /// 切换收藏，返回切换后的收藏状态
  Future<bool> toggle(int id) async {
    await load();
    final nowFav = !_ids.contains(id);
    if (nowFav) {
      _ids.insert(0, id);
    } else {
      _ids.remove(id);
    }
    await Prefs().setString(Prefs.keyFavorites, jsonEncode(_ids));
    notifyListeners();
    return nowFav;
  }
}
