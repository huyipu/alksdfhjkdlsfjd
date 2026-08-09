import 'package:flutter/foundation.dart';
import 'data_service.dart';

/// 装备对比选择状态：内存态单例，最多 2 件
class CompareService extends ChangeNotifier {
  static final CompareService _instance = CompareService._internal();
  factory CompareService() => _instance;
  CompareService._internal();

  final List<Equipment> _items = [];

  List<Equipment> get items => List.unmodifiable(_items);
  bool get isFull => _items.length >= 2;

  bool contains(int id) => _items.any((e) => e.id == id);

  /// 加入对比，返回加入后的数量；已在列表中返回当前数量；已满返回 -1
  int add(Equipment e) {
    if (contains(e.id)) return _items.length;
    if (isFull) return -1;
    _items.add(e);
    notifyListeners();
    return _items.length;
  }

  void remove(int id) {
    _items.removeWhere((e) => e.id == id);
    notifyListeners();
  }

  void clear() {
    if (_items.isEmpty) return;
    _items.clear();
    notifyListeners();
  }
}
