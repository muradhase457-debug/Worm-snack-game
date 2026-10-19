import 'package:shared_preferences/shared_preferences.dart';

class GameStorage {
  static const _coinsKey = 'worm_coins';
  static const _bestScoreKey = 'worm_best_score';
  static const _bestLengthKey = 'worm_best_length';
  static const _skinKey = 'worm_skin';
  static const _faceKey = 'worm_face';
  static const _unlockedSkinsKey = 'worm_unlocked_skins';
  static const _unlockedFacesKey = 'worm_unlocked_faces';
  static const _totalFoodsKey = 'worm_total_foods';
  static const _gamesPlayedKey = 'worm_games_played';
  static const _photoKey = 'worm_photo_path';
  static const _soundKey = 'worm_sound';

  static Future<int> getCoins() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_coinsKey) ?? 340;
  }

  static Future<void> setCoins(int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_coinsKey, value);
  }

  static Future<void> addCoins(int amount) async {
    final current = await getCoins();
    await setCoins(current + amount);
  }

  static Future<int> getBestScore() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_bestScoreKey) ?? 0;
  }

  static Future<void> setBestScore(int value) async {
    final prefs = await SharedPreferences.getInstance();
    final old = prefs.getInt(_bestScoreKey) ?? 0;
    if (value > old) await prefs.setInt(_bestScoreKey, value);
  }

  static Future<int> getBestLength() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_bestLengthKey) ?? 0;
  }

  static Future<void> setBestLength(int value) async {
    final prefs = await SharedPreferences.getInstance();
    final old = prefs.getInt(_bestLengthKey) ?? 0;
    if (value > old) await prefs.setInt(_bestLengthKey, value);
  }

  static Future<String> getSkin() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_skinKey) ?? 'white';
  }

  static Future<void> setSkin(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_skinKey, id);
  }

  static Future<String> getFace() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_faceKey) ?? 'happy';
  }

  static Future<void> setFace(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_faceKey, id);
  }

  static Future<List<String>> getUnlockedSkins() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_unlockedSkinsKey) ?? ['white', 'rainbow'];
  }

  static Future<void> setUnlockedSkins(List<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_unlockedSkinsKey, ids);
  }

  static Future<List<String>> getUnlockedFaces() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_unlockedFacesKey) ?? ['happy', 'love'];
  }

  static Future<void> setUnlockedFaces(List<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_unlockedFacesKey, ids);
  }

  static Future<int> getTotalFoods() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_totalFoodsKey) ?? 0;
  }

  static Future<void> addTotalFoods(int amount) async {
    final prefs = await SharedPreferences.getInstance();
    final cur = prefs.getInt(_totalFoodsKey) ?? 0;
    await prefs.setInt(_totalFoodsKey, cur + amount);
  }

  static Future<int> getGamesPlayed() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_gamesPlayedKey) ?? 0;
  }

  static Future<void> incrementGamesPlayed() async {
    final prefs = await SharedPreferences.getInstance();
    final cur = prefs.getInt(_gamesPlayedKey) ?? 0;
    await prefs.setInt(_gamesPlayedKey, cur + 1);
  }

  static Future<String?> getPhotoPath() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_photoKey);
  }

  static Future<void> setPhotoPath(String? value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value == null) {
      await prefs.remove(_photoKey);
    } else {
      await prefs.setString(_photoKey, value);
    }
  }

  static Future<bool> getSound() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_soundKey) ?? true;
  }

  static Future<void> setSound(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_soundKey, value);
  }
}
