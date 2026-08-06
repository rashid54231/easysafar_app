import 'dart:async';
import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  final Widget nextScreen;

  const SplashScreen({super.key, required this.nextScreen});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _controller.forward();

    // Navigate to next screen after 3 seconds
    Timer(const Duration(milliseconds: 2800), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => widget.nextScreen,
            transitionsBuilder: (_, animation, __, child) => FadeTransition(
              opacity: animation,
              child: child,
            ),
            transitionDuration: const Duration(milliseconds: 600),
          ),
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
      backgroundColor: const Color(0xFF0F1624),
      body: Stack(
        children: [
          // Background Gradient Glow
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF00D4AA).withValues(alpha: 0.15),
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.blueAccent.withValues(alpha: 0.15),
              ),
            ),
          ),

          // Main Center Content
          Center(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return FadeTransition(
                  opacity: _fadeAnimation,
                  child: Transform.scale(
                    scale: _scaleAnimation.value,
                    child: child,
                  ),
                );
              },
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Glowing Image Box
                  Container(
                    width: 150,
                    height: 150,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF182234),
                      borderRadius: BorderRadius.circular(36),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF00D4AA).withValues(alpha: 0.3),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                        ),
                      ],
                      border: Border.all(
                        color: const Color(0xFF00D4AA).withValues(alpha: 0.5),
                        width: 2,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(32),
                      child: Transform.scale(
                        scale: 1.4,
                        child: Image.asset(
                          'assets/images/trip_cover.png',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => const Icon(
                            Icons.directions_car_filled_rounded,
                            size: 70,
                            color: Color(0xFF00D4AA),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 36),

                  // App Name
                  const Text(
                    "EasySafar",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 38,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2.0,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Subtitle / Tagline
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00D4AA).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      "SMART INTERCITY CARPOOLING",
                      style: TextStyle(
                        color: Color(0xFF00D4AA),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom Loading Indicator & Copyright
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Column(
              children: [
                SizedBox(
                  width: 40,
                  height: 3,
                  child: LinearProgressIndicator(
                    backgroundColor: Colors.white12,
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF00D4AA)),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  "YOUR SMART TRAVEL PARTNER",
                  style: TextStyle(
                    color: Colors.white38,
                    fontSize: 10,
                    letterSpacing: 3.0,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
