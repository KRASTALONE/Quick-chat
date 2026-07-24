import 'package:shared_preferences/shared_preferences.dart';

class SearchHistoryService {
  static const String _historyKey = 'recent_username_searches';
  static const int _maxItems = 8;

  Future<List<String>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_historyKey) ?? <String>[];
  }

  Future<void> addHistoryItem(String username) async {
    final trimmed = username.trim();
    if (trimmed.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getStringList(_historyKey) ?? <String>[];

    current.remove(trimmed);
    current.insert(0, trimmed);

    if (current.length > _maxItems) {
      current.removeRange(_maxItems, current.length);
    }

    await prefs.setStringList(_historyKey, current);
  }

  Future<void> removeHistoryItem(String username) async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getStringList(_historyKey) ?? <String>[];
    current.remove(username);
    await prefs.setStringList(_historyKey, current);
  }

  Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_historyKey);
  }
}
