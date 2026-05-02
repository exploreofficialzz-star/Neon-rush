import 'dart:math';
import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../services/audio_service.dart';
import '../services/admob_service.dart';

class DailyRewardsScreen extends StatefulWidget {
  const DailyRewardsScreen({super.key});

  @override
  State<DailyRewardsScreen> createState() => _DailyRewardsScreenState();
}

class _DailyRewardsScreenState extends State<DailyRewardsScreen>
    with SingleTickerProviderStateMixin {
  final StorageService _storage = StorageService();
  final AudioService _audio = AudioService();
  final AdMobService _adMob = AdMobService();

  late AnimationController _controller;
  int _streak = 0;
  bool _claimed = false;
  int _rewardCoins = 0;

  final List<int> _rewards = [100, 200, 300, 500, 750, 1000, 2000];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _loadData();
    _adMob.loadRewardedAd();
  }

  void _loadData() {
    final lastReward = _storage.getLastDailyReward();
    final today = DateTime.now().toIso8601String().split('T')[0];
    
    int streak = _storage.getDailyStreak();
    
    if (lastReward != null) {
      final lastDate = DateTime.parse(lastReward);
      final now = DateTime.now();
      final difference = now.difference(lastDate).inDays;
      
      if (difference == 0) {
        // Already claimed today
        _claimed = true;
      } else if (difference == 1) {
        // Consecutive day
        streak = streak + 1;
      } else if (difference > 1) {
        // Streak broken
        streak = 0;
      }
    }
    
    streak = streak.clamp(0, 6);
    
    setState(() {
      _streak = streak;
      _rewardCoins = _rewards[streak.clamp(0, 6)];
    });
  }

  void _claimReward() {
    if (_claimed) return;
    
    final today = DateTime.now().toIso8601String().split('T')[0];
    
    _storage.setLastDailyReward(today);
    _storage.setDailyStreak(_streak);
    _storage.addCoins(_rewardCoins);
    
    _audio.playCoin();
    _controller.forward();
    
    setState(() {
      _claimed = true;
    });
  }

  void _watchAdForBonus() {
    _adMob.showRewardedAd(
      onReward: (amount) {
        _storage.addCoins(500);
        _audio.playCoin();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bonus 500 coins earned!')),
        );
      },
      onDismiss: () {},
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0A0A1A),
              Color(0xFF1A0A2E),
              Color(0xFF0D1B2A),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Header
                const Text(
                  'DAILY REWARDS',
                  style: TextStyle(
                    fontSize: 28,
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
                const SizedBox(height: 8),
                Text(
                  'Day ${_streak + 1} of 7',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.6),
                  ),
                ),

                const SizedBox(height: 30),

                // Reward days
                Expanded(
                  child: ListView.builder(
                    itemCount: 7,
                    itemBuilder: (context, index) {
                      final isCurrent = index == _streak;
                      final isPast = index < _streak;
                      final isFuture = index > _streak;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isCurrent
                              ? const Color(0xFF00F0FF).withOpacity(0.15)
                              : isPast
                                  ? Colors.white.withOpacity(0.05)
                                  : Colors.white.withOpacity(0.02),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isCurrent
                                ? const Color(0xFF00F0FF)
                                : isPast
                                    ? const Color(0xFFFF00A0).withOpacity(0.3)
                                    : Colors.white.withOpacity(0.1),
                            width: isCurrent ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: isCurrent
                                    ? const Color(0xFF00F0FF)
                                    : isPast
                                        ? const Color(0xFFFF00A0)
                                        : Colors.white.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: isPast
                                    ? const Icon(
                                        Icons.check,
                                        color: Colors.white,
                                        size: 20,
                                      )
                                    : Text(
                                        '${index + 1}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: isCurrent
                                              ? const Color(0xFF0A0A1A)
                                              : Colors.white,
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Day ${index + 1}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: isCurrent
                                          ? const Color(0xFF00F0FF)
                                          : isPast
                                              ? Colors.white.withOpacity(0.4)
                                              : Colors.white,
                                    ),
                                  ),
                                  if (isCurrent)
                                    const Text(
                                      'Available Now',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFFFF00A0),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            Image.asset(
                              'assets/images/powerups/coin.png',
                              width: 24,
                              height: 24,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${_rewards[index]}',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isPast
                                    ? Colors.white.withOpacity(0.4)
                                    : Colors.amber,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 20),

                // Claim button
                if (!_claimed)
                  GestureDetector(
                    onTap: _claimReward,
                    child: AnimatedBuilder(
                      animation: _controller,
                      builder: (context, child) {
                        return Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 18),
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
                                color: const Color(0xFF00F0FF).withOpacity(0.4),
                                blurRadius: 20,
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.asset(
                                'assets/images/powerups/coin.png',
                                width: 28,
                                height: 28,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'CLAIM $_rewardCoins COINS',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0A0A1A),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  )
                else
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: Color(0xFF00F0FF),
                          size: 24,
                        ),
                        SizedBox(width: 12),
                        Text(
                          'CLAIMED!',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF00F0FF),
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 12),

                // Bonus ad button
                if (_claimed)
                  ElevatedButton.icon(
                    onPressed: _watchAdForBonus,
                    icon: const Icon(Icons.videocam, size: 18),
                    label: const Text('Watch Ad for +500 Bonus'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF00A0),
                      minimumSize: const Size(double.infinity, 48),
                    ),
                  ),

                const SizedBox(height: 12),

                // Close button
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'CLOSE',
                    style: TextStyle(color: Colors.white60),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
