import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../services/audio_service.dart';
import '../services/admob_service.dart';
import 'game_screen.dart';
import 'shop_screen.dart';
import 'settings_screen.dart';
import 'daily_rewards.dart';

class MainMenu extends StatefulWidget {
  const MainMenu({super.key});

  @override
  State<MainMenu> createState() => _MainMenuState();
}

class _MainMenuState extends State<MainMenu> with TickerProviderStateMixin {
  final StorageService _storage = StorageService();
  final AudioService _audio = AudioService();
  final AdMobService _adMob = AdMobService();

  late AnimationController _floatController;
  late Animation<double> _floatAnim;
  late AnimationController _pulseController;
  int _coins = 0;
  int _gems = 0;
  int _highScore = 0;

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _floatAnim = Tween<double>(begin: -10, end: 10).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _loadData();
    _audio.playBgMusic();
    _adMob.loadBannerAd((ad) => setState(() {}));

    // Show daily rewards if available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkDailyRewards();
    });
  }

  void _loadData() {
    setState(() {
      _coins = _storage.getCoins();
      _gems = _storage.getGems();
      _highScore = _storage.getHighScore();
    });
  }

  void _checkDailyRewards() {
    final lastReward = _storage.getLastDailyReward();
    final today = DateTime.now().toIso8601String().split('T')[0];
    if (lastReward != today) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const DailyRewardsScreen()),
      );
    }
  }

  @override
  void dispose() {
    _floatController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0A0A1A),
              Color(0xFF1A0A2E),
              Color(0xFF0D1B2A),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Banner Ad at top
              _adMob.getBannerWidget(),
              
              // Top bar with currency
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildCurrencyBadge(
                      icon: Icons.monetization_on,
                      value: _coins,
                      color: Colors.amber,
                    ),
                    _buildCurrencyBadge(
                      icon: Icons.diamond,
                      value: _gems,
                      color: const Color(0xFF00F0FF),
                    ),
                  ],
                ),
              ),

              // High Score
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFFFF00A0).withOpacity(0.3),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      'HIGH SCORE',
                      style: TextStyle(
                        fontSize: 12,
                        letterSpacing: 3,
                        color: Colors.white.withOpacity(0.5),
                      ),
                    ),
                    Text(
                      '$_highScore',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFFF00A0),
                        shadows: [
                          Shadow(
                            color: Color(0xFFFF00A0),
                            blurRadius: 15,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Title Logo
              AnimatedBuilder(
                animation: _floatAnim,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, _floatAnim.value),
                    child: Image.asset(
                      'assets/images/ui/title_logo.png',
                      width: 300,
                      fit: BoxFit.contain,
                    ),
                  );
                },
              ),

              const SizedBox(height: 20),

              // Character preview
              AnimatedBuilder(
                animation: _floatController,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, _floatAnim.value * 0.5),
                    child: Image.asset(
                      'assets/images/characters/runner_run.png',
                      height: 150,
                      fit: BoxFit.contain,
                    ),
                  );
                },
              ),

              const Spacer(),

              // Play Button
              _buildGlowingButton(
                text: 'PLAY',
                icon: Icons.play_arrow_rounded,
                onTap: () {
                  _audio.playSwipe();
                  _adMob.showInterstitialAd(onComplete: () {});
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const GameScreen()),
                  ).then((_) => _loadData());
                },
              ),

              const SizedBox(height: 16),

              // Menu buttons row
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildMenuButton(
                    icon: Icons.shopping_cart,
                    label: 'SHOP',
                    onTap: () {
                      _audio.playSwipe();
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const ShopScreen()),
                      ).then((_) => _loadData());
                    },
                  ),
                  const SizedBox(width: 16),
                  _buildMenuButton(
                    icon: Icons.settings,
                    label: 'SETTINGS',
                    onTap: () {
                      _audio.playSwipe();
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const SettingsScreen()),
                      );
                    },
                  ),
                  const SizedBox(width: 16),
                  _buildMenuButton(
                    icon: Icons.card_giftcard,
                    label: 'REWARDS',
                    onTap: () {
                      _audio.playSwipe();
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const DailyRewardsScreen()),
                      ).then((_) => _loadData());
                    },
                  ),
                ],
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrencyBadge({
    required IconData icon,
    required int value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 6),
          Text(
            value.toString(),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlowingButton({
    required String text,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          return Container(
            width: 220,
            height: 70,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF00F0FF),
                  Color(0xFF0080FF),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00F0FF).withOpacity(
                    0.4 + _pulseController.value * 0.4,
                  ),
                  blurRadius: 20 + _pulseController.value * 20,
                  spreadRadius: 2 + _pulseController.value * 4,
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: const Color(0xFF0A0A1A), size: 32),
                const SizedBox(width: 12),
                Text(
                  text,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0A0A1A),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMenuButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 90,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withOpacity(0.2),
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFFFF00A0), size: 28),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.white70,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
