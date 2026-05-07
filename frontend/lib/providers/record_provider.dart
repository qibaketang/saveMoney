import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/expense_record.dart';
import '../services/api_client.dart';

class RecordProvider extends ChangeNotifier {
  static const _storageKeyBase = 'records';
  String _scope = 'guest';
  List<ExpenseRecord> _records = [];
  List<ExpenseRecord> get records => List.unmodifiable(_records);

  String get _storageKey => '$_storageKeyBase::$_scope';

  RecordProvider() {
    load();
  }

  void applyAuthContext({required String scope, required bool loggedIn}) {
    final normalizedScope = loggedIn ? scope : 'guest';
    if (_scope == normalizedScope) {
      return;
    }
    _scope = normalizedScope;
    if (!loggedIn) {
      _records = [];
      notifyListeners();
      return;
    }
    load();
  }

  Future<void> load() async {
    try {
      final data = await ApiClient.instance.get('/expenses');
      final items = (data['items'] as List? ?? const []);
      _records = items
          .whereType<Map<String, dynamic>>()
          .map(ExpenseRecord.fromApi)
          .toList();
      await _saveLocalCache();
    } catch (_) {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getStringList(_storageKey) ?? [];
      _records = raw.map((e) => ExpenseRecord.fromJson(jsonDecode(e))).toList();
    }
    notifyListeners();
  }

  Future<void> addRecord({
    required String category,
    required double amount,
    String note = '',
    List<String> tags = const [],
    DateTime? time,
    String? location,
  }) async {
    final draft = ExpenseRecord(
      id: '',
      category: category,
      amount: amount,
      note: note,
      tags: tags,
      time: time ?? DateTime.now(),
      location: location,
    );
    final data = await ApiClient.instance.post('/expenses', draft.toApiJson());
    final apiExpense = data['expense'] as Map<String, dynamic>;
    final record = ExpenseRecord.fromApi(apiExpense);
    _records.insert(0, record);
    await _saveLocalCache();
    notifyListeners();
  }

  Future<void> deleteRecord(String id) async {
    await ApiClient.instance.delete('/expenses/$id');
    _records.removeWhere((e) => e.id == id);
    await _saveLocalCache();
    notifyListeners();
  }

  Future<void> updateRecord({
    required String id,
    required String category,
    required double amount,
    String note = '',
    List<String> tags = const [],
    DateTime? time,
    String? location,
  }) async {
    final index = _records.indexWhere((e) => e.id == id);
    if (index < 0) {
      return;
    }

    final current = _records[index];
    final draft = ExpenseRecord(
      id: id,
      category: category,
      amount: amount,
      note: note,
      tags: tags,
      time: time ?? current.time,
      location: location ?? current.location,
      receiptPath: current.receiptPath,
    );

    final data =
        await ApiClient.instance.put('/expenses/$id', draft.toApiJson());
    final apiExpense = data['expense'];
    final updated = apiExpense is Map<String, dynamic>
        ? ExpenseRecord.fromApi(apiExpense)
        : draft;

    _records[index] = updated;
    await _saveLocalCache();
    notifyListeners();
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  double get todaySpent {
    final now = DateTime.now();
    return _records
        .where((e) => _isSameDay(e.time, now))
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  double spentForCategoriesOnDate(Set<String> categories, DateTime date) {
    if (categories.isEmpty) {
      return 0;
    }
    return _records
        .where(
            (e) => categories.contains(e.category) && _isSameDay(e.time, date))
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  double todaySpentForCategories(Set<String> categories) {
    return spentForCategoriesOnDate(categories, DateTime.now());
  }

  int get todayCount {
    final now = DateTime.now();
    return _records.where((e) => _isSameDay(e.time, now)).length;
  }

  int countForCategoriesOnDate(Set<String> categories, DateTime date) {
    if (categories.isEmpty) {
      return 0;
    }
    return _records
        .where(
            (e) => categories.contains(e.category) && _isSameDay(e.time, date))
        .length;
  }

  int todayCountForCategories(Set<String> categories) {
    return countForCategoriesOnDate(categories, DateTime.now());
  }

  List<ExpenseRecord> recordsForCategoryOnDate(String category, DateTime date) {
    final list = _records
        .where((e) => e.category == category && _isSameDay(e.time, date))
        .toList();
    list.sort((a, b) => b.time.compareTo(a.time));
    return list;
  }

  List<ExpenseRecord> recordsForCategoryInMonth(
      String category, DateTime month) {
    final list = _records
        .where((e) =>
            e.category == category &&
            e.time.year == month.year &&
            e.time.month == month.month)
        .toList();
    list.sort((a, b) => b.time.compareTo(a.time));
    return list;
  }

  double spentForCategoryToday(String category) {
    return spentForCategoryOnDate(category, DateTime.now());
  }

  double spentForCategoryOnDate(String category, DateTime date) {
    return _records
        .where((e) => e.category == category && _isSameDay(e.time, date))
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  double spentForCategoryMonth(String category, DateTime month) {
    return _records
        .where((e) =>
            e.category == category &&
            e.time.year == month.year &&
            e.time.month == month.month)
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  Map<String, double> categorySpendForMonth(DateTime date) {
    final map = <String, double>{};
    for (final record in _records
        .where((e) => e.time.year == date.year && e.time.month == date.month)) {
      map.update(record.category, (v) => v + record.amount,
          ifAbsent: () => record.amount);
    }
    return map;
  }

  List<double> dailySpendForMonth(DateTime date) {
    final days = DateUtils.getDaysInMonth(date.year, date.month);
    final result = List<double>.filled(days, 0);
    for (final record in _records
        .where((e) => e.time.year == date.year && e.time.month == date.month)) {
      result[record.time.day - 1] += record.amount;
    }
    return result;
  }

  Future<void> _saveLocalCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
        _storageKey, _records.map((e) => jsonEncode(e.toJson())).toList());
  }
}
