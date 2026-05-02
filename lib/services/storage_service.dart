import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Coins
  int getCoins() => _prefs?.getInt('coins') ?? 0;
  Future<void> setCoins(int value) async => await _prefs?.setInt('coins', value);
  Future<void> addCoins(int value) async => await setCoins(getCoins() + value);

  // Gems
  int getGems() => _prefs?.getInt('gems') ?? 0;
  Future<void> setGems(int value) async => await _prefs?.setInt('gems', value);
  Future<void> addGems(int value) async => await setGems(getGems() + value);

  // High Score
  int getHighScore() => _prefs?.getInt('high_score') ?? 0;
  Future<void> setHighScore(int value) async {
    if (value > getHighScore()) {
      await _prefs?.setInt('high_score', value);
    }
  }

  // Total Score (for leaderboard progression)
  int getTotalScore() => _prefs?.getInt('total_score') ?? 0;
  Future<void> addTotalScore(int value) async => await _prefs?.setInt('total_score', getTotalScore() + value);

  // Games Played
  int getGamesPlayed() => _prefs?.getInt('games_played') ?? 0;
  Future<void> incrementGamesPlayed() async => await _prefs?.setInt('games_played', getGamesPlayed() + 1);

  // Last Daily Reward
  String? getLastDailyReward() => _prefs?.getString('last_daily_reward');
  Future<void> setLastDailyReward(String date) async => await _prefs?.setString('last_daily_reward', date);
  int getDailyStreak() => _prefs?.getInt('daily_streak') ?? 0;
  Future<void> setDailyStreak(int value) async => await _prefs?.setInt('daily_streak', value);

  // Sound Settings
  bool getSoundEnabled() => _prefs?.getBool('sound_enabled') ?? true;
  Future<void> setSoundEnabled(bool value) async => await _prefs?.setBool('sound_enabled', value);
  bool getMusicEnabled() => _prefs?.getBool('music_enabled') ?? true;
  Future<void> setMusicEnabled(bool value) async => await _prefs?.setBool('music_enabled', value);

  // Selected Character
  String getSelectedCharacter() => _prefs?.getString('selected_character') ?? 'default';
  Future<void> setSelectedCharacter(String value) async => await _prefs?.setString('selected_character', value);

  // Unlocked Characters
  List<String> getUnlockedCharacters() {
    final json = _prefs?.getString('unlocked_characters');
    if (json == null) return ['default'];
    return List<String>.from(jsonDecode(json));
  }
  Future<void> unlockCharacter(String character) async {
    final unlocked = getUnlockedCharacters();
    if (!unlocked.contains(character)) {
      unlocked.add(character);
      await _prefs?.setString('unlocked_characters', jsonEncode(unlocked));
    }
  }

  // Selected Hoverboard
  String getSelectedHoverboard() => _prefs?.getString('selected_hoverboard') ?? 'default';
  Future<void> setSelectedHoverboard(String value) async => await _prefs?.setString('selected_hoverboard', value);

  // Unlocked Hoverboards
  List<String> getUnlockedHoverboards() {
    final json = _prefs?.getString('unlocked_hoverboards');
    if (json == null) return ['default'];
    return List<String>.from(jsonDecode(json));
  }
  Future<void> unlockHoverboard(String board) async {
    final unlocked = getUnlockedHoverboards();
    if (!unlocked.contains(board)) {
      unlocked.add(board);
      await _prefs?.setString('unlocked_hoverboards', jsonEncode(unlocked));
    }
  }

  // Missions
  Map<String, dynamic> getMissions() {
    final json = _prefs?.getString('missions');
    if (json == null) return {};
    return jsonDecode(json);
  }
  Future<void> setMissions(Map<String, dynamic> missions) async {
    await _prefs?.setString('missions', jsonEncode(missions));
  }

  // Ad counters
  int getRunCount() => _prefs?.getInt('run_count') ?? 0;
  Future<void> incrementRunCount() async => await _prefs?.setInt('run_count', getRunCount() + 1);
  int getInterstitialCount() => _prefs?.getInt('interstitial_count') ?? 0;
  Future<void> incrementInterstitialCount() async => await _prefs?.setInt('interstitial_count', getInterstitialCount() + 1);

  // First launch
  bool getFirstLaunch() => _prefs?.getBool('first_launch') ?? true;
  Future<void> setFirstLaunch(bool value) async => await _prefs?.setBool('first_launch', value);

  // Tutorial completed
  bool getTutorialCompleted() => _prefs?.getBool('tutorial_completed') ?? false;
  Future<void> setTutorialCompleted(bool value) async => await _prefs?.setBool('tutorial_completed', value);
}
