import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists reader preferences and lightweight local reading continuity.
class AppStore extends ChangeNotifier {
  static const _kFavs = 'blin_favs_v1';
  static const _kScale = 'blin_scale_v1';
  static const _kNotes = 'blin_notes_v1';
  static const _kAppearance = 'blin_appearance_v1';
  static const _kRecent = 'blin_recent_v1';
  static const _kOffsets = 'blin_offsets_v1';
  static const _kMercyStage = 'blin_mercy_stage_v1';
  static const _kCompleted = 'blin_completed_v1';

  SharedPreferences? _prefs;
  Set<String> _favs = {};
  double _scale = 1.0;
  bool _showNotes = true;
  String _appearance = 'system';
  List<String> _recentIds = [];
  Map<String, double> _offsets = {};
  int _mercyStage = 0;
  Set<String> _completed = {};

  Set<String> get favs => _favs;
  double get scale => _scale;
  bool get showNotes => _showNotes;
  String get appearance => _appearance;
  List<String> get recentIds => List.unmodifiable(_recentIds);
  String? get lastItemId => _recentIds.isEmpty ? null : _recentIds.first;
  int get mercyStage => _mercyStage;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _favs = (_prefs!.getStringList(_kFavs) ?? []).toSet();
    _scale = _prefs!.getDouble(_kScale) ?? 1.0;
    _showNotes = _prefs!.getBool(_kNotes) ?? true;
    _appearance = _prefs!.getString(_kAppearance) ?? 'system';
    _recentIds = _prefs!.getStringList(_kRecent) ?? [];
    _mercyStage = (_prefs!.getInt(_kMercyStage) ?? 0).clamp(0, 3);
    _completed = (_prefs!.getStringList(_kCompleted) ?? []).toSet();
    final encodedOffsets = _prefs!.getString(_kOffsets);
    if (encodedOffsets != null) {
      try {
        final decoded = jsonDecode(encodedOffsets);
        if (decoded is Map) {
          _offsets = decoded.map((key, value) => MapEntry(
                key.toString(),
                value is num ? value.toDouble() : 0,
              ));
        }
      } on FormatException {
        _offsets = {};
      }
    }
    notifyListeners();
  }

  bool isFav(String id) => _favs.contains(id);

  bool toggleFav(String id) {
    final nowFav = !_favs.contains(id);
    if (nowFav) {
      _favs.add(id);
    } else {
      _favs.remove(id);
    }
    _prefs?.setStringList(_kFavs, _favs.toList());
    notifyListeners();
    return nowFav;
  }

  void setScale(double v) {
    _scale = v.clamp(0.8, 1.8);
    _prefs?.setDouble(_kScale, _scale);
    notifyListeners();
  }

  void bumpScale(double delta) => setScale(_scale + delta);

  void setShowNotes(bool v) {
    _showNotes = v;
    _prefs?.setBool(_kNotes, v);
    notifyListeners();
  }

  void setAppearance(String value) {
    if (!const {'system', 'parchment', 'night'}.contains(value)) return;
    _appearance = value;
    _prefs?.setString(_kAppearance, value);
    notifyListeners();
  }

  void recordOpened(String itemId) {
    _recentIds.remove(itemId);
    _recentIds.insert(0, itemId);
    if (_recentIds.length > 12) {
      _recentIds = _recentIds.take(12).toList();
    }
    _prefs?.setStringList(_kRecent, _recentIds);
    notifyListeners();
  }

  double readingOffset(String itemId) => _offsets[itemId] ?? 0;

  void setReadingOffset(String itemId, double offset) {
    if (!offset.isFinite || offset < 0) return;
    _offsets[itemId] = offset;
    _prefs?.setString(_kOffsets, jsonEncode(_offsets));
  }

  void resetReading(String itemId) {
    _offsets.remove(itemId);
    if (itemId == 'p_mercy') {
      _mercyStage = 0;
      _prefs?.setInt(_kMercyStage, 0);
    }
    _completed.remove(itemId);
    _prefs?.setString(_kOffsets, jsonEncode(_offsets));
    _prefs?.setStringList(_kCompleted, _completed.toList());
    notifyListeners();
  }

  void setMercyStage(int stage) {
    _mercyStage = stage.clamp(0, 3);
    _prefs?.setInt(_kMercyStage, _mercyStage);
  }

  bool isCompleted(String itemId) => _completed.contains(itemId);

  void markCompleted(String itemId) {
    _completed.add(itemId);
    _prefs?.setStringList(_kCompleted, _completed.toList());
    notifyListeners();
  }
}
