import 'dart:math';
import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../services/audio_service.dart';
import '../services/admob_service.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  final StorageService _storage = StorageService();
  final AudioService _audio = AudioService();
  final AdMobService _adMob = AdMobService();

  int _coins = 0;
  int _gems = 0;
  String _selectedCharacter = 'default';
  String _selectedHoverboard = 'default';
  List<String> _unlockedCharacters = ['default'];
  List<String> _unlockedHoverboards = ['default'];

  final List<Map<String, dynamic>> _characters = [
    {
      'id': 'default',
      'name': 'Neon Runner',
      'price': 0,
      'image': 'assets/images/characters/runner_run.png',
    },
    {
      'id': 'cyber_punk',
      'name': 'Cyber Punk',
      'price': 5000,
      'image': 'assets/images/characters/runner_jump.png',
    },
    {
      'id': 'stealth',
      'name': 'Stealth Agent',
      'price': 10000,
      'image': 'assets/images/characters/runner_slide.png',
    },
  ];

  final List<Map<String, dynamic>> _hoverboards = [
    {
      'id': 'default',
      'name': 'Standard Board',
      'price': 0,
      'image': 'assets/images/powerups/hoverboard.png',
    },
    {
      'id': 'neon_blade',
      'name': 'Neon Blade',
      'price': 8000,
      'image': 'assets/images/powerups/hoverboard.png',
    },
    {
      'id': 'plasma',
      'name': 'Plasma Rider',
      'price': 15000,
      'image': 'assets/images/powerups/hoverboard.png',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
    _adMob.loadRewardedAd();
  }

  void _loadData() {
    setState(() {
      _coins = _storage.getCoins();
      _gems = _storage.getGems();
      _selectedCharacter = _storage.getSelectedCharacter();
      _selectedHoverboard = _storage.getSelectedHoverboard();
      _unlockedCharacters = _storage.getUnlockedCharacters();
      _unlockedHoverboards = _storage.getUnlockedHoverboards();
    });
  }

  void _selectCharacter(String id) {
    if (_unlockedCharacters.contains(id)) {
      _storage.setSelectedCharacter(id);
      _audio.playPowerUp();
      _loadData();
    } else {
      final char = _characters.firstWhere((c) => c['id'] == id);
      final price = char['price'] as int;
      if (_coins >= price) {
        _storage.addCoins(-price);
        _storage.unlockCharacter(id);
        _storage.setSelectedCharacter(id);
        _audio.playPowerUp();
        _loadData();
      } else {
        _showNeedCoinsDialog();
      }
    }
  }

  void _selectHoverboard(String id) {
    if (_unlockedHoverboards.contains(id)) {
      _storage.setSelectedHoverboard(id);
      _audio.playPowerUp();
      _loadData();
    } else {
      final board = _hoverboards.firstWhere((b) => b['id'] == id);
      final price = board['price'] as int;
      if (_coins >= price) {
        _storage.addCoins(-price);
        _storage.unlockHoverboard(id);
        _storage.setSelectedHoverboard(id);
        _audio.playPowerUp();
        _loadData();
      } else {
        _showNeedCoinsDialog();
      }
    }
  }

  void _showNeedCoinsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text(
          'Need More Coins',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Watch a video to earn free coins!',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _adMob.showRewardedAd(
                onReward: (amount) {
                  _storage.addCoins(100);
                  _audio.playCoin();
                  _loadData();
                },
                onDismiss: () {},
              );
            },
            child: const Text('Watch Ad'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text(
            'SHOP',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF00F0FF),
            ),
          ),
          bottom: const TabBar(
            indicatorColor: Color(0xFF00F0FF),
            labelColor: Color(0xFF00F0FF),
            unselectedLabelColor: Colors.white60,
            tabs: [
              Tab(text: 'CHARACTERS'),
              Tab(text: 'HOVERBOARDS'),
            ],
          ),
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF0A0A1A),
                Color(0xFF1A0A2E),
              ],
            ),
          ),
          child: Column(
            children: [
              // Currency bar
              Padding(
                padding: const EdgeInsets.all(16),
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
                    ElevatedButton.icon(
                      onPressed: () {
                        _adMob.showRewardedAd(
                          onReward: (amount) {
                            _storage.addCoins(100);
                            _audio.playCoin();
                            _loadData();
                          },
                          onDismiss: () {},
                        );
                      },
                      icon: const Icon(Icons.videocam, size: 16),
                      label: const Text('Free Coins'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF00A0),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Tab content
              Expanded(
                child: TabBarView(
                  children: [
                    _buildCharacterGrid(),
                    _buildHoverboardGrid(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCharacterGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: _characters.length,
      itemBuilder: (context, index) {
        final char = _characters[index];
        final isUnlocked = _unlockedCharacters.contains(char['id']);
        final isSelected = _selectedCharacter == char['id'];

        return GestureDetector(
          onTap: () => _selectCharacter(char['id']),
          child: Container(
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFF00F0FF).withOpacity(0.15)
                  : Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFF00F0FF)
                    : Colors.white.withOpacity(0.1),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  char['image'],
                  height: 100,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 12),
                Text(
                  char['name'],
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                if (!isUnlocked)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.monetization_on,
                          color: Colors.amber,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${char['price']}',
                          style: const TextStyle(
                            color: Colors.amber,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  )
                else if (isSelected)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00F0FF).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'SELECTED',
                      style: TextStyle(
                        color: Color(0xFF00F0FF),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  )
                else
                  const Text(
                    'OWNED',
                    style: TextStyle(
                      color: Colors.white60,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHoverboardGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: _hoverboards.length,
      itemBuilder: (context, index) {
        final board = _hoverboards[index];
        final isUnlocked = _unlockedHoverboards.contains(board['id']);
        final isSelected = _selectedHoverboard == board['id'];

        return GestureDetector(
          onTap: () => _selectHoverboard(board['id']),
          child: Container(
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFFFF00A0).withOpacity(0.15)
                  : Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFFFF00A0)
                    : Colors.white.withOpacity(0.1),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  board['image'],
                  height: 80,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 12),
                Text(
                  board['name'],
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                if (!isUnlocked)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.monetization_on,
                          color: Colors.amber,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${board['price']}',
                          style: const TextStyle(
                            color: Colors.amber,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  )
                else if (isSelected)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF00A0).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'SELECTED',
                      style: TextStyle(
                        color: Color(0xFFFF00A0),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  )
                else
                  const Text(
                    'OWNED',
                    style: TextStyle(
                      color: Colors.white60,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
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
}
