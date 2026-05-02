import 'package:flutter/material.dart';
import '../services/audio_service.dart';
import '../services/admob_service.dart';
import 'game_screen.dart';
import 'main_menu.dart';

class GameOverScreen extends StatefulWidget {
  final int score;
  final int coins;
  final int highScore;
  final VoidCallback onRestart;
  final VoidCallback onMainMenu;

  const GameOverScreen({
    super.key,
    required this.score,
    required this.coins,
    required this.highScore,
    required this.onRestart,
    required this.onMainMenu,
  });

  @override
  State<GameOverScreen> createState() => _GameOverScreenState();
}

class _GameOverScreenState extends State<GameOverScreen>
    with SingleTickerProviderStateMixin {
  final AudioService _audio = AudioService();
  final AdMobService _adMob = AdMobService();

  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  bool _continued = false;
  bool _usedRewardedAd = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _scaleAnim = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );
    _controller.forward();
    _adMob.loadBannerAd((ad) => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isNewHighScore = widget.score >= widget.highScore;

    return Scaffold(
      body: Stack(
        children: [
          // Background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF0A0A1A),
                  Color(0xFF1A0A2E),
                  Color(0xFF0A0A1A),
                ],
              ),
            ),
            child: SafeArea(
              child: Center(
                child: ScaleTransition(
                  scale: _scaleAnim,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Game Over Text
                        const Text(
                          'GAME OVER',
                          style: TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFFF00A0),
                            shadows: [
                              Shadow(
                                color: Color(0xFFFF00A0),
                                blurRadius: 30,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 30),

                        // Score display
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(0xFF00F0FF).withOpacity(0.3),
                            ),
                          ),
                          child: Column(
                            children: [
                              Text(
                                'SCORE',
                                style: TextStyle(
                                  fontSize: 14,
                                  letterSpacing: 4,
                                  color: Colors.white.withOpacity(0.5),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${widget.score}',
                                style: const TextStyle(
                                  fontSize: 56,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              if (isNewHighScore)
                                Container(
                                  margin: const EdgeInsets.only(top: 8),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFF00A0).withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: const Color(0xFFFF00A0),
                                    ),
                                  ),
                                  child: const Text(
                                    'NEW HIGH SCORE!',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFFFF00A0),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Coins earned
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              'assets/images/powerups/coin.png',
                              width: 28,
                              height: 28,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '+${widget.coins}',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.amber,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 30),

                        // Continue with rewarded ad (one-time per game over)
                        if (!_continued)
                          GestureDetector(
                            onTap: () {
                              _adMob.showRewardedAd(
                                onReward: (amount) {
                                  setState(() {
                                    _continued = true;
                                    _usedRewardedAd = true;
                                  });
                                  _audio.playPowerUp();
                                  Navigator.of(context).pushReplacement(
                                    MaterialPageRoute(
                                      builder: (_) => const GameScreen(),
                                    ),
                                  );
                                },
                                onDismiss: () {},
                              );
                            },
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFFF00A0),
                                    Color(0xFFFF4080),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFFF00A0).withOpacity(0.4),
                                    blurRadius: 20,
                                  ),
                                ],
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.play_circle_fill,
                                    color: Colors.white,
                                    size: 28,
                                  ),
                                  SizedBox(width: 12),
                                  Text(
                                    'CONTINUE',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Icon(Icons.videocam, color: Colors.white, size: 18),
                                ],
                              ),
                            ),
                          ),

                        const SizedBox(height: 16),

                        // Play Again — interstitial every 3 games, skipped if rewarded was used
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              _audio.playSwipe();
                              if (!_usedRewardedAd && _adMob.shouldShowInterstitial()) {
                                _adMob.showInterstitialAd(onComplete: widget.onRestart);
                              } else {
                                widget.onRestart();
                              }
                            },
                            icon: const Icon(Icons.replay),
                            label: const Text('PLAY AGAIN'),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Main Menu — interstitial every 3 games, skipped if rewarded was used
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              _audio.playSwipe();
                              void goToMenu() {
                                Navigator.of(context).pushAndRemoveUntil(
                                  MaterialPageRoute(
                                    builder: (_) => const MainMenu(),
                                  ),
                                  (route) => false,
                                );
                              }
                              if (!_usedRewardedAd && _adMob.shouldShowInterstitial()) {
                                _adMob.showInterstitialAd(onComplete: goToMenu);
                              } else {
                                goToMenu();
                              }
                            },
                            icon: const Icon(Icons.home),
                            label: const Text('MAIN MENU'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white.withOpacity(0.1),
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Banner ad pinned to bottom
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _adMob.getBannerWidget(),
          ),
        ],
      ),
    );
  }
}
