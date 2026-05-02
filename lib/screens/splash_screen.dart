import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/main_menu.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeIn;
  late Animation<double> _scale;
  late Animation<double> _glow;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );

    _fadeIn = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0, 0.4, curve: Curves.easeIn),
      ),
    );

    _scale = Tween<double>(begin: 0.5, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0, 0.5, curve: Curves.elasticOut),
      ),
    );

    _glow = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 0.7, curve: Curves.easeInOut),
      ),
    );

    _controller.forward();

    Timer(const Duration(milliseconds: 3500), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainMenu()),
        );
      }
    });
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
              Color(0xFF0A0A1A),
            ],
          ),
        ),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FadeTransition(
                    opacity: _fadeIn,
                    child: ScaleTransition(
                      scale: _scale,
                      child: Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF00F0FF)
                                  .withOpacity(_glow.value * 0.5),
                              blurRadius: 40 + _glow.value * 20,
                              spreadRadius: 10 + _glow.value * 10,
                            ),
                            BoxShadow(
                              color: const Color(0xFFFF00A0)
                                  .withOpacity(_glow.value * 0.3),
                              blurRadius: 60 + _glow.value * 30,
                              spreadRadius: 20 + _glow.value * 15,
                            ),
                          ],
                          border: Border.all(
                            color: const Color(0xFF00F0FF)
                                .withOpacity(0.5 + _glow.value * 0.5),
                            width: 3,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            'chAs',
                            style: TextStyle(
                              fontSize: 56,
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFF00F0FF),
                              letterSpacing: 4,
                              shadows: [
                                Shadow(
                                  color: const Color(0xFF00F0FF),
                                  blurRadius: 20 + _glow.value * 30,
                                ),
                                Shadow(
                                  color: const Color(0xFFFF00A0),
                                  blurRadius: 40 + _glow.value * 40,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  FadeTransition(
                    opacity: _fadeIn,
                    child: Text(
                      'TECH GROUP',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 8,
                        color: const Color(0xFFFF00A0)
                            .withOpacity(0.7 + _glow.value * 0.3),
                        shadows: [
                          Shadow(
                            color: const Color(0xFFFF00A0),
                            blurRadius: 10 + _glow.value * 15,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 60),
                  FadeTransition(
                    opacity: _fadeIn,
                    child: Text(
                      'PRESENTS',
                      style: TextStyle(
                        fontSize: 14,
                        letterSpacing: 6,
                        color: Colors.white.withOpacity(0.4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ScaleTransition(
                    scale: _scale,
                    child: FadeTransition(
                      opacity: _fadeIn,
                      child: Image.asset(
                        'assets/images/ui/title_logo.png',
                        width: 280,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
