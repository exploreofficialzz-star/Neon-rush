import 'package:audioplayers/audioplayers.dart';
import 'storage_service.dart';

class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  final AudioPlayer _musicPlayer = AudioPlayer();
  final AudioPlayer _sfxPlayer = AudioPlayer();
  final StorageService _storage = StorageService();

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    await _musicPlayer.setReleaseMode(ReleaseMode.loop);
    _initialized = true;
  }

  Future<void> playBgMusic() async {
    if (!_storage.getMusicEnabled()) return;
    try {
      await _musicPlayer.play(AssetSource('audio/bg_music.mp3'), volume: 0.4);
    } catch (_) {}
  }

  Future<void> stopBgMusic() async {
    await _musicPlayer.stop();
  }

  Future<void> pauseBgMusic() async {
    await _musicPlayer.pause();
  }

  Future<void> resumeBgMusic() async {
    if (_storage.getMusicEnabled()) {
      await _musicPlayer.resume();
    }
  }

  Future<void> playCoin() async {
    if (!_storage.getSoundEnabled()) return;
    try {
      await _sfxPlayer.play(AssetSource('audio/coin_collect.mp3'), volume: 0.6);
    } catch (_) {}
  }

  Future<void> playJump() async {
    if (!_storage.getSoundEnabled()) return;
    try {
      final player = AudioPlayer();
      await player.play(AssetSource('audio/jump.mp3'), volume: 0.5);
    } catch (_) {}
  }

  Future<void> playSlide() async {
    if (!_storage.getSoundEnabled()) return;
    try {
      final player = AudioPlayer();
      await player.play(AssetSource('audio/slide.mp3'), volume: 0.5);
    } catch (_) {}
  }

  Future<void> playSwipe() async {
    if (!_storage.getSoundEnabled()) return;
    try {
      final player = AudioPlayer();
      await player.play(AssetSource('audio/swipe.mp3'), volume: 0.4);
    } catch (_) {}
  }

  Future<void> playPowerUp() async {
    if (!_storage.getSoundEnabled()) return;
    try {
      final player = AudioPlayer();
      await player.play(AssetSource('audio/powerup.mp3'), volume: 0.7);
    } catch (_) {}
  }

  Future<void> playCrash() async {
    if (!_storage.getSoundEnabled()) return;
    try {
      final player = AudioPlayer();
      await player.play(AssetSource('audio/crash.mp3'), volume: 0.8);
    } catch (_) {}
  }

  void dispose() {
    _musicPlayer.dispose();
    _sfxPlayer.dispose();
  }
}
