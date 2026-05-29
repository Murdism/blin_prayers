import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists favorites, reading text scale, and the "show English notes" toggle.
class AppStore extends ChangeNotifier {
  static const _kFavs = 'blin_favs_v1';
  static const _kScale = 'blin_scale_v1';
  static const _kNotes = 'blin_notes_v1';

  SharedPreferences? _prefs;
  Set<String> _favs = {};
  double _scale = 1.0;
  bool _showNotes = true;

  Set<String> get favs => _favs;
  double get scale => _scale;
  bool get showNotes => _showNotes;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _favs = (_prefs!.getStringList(_kFavs) ?? []).toSet();
    _scale = _prefs!.getDouble(_kScale) ?? 1.0;
    _showNotes = _prefs!.getBool(_kNotes) ?? true;
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
}
