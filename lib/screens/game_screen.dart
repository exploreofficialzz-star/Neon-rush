import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../services/storage_service.dart';
import '../services/audio_service.dart';
import '../services/admob_service.dart';
import 'game_over_screen.dart';

enum Lane { left, center, right }
enum PlayerState { running, jumping, sliding, dead }
enum ObstacleType { barrier, train, drone }
enum PowerUpType { magnet, jetpack, shield, multiplier }

class GameEntity {
  double z; // Distance from player (0 = at player, >0 = ahead)
  Lane lane;
  bool active;
  GameEntity({required this.z, required this.lane, this.active = true});
}

class Obstacle extends GameEntity {
  ObstacleType type;
  bool tall; // Needs jump
  bool low;  // Needs slide
  Obstacle({
    required super.z,
    required super.lane,
    required this.type,
    this.tall = false,
    this.low = false,
  });
}

class Coin extends GameEntity {
  bool collected;
  Coin({required super.z, required super.lane, this.collected = false});
}

class PowerUp extends GameEntity {
  PowerUpType type;
  PowerUp({required super.z, required super.lane, required this.type});
}

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with TickerProviderStateMixin {
  final StorageService _storage = StorageService();
  final AudioService _audio = AudioService();
  final AdMobService _adMob = AdMobService();

  // Game state
  bool _playing = false;
  bool _paused = false;
  bool _gameOver = false;
  PlayerState _playerState = PlayerState.running;
  Lane _playerLane = Lane.center;
  
  // Game loop
  Timer? _gameTimer;
  double _gameSpeed = 12.0;
  double _distance = 0;
  int _score = 0;
  int _coins = 0;
  double _multiplier = 1.0;
  
  // Power-up timers
  double _magnetTime = 0;
  double _shieldTime = 0;
  double _multiplierTime = 0;
  double _jetpackTime = 0;
  bool _hasMagnet = false;
  bool _hasShield = false;
  bool _hasMultiplier = false;
  bool _hasJetpack = false;
  
  // Entities
  final List<Obstacle> _obstacles = [];
  final List<Coin> _coinsList = [];
  final List<PowerUp> _powerUps = [];
  
  // Animation
  double _jumpProgress = 0;
  double _slideProgress = 0;
  double _laneSwitchProgress = 0;
  Lane? _targetLane;
  
  // Spawn timing
  double _nextObstacleZ = 80;
  double _nextCoinZ = 30;
  double _nextPowerUpZ = 200;
  final Random _random = Random();
  
  // Ad banner
  BannerAd? _bannerAd;
  
  // Dimensions
  late double _laneWidth;
  late double _screenHeight;
  late double _horizonY;
  
  @override
  void initState() {
    super.initState();
    _adMob.loadBannerAd((ad) {
      setState(() => _bannerAd = ad);
    });
    _startGame();
  }
  
  void _startGame() {
    setState(() {
      _playing = true;
      _gameOver = false;
      _paused = false;
      _playerState = PlayerState.running;
      _playerLane = Lane.center;
      _gameSpeed = 12.0;
      _distance = 0;
      _score = 0;
      _coins = 0;
      _multiplier = 1.0;
      _magnetTime = 0;
      _shieldTime = 0;
      _multiplierTime = 0;
      _jetpackTime = 0;
      _hasMagnet = false;
      _hasShield = false;
      _hasMultiplier = false;
      _hasJetpack = false;
      _obstacles.clear();
      _coinsList.clear();
      _powerUps.clear();
      _jumpProgress = 0;
      _slideProgress = 0;
      _laneSwitchProgress = 0;
      _targetLane = null;
      _nextObstacleZ = 100;
      _nextCoinZ = 30;
      _nextPowerUpZ = 250;
    });
    
    _audio.playBgMusic();
    
    // Start game loop at 60 FPS
    _gameTimer?.cancel();
    _gameTimer = Timer.periodic(
      const Duration(milliseconds: 16),
      (timer) => _gameLoop(),
    );
  }
  
  void _gameLoop() {
    if (!_playing || _paused || _gameOver) return;
    
    setState(() {
      // Increase speed over time
      _gameSpeed = 12.0 + (_distance / 2000) * 8;
      _gameSpeed = _gameSpeed.clamp(12.0, 35.0);
      
      // Move world
      final moveAmount = _gameSpeed * 0.5;
      _distance += moveAmount;
      
      // Score from distance
      _score += (moveAmount * _multiplier).toInt();
      
      // Jetpack mode - fly over everything
      if (_hasJetpack) {
        _jetpackTime -= 0.016;
        if (_jetpackTime <= 0) {
          _hasJetpack = false;
          _jetpackTime = 0;
        }
      }
      
      // Update power-up timers
      if (_hasMagnet) {
        _magnetTime -= 0.016;
        if (_magnetTime <= 0) {
          _hasMagnet = false;
          _magnetTime = 0;
        }
      }
      if (_hasShield) {
        _shieldTime -= 0.016;
        if (_shieldTime <= 0) {
          _hasShield = false;
          _shieldTime = 0;
        }
      }
      if (_hasMultiplier) {
        _multiplierTime -= 0.016;
        if (_multiplierTime <= 0) {
          _hasMultiplier = false;
          _multiplierTime = 0;
          _multiplier = 1.0;
        }
      }
      
      // Update jump
      if (_playerState == PlayerState.jumping) {
        _jumpProgress += 0.06;
        if (_jumpProgress >= 1.0) {
          _jumpProgress = 0;
          _playerState = PlayerState.running;
        }
      }
      
      // Update slide
      if (_playerState == PlayerState.sliding) {
        _slideProgress += 0.04;
        if (_slideProgress >= 1.0) {
          _slideProgress = 0;
          _playerState = PlayerState.running;
        }
      }
      
      // Update lane switch
      if (_targetLane != null) {
        _laneSwitchProgress += 0.12;
        if (_laneSwitchProgress >= 1.0) {
          _playerLane = _targetLane!;
          _targetLane = null;
          _laneSwitchProgress = 0;
        }
      }
      
      // Spawn obstacles
      if (_distance + 200 > _nextObstacleZ) {
        _spawnObstacle();
        _nextObstacleZ = _distance + 60 + _random.nextDouble() * 80;
      }
      
      // Spawn coins
      if (_distance + 150 > _nextCoinZ) {
        _spawnCoins();
        _nextCoinZ = _distance + 40 + _random.nextDouble() * 60;
      }
      
      // Spawn power-ups
      if (_distance + 300 > _nextPowerUpZ) {
        _spawnPowerUp();
        _nextPowerUpZ = _distance + 400 + _random.nextDouble() * 400;
      }
      
      // Move entities
      _moveEntities();
      
      // Check collisions
      _checkCollisions();
      
      // Clean up old entities
      _cleanupEntities();
      
      // Magnet effect - pull coins
      if (_hasMagnet) {
        _magnetCoins();
      }
    });
  }
  
  void _spawnObstacle() {
    final lanes = [Lane.left, Lane.center, Lane.right];
    final lane = lanes[_random.nextInt(3)];
    
    // Choose obstacle type
    final rand = _random.nextDouble();
    ObstacleType type;
    bool tall = false;
    bool low = false;
    
    if (rand < 0.5) {
      type = ObstacleType.barrier;
      tall = _random.nextBool();
      low = !tall && _random.nextBool();
    } else if (rand < 0.75) {
      type = ObstacleType.train;
      tall = true;
    } else {
      type = ObstacleType.drone;
      low = true;
    }
    
    _obstacles.add(Obstacle(
      z: _nextObstacleZ,
      lane: lane,
      type: type,
      tall: tall,
      low: low,
    ));
    
    // Sometimes spawn double obstacles
    if (_random.nextDouble() < 0.2 && _distance > 500) {
      final otherLane = lanes.where((l) => l != lane).toList()[_random.nextInt(2)];
      _obstacles.add(Obstacle(
        z: _nextObstacleZ,
        lane: otherLane,
        type: ObstacleType.barrier,
        tall: false,
        low: false,
      ));
    }
  }
  
  void _spawnCoins() {
    final pattern = _random.nextInt(3);
    final startZ = _nextCoinZ;
    
    if (pattern == 0) {
      // Single lane line
      final lane = [Lane.left, Lane.center, Lane.right][_random.nextInt(3)];
      for (int i = 0; i < 5; i++) {
        _coinsList.add(Coin(z: startZ + i * 15, lane: lane));
      }
    } else if (pattern == 1) {
      // All lanes
      for (int i = 0; i < 3; i++) {
        for (final lane in [Lane.left, Lane.center, Lane.right]) {
          _coinsList.add(Coin(z: startZ + i * 15, lane: lane));
        }
      }
    } else {
      // Arc pattern
      final lane = [Lane.left, Lane.center, Lane.right][_random.nextInt(3)];
      _coinsList.add(Coin(z: startZ, lane: lane));
      _coinsList.add(Coin(z: startZ + 15, lane: lane));
      _coinsList.add(Coin(z: startZ + 30, lane: lane));
    }
  }
  
  void _spawnPowerUp() {
    final types = [PowerUpType.magnet, PowerUpType.jetpack, PowerUpType.shield, PowerUpType.multiplier];
    final lane = [Lane.left, Lane.center, Lane.right][_random.nextInt(3)];
    _powerUps.add(PowerUp(
      z: _nextPowerUpZ,
      lane: lane,
      type: types[_random.nextInt(types.length)],
    ));
  }
  
  void _moveEntities() {
    for (final obs in _obstacles) {
      obs.z -= _gameSpeed * 0.5;
    }
    for (final coin in _coinsList) {
      coin.z -= _gameSpeed * 0.5;
    }
    for (final pu in _powerUps) {
      pu.z -= _gameSpeed * 0.5;
    }
  }
  
  void _checkCollisions() {
    if (_hasJetpack) return; // Invincible while jetpack
    
    const collisionRange = 15.0;
    
    // Check obstacle collisions
    for (final obs in _obstacles) {
      if (!obs.active) continue;
      if (obs.z.abs() < collisionRange && _isSameLane(obs.lane)) {
        // Check if player can avoid
        if (obs.tall && _playerState == PlayerState.jumping) continue;
        if (obs.low && _playerState == PlayerState.sliding) continue;
        
        if (_hasShield) {
          _hasShield = false;
          _shieldTime = 0;
          obs.active = false;
          _audio.playCrash();
          continue;
        }
        
        _triggerGameOver();
        return;
      }
    }
    
    // Check coin collection
    for (final coin in _coinsList) {
      if (coin.collected) continue;
      if (coin.z.abs() < collisionRange && _isSameLane(coin.lane)) {
        coin.collected = true;
        _coins++;
        _audio.playCoin();
      }
    }
    
    // Check power-up collection
    for (final pu in _powerUps) {
      if (!pu.active) continue;
      if (pu.z.abs() < collisionRange && _isSameLane(pu.lane)) {
        pu.active = false;
        _activatePowerUp(pu.type);
      }
    }
  }
  
  bool _isSameLane(Lane lane) {
    if (_targetLane != null) {
      // Interpolate lane position
      final currentIndex = _playerLane.index;
      final targetIndex = _targetLane!.index;
      final progress = _laneSwitchProgress;
      final effectiveIndex = currentIndex + (targetIndex - currentIndex) * progress;
      return (effectiveIndex - lane.index).abs() < 0.5;
    }
    return _playerLane == lane;
  }
  
  void _magnetCoins() {
    for (final coin in _coinsList) {
      if (coin.collected) continue;
      if (coin.z > 0 && coin.z < 100) {
        // Pull coin to player's lane
        if (coin.lane != _playerLane) {
          // Visual only - collect if close enough
          if (coin.z < 30) {
            coin.collected = true;
            _coins++;
            _audio.playCoin();
          }
        }
      }
    }
  }
  
  void _cleanupEntities() {
    _obstacles.removeWhere((o) => o.z < -50);
    _coinsList.removeWhere((c) => c.collected || c.z < -50);
    _powerUps.removeWhere((p) => !p.active || p.z < -50);
  }
  
  void _activatePowerUp(PowerUpType type) {
    _audio.playPowerUp();
    switch (type) {
      case PowerUpType.magnet:
        _hasMagnet = true;
        _magnetTime = 8.0;
        break;
      case PowerUpType.jetpack:
        _hasJetpack = true;
        _jetpackTime = 6.0;
        _playerState = PlayerState.running;
        _jumpProgress = 0;
        break;
      case PowerUpType.shield:
        _hasShield = true;
        _shieldTime = 10.0;
        break;
      case PowerUpType.multiplier:
        _hasMultiplier = true;
        _multiplierTime = 10.0;
        _multiplier = 2.0;
        break;
    }
  }
  
  void _triggerGameOver() {
    _gameOver = true;
    _playing = false;
    _gameTimer?.cancel();
    _audio.playCrash();
    _audio.stopBgMusic();
    
    // Save stats
    _storage.setHighScore(_score);
    _storage.addTotalScore(_score);
    _storage.addCoins(_coins);
    _storage.incrementGamesPlayed();
    _storage.incrementRunCount();
    
    // Show interstitial every 3 runs
    if (_adMob.shouldShowInterstitial()) {
      _adMob.showInterstitialAd();
    }
    
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => GameOverScreen(
              score: _score,
              coins: _coins,
              highScore: _storage.getHighScore(),
              onRestart: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const GameScreen()),
                );
              },
              onMainMenu: () {
                Navigator.of(context).pop();
              },
            ),
          ),
        );
      }
    });
  }
  
  // Controls
  void _swipeLeft() {
    if (!_playing || _gameOver) return;
    if (_playerLane == Lane.left && _targetLane == null) return;
    
    _audio.playSwipe();
    setState(() {
      if (_targetLane != null) {
        if (_targetLane == Lane.center) { _targetLane = Lane.left; }
        else if (_targetLane == Lane.right) { _targetLane = Lane.center; }
      } else {
        if (_playerLane == Lane.center) { _targetLane = Lane.left; }
        else if (_playerLane == Lane.right) { _targetLane = Lane.center; }
        _laneSwitchProgress = 0;
      }
    });
  }
  
  void _swipeRight() {
    if (!_playing || _gameOver) return;
    if (_playerLane == Lane.right && _targetLane == null) return;
    
    _audio.playSwipe();
    setState(() {
      if (_targetLane != null) {
        if (_targetLane == Lane.center) { _targetLane = Lane.right; }
        else if (_targetLane == Lane.left) { _targetLane = Lane.center; }
      } else {
        if (_playerLane == Lane.center) { _targetLane = Lane.right; }
        else if (_playerLane == Lane.left) { _targetLane = Lane.center; }
        _laneSwitchProgress = 0;
      }
    });
  }
  
  void _swipeUp() {
    if (!_playing || _gameOver) return;
    if (_playerState == PlayerState.jumping || _hasJetpack) return;
    
    _audio.playJump();
    setState(() {
      _playerState = PlayerState.jumping;
      _jumpProgress = 0;
      _slideProgress = 0;
    });
  }
  
  void _swipeDown() {
    if (!_playing || _gameOver) return;
    if (_playerState == PlayerState.sliding || _hasJetpack) return;
    
    _audio.playSlide();
    setState(() {
      _playerState = PlayerState.sliding;
      _slideProgress = 0;
      _jumpProgress = 0;
    });
  }
  
  double _getLaneX(Lane lane, double laneWidth, double centerX) {
    switch (lane) {
      case Lane.left:
        return centerX - laneWidth;
      case Lane.center:
        return centerX;
      case Lane.right:
        return centerX + laneWidth;
    }
  }
  
  double _getPlayerX(double laneWidth, double centerX) {
    if (_targetLane != null) {
      final currentX = _getLaneX(_playerLane, laneWidth, centerX);
      final targetX = _getLaneX(_targetLane!, laneWidth, centerX);
      return currentX + (targetX - currentX) * _laneSwitchProgress;
    }
    return _getLaneX(_playerLane, laneWidth, centerX);
  }
  
  double _getPlayerY() {
    if (_hasJetpack) {
      return _horizonY - 120 - (_jetpackTime > 0 ? sin(_jetpackTime * 3) * 10 : 0);
    }
    if (_playerState == PlayerState.jumping) {
      final jumpHeight = sin(_jumpProgress * pi) * 100;
      return _horizonY - 20 - jumpHeight;
    }
    if (_playerState == PlayerState.sliding) {
      return _horizonY + 40;
    }
    return _horizonY - 20;
  }
  
  double _getEntityScreenY(double z) {
    // z: positive = ahead of player, 0 = at player
    // Far objects (large z) appear near horizon (smaller Y)
    // Close objects (z near 0) appear near bottom (larger Y)
    const maxDist = 300.0;
    final t = (1.0 - (z / maxDist)).clamp(0.0, 1.0);
    return _horizonY + t * (_screenHeight - _horizonY - 200);
  }
  
  double _getEntityScale(double z) {
    // Far objects are smaller, close objects are larger
    const maxDist = 300.0;
    final t = (1.0 - (z / maxDist)).clamp(0.0, 1.0);
    return 0.2 + t * 0.8;
  }
  
  @override
  void dispose() {
    _gameTimer?.cancel();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    _laneWidth = size.width / 3.5;
    _screenHeight = size.height;
    _horizonY = size.height * 0.35;
    final centerX = size.width / 2;
    
    return Scaffold(
      body: GestureDetector(
        onTapUp: (details) {
          final dx = details.localPosition.dx;
          final dy = details.localPosition.dy;
          final width = size.width;
          final height = size.height;
          
          if (dy < height * 0.4) {
            _swipeUp();
          } else if (dy > height * 0.7) {
            _swipeDown();
          } else if (dx < width * 0.3) {
            _swipeLeft();
          } else if (dx > width * 0.7) {
            _swipeRight();
          }
        },
        onPanUpdate: (details) {
          if (details.delta.dx > 15) _swipeRight();
          if (details.delta.dx < -15) _swipeLeft();
          if (details.delta.dy < -20) _swipeUp();
          if (details.delta.dy > 20) _swipeDown();
        },
        child: Container(
          color: const Color(0xFF0A0A1A),
          child: Stack(
            children: [
              // Background city
              Positioned.fill(
                child: Image.asset(
                  'assets/images/environment/city_bg.jpg',
                  fit: BoxFit.cover,
                  opacity: const AlwaysStoppedAnimation(0.6),
                ),
              ),
              
              // Road
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: size.height - _horizonY + 50,
                child: Image.asset(
                  'assets/images/environment/road.jpg',
                  fit: BoxFit.cover,
                ),
              ),
              
              // Lane dividers
              ..._buildLaneDividers(size, centerX),
              
              // Entities behind player (z > 0)
              ..._buildEntities(centerX, true),
              
              // Player
              Positioned(
                left: _getPlayerX(_laneWidth, centerX) - 35,
                top: _getPlayerY() - 50,
                child: Transform.scale(
                  scale: 1.2,
                  child: _buildPlayerSprite(),
                ),
              ),
              
              // Shield effect
              if (_hasShield)
                Positioned(
                  left: _getPlayerX(_laneWidth, centerX) - 50,
                  top: _getPlayerY() - 60,
                  child: Image.asset(
                    'assets/images/powerups/shield.png',
                    width: 100,
                    height: 100,
                    opacity: const AlwaysStoppedAnimation(0.6),
                  ),
                ),
              
              // Entities in front of player (z < 0)
              ..._buildEntities(centerX, false),
              
              // HUD
              _buildHUD(size),
              
              // Bottom Banner Ad
              if (_bannerAd != null)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: SizedBox(
                    width: _bannerAd!.size.width.toDouble(),
                    height: _bannerAd!.size.height.toDouble(),
                    child: AdWidget(ad: _bannerAd!),
                  ),
                ),
              
              // Pause button
              Positioned(
                top: 40,
                right: 16,
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _paused = !_paused;
                      if (_paused) {
                        _audio.pauseBgMusic();
                      } else {
                        _audio.resumeBgMusic();
                      }
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _paused ? Icons.play_arrow : Icons.pause,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
              ),
              
              // Pause overlay
              if (_paused)
                Container(
                  color: Colors.black.withOpacity(0.7),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'PAUSED',
                          style: TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF00F0FF),
                            shadows: [
                              Shadow(
                                color: Color(0xFF00F0FF),
                                blurRadius: 20,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 30),
                        ElevatedButton(
                          onPressed: () {
                            setState(() => _paused = false);
                            _audio.resumeBgMusic();
                          },
                          child: const Text('RESUME'),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF00A0),
                          ),
                          child: const Text('QUIT'),
                        ),
                      ],
                    ),
                  ),
                ),
              
              // Tutorial overlay for first launch
              if (_storage.getFirstLaunch() && !_storage.getTutorialCompleted())
                _buildTutorialOverlay(size),
            ],
          ),
        ),
      ),
    );
  }
  
  List<Widget> _buildLaneDividers(Size size, double centerX) {
    return [
      // Left lane divider
      Positioned(
        left: centerX - _laneWidth - 2,
        top: _horizonY,
        bottom: 0,
        width: 4,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFF00F0FF).withOpacity(0.1),
                const Color(0xFF00F0FF).withOpacity(0.5),
                const Color(0xFF00F0FF).withOpacity(0.1),
              ],
            ),
          ),
        ),
      ),
      // Right lane divider
      Positioned(
        left: centerX + _laneWidth - 2,
        top: _horizonY,
        bottom: 0,
        width: 4,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFFFF00A0).withOpacity(0.1),
                const Color(0xFFFF00A0).withOpacity(0.5),
                const Color(0xFFFF00A0).withOpacity(0.1),
              ],
            ),
          ),
        ),
      ),
    ];
  }
  
  Widget _buildPlayerSprite() {
    String asset;
    if (_playerState == PlayerState.jumping || _hasJetpack) {
      asset = 'assets/images/characters/runner_jump.png';
    } else if (_playerState == PlayerState.sliding) {
      asset = 'assets/images/characters/runner_slide.png';
    } else {
      asset = 'assets/images/characters/runner_run.png';
    }
    
    return Image.asset(
      asset,
      width: 70,
      height: 100,
      fit: BoxFit.contain,
    );
  }
  
  List<Widget> _buildEntities(double centerX, bool behindPlayer) {
    final widgets = <Widget>[];
    
    // Obstacles
    for (final obs in _obstacles.where((o) => behindPlayer ? o.z > 0 : o.z <= 0)) {
      if (!obs.active) continue;
      final x = _getLaneX(obs.lane, _laneWidth, centerX) - 30;
      final y = _getEntityScreenY(obs.z) - 40;
      final scale = _getEntityScale(obs.z);
      
      String asset;
      switch (obs.type) {
        case ObstacleType.barrier:
          asset = 'assets/images/obstacles/barrier.png';
          break;
        case ObstacleType.train:
          asset = 'assets/images/obstacles/train.png';
          break;
        case ObstacleType.drone:
          asset = 'assets/images/obstacles/drone.png';
          break;
      }
      
      widgets.add(
        Positioned(
          left: x,
          top: y,
          child: Transform.scale(
            scale: scale,
            child: Image.asset(
              asset,
              width: 60,
              height: obs.type == ObstacleType.train ? 80 : 60,
              fit: BoxFit.contain,
            ),
          ),
        ),
      );
    }
    
    // Coins
    for (final coin in _coinsList.where((c) => behindPlayer ? c.z > 0 : c.z <= 0)) {
      if (coin.collected) continue;
      final x = _getLaneX(coin.lane, _laneWidth, centerX) - 15;
      final y = _getEntityScreenY(coin.z) - 15;
      final scale = _getEntityScale(coin.z);
      
      widgets.add(
        Positioned(
          left: x,
          top: y,
          child: Transform.scale(
            scale: scale,
            child: Image.asset(
              'assets/images/powerups/coin.png',
              width: 30,
              height: 30,
              fit: BoxFit.contain,
            ),
          ),
        ),
      );
    }
    
    // Power-ups
    for (final pu in _powerUps.where((p) => behindPlayer ? p.z > 0 : p.z <= 0)) {
      if (!pu.active) continue;
      final x = _getLaneX(pu.lane, _laneWidth, centerX) - 20;
      final y = _getEntityScreenY(pu.z) - 20;
      final scale = _getEntityScale(pu.z);
      
      String asset;
      switch (pu.type) {
        case PowerUpType.magnet:
          asset = 'assets/images/powerups/magnet.png';
          break;
        case PowerUpType.jetpack:
          asset = 'assets/images/powerups/jetpack.png';
          break;
        case PowerUpType.shield:
          asset = 'assets/images/powerups/shield.png';
          break;
        case PowerUpType.multiplier:
          asset = 'assets/images/powerups/multiplier.png';
          break;
      }
      
      widgets.add(
        Positioned(
          left: x,
          top: y,
          child: Transform.scale(
            scale: scale,
            child: Image.asset(
              asset,
              width: 40,
              height: 40,
              fit: BoxFit.contain,
            ),
          ),
        ),
      );
    }
    
    return widgets;
  }
  
  Widget _buildHUD(Size size) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Score
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF00F0FF).withOpacity(0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SCORE',
                    style: TextStyle(
                      fontSize: 10,
                      letterSpacing: 3,
                      color: Colors.white.withOpacity(0.5),
                    ),
                  ),
                  Text(
                    '$_score',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Coins
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/images/powerups/coin.png',
                    width: 20,
                    height: 20,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '$_coins',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.amber,
                    ),
                  ),
                ],
              ),
            ),
            
            const Spacer(),
            
            // Power-up indicators
            if (_hasMagnet || _hasShield || _hasMultiplier || _hasJetpack)
              Row(
                children: [
                  if (_hasJetpack) _buildPowerUpIndicator('assets/images/powerups/jetpack.png', _jetpackTime),
                  if (_hasMagnet) _buildPowerUpIndicator('assets/images/powerups/magnet.png', _magnetTime),
                  if (_hasShield) _buildPowerUpIndicator('assets/images/powerups/shield.png', _shieldTime),
                  if (_hasMultiplier) _buildPowerUpIndicator('assets/images/powerups/multiplier.png', _multiplierTime),
                ],
              ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildPowerUpIndicator(String asset, double time) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF00F0FF).withOpacity(0.5)),
      ),
      child: Column(
        children: [
          Image.asset(asset, width: 24, height: 24),
          const SizedBox(height: 2),
          Text(
            time.toStringAsFixed(1),
            style: const TextStyle(fontSize: 10, color: Colors.white),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTutorialOverlay(Size size) {
    return Container(
      color: Colors.black.withOpacity(0.8),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.touch_app,
              size: 60,
              color: Color(0xFF00F0FF),
            ),
            const SizedBox(height: 20),
            const Text(
              'HOW TO PLAY',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF00F0FF),
              ),
            ),
            const SizedBox(height: 20),
            _buildTutorialItem('Swipe LEFT/RIGHT', 'Switch lanes'),
            _buildTutorialItem('Swipe UP', 'Jump over obstacles'),
            _buildTutorialItem('Swipe DOWN', 'Slide under obstacles'),
            _buildTutorialItem('Collect Coins', 'Earn currency'),
            _buildTutorialItem('Grab Power-ups', 'Get special abilities'),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                _storage.setTutorialCompleted(true);
                setState(() {});
              },
              child: const Text('GOT IT!'),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildTutorialItem(String title, String desc) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Color(0xFFFF00A0),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                desc,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
