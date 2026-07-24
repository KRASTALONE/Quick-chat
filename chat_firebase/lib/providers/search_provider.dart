import 'dart:async';

import 'package:chatappui/data/models/user_model.dart';
import 'package:chatappui/data/services/search_history_service.dart';
import 'package:chatappui/data/services/user_service.dart';
import 'package:flutter/material.dart';

class SearchProvider extends ChangeNotifier {
  final UserService _userService = UserService();
  final SearchHistoryService _historyService = SearchHistoryService();

  Timer? _debounce;
  List<UserModel> _results = <UserModel>[];
  List<String> _history = <String>[];
  bool _isSearching = false;
  String _query = '';
  int _searchVersion = 0;
  bool _isInitialized = false;

  List<UserModel> get results => _results;
  List<String> get history => _history;
  bool get isSearching => _isSearching;
  String get query => _query;

  Future<void> initialize() async {
    if (_isInitialized) return;
    _isInitialized = true;
    await loadHistory();
  }

  Future<void> loadHistory() async {
    _history = await _historyService.getHistory();
    notifyListeners();
  }

  // Debounce keeps search smooth and avoids a Firestore request per keystroke.
  void onQueryChanged(String value) {
    _query = value;
    _debounce?.cancel();

    if (value.trim().isEmpty) {
      _isSearching = false;
      _results = <UserModel>[];
      notifyListeners();
      return;
    }

    notifyListeners();
    _debounce = Timer(
      const Duration(milliseconds: 300),
      () => searchUsers(value),
    );
  }

  Future<void> searchUsers(String query, {bool saveHistory = false}) async {
    final trimmed = query.trim();
    _query = query;

    if (trimmed.isEmpty) {
      _isSearching = false;
      _results = <UserModel>[];
      notifyListeners();
      return;
    }

    final requestId = ++_searchVersion;
    _isSearching = true;
    notifyListeners();

    final results = await _userService.searchByUsername(trimmed);
    if (requestId != _searchVersion) return;

    _results = results;
    _isSearching = false;
    notifyListeners();

    if (saveHistory) {
      await saveHistoryItem(trimmed);
    }
  }

  Future<void> selectHistoryItem(String username) async {
    _query = username;
    notifyListeners();
    await searchUsers(username, saveHistory: true);
  }

  Future<void> saveHistoryItem(String username) async {
    await _historyService.addHistoryItem(username);
    await loadHistory();
  }

  Future<void> deleteHistoryItem(String username) async {
    await _historyService.removeHistoryItem(username);
    await loadHistory();
  }

  Future<void> clearHistory() async {
    await _historyService.clearHistory();
    await loadHistory();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}
