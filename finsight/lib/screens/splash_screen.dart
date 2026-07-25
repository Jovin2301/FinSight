import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import './auth_provider.dart';
import './login_screen.dart';
import './main_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  Future<void> _checkLogin() async {
    // Show splash screen for 3 seconds
    await Future.delayed(const Duration(seconds: 3));

    final auth = context.read<AuthProvider>();

    await auth.tryAutoLogin();

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) =>
            auth.isLoggedIn ? const MainScreen() : const LoginScreen(),
      ),
    );
  }

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _scaleAnimation = Tween<double>(
      begin: 0.6,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _opacityAnimation = Tween<double>(begin: 0, end: 1).animate(_controller);

    _controller.forward();

    _checkLogin();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff00897B),

      body: Stack(
        children: [
          /// Decorative circles
          Positioned(
            top: -120,
            right: -80,
            child: Container(
              height: 260,
              width: 260,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(.08),
                shape: BoxShape.circle,
              ),
            ),
          ),

          Positioned(
            bottom: -140,
            left: -80,
            child: Container(
              height: 300,
              width: 300,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(.06),
                shape: BoxShape.circle,
              ),
            ),
          ),

          Center(
            child: FadeTransition(
              opacity: _opacityAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      height: 120,
                      width: 120,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            blurRadius: 25,
                            color: Colors.black.withOpacity(.15),
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),

                      child: Padding(
                        padding: const EdgeInsets.all(22),
                        child: Image.asset('assets/images/finsight_logo.png'),
                      ),
                    ),

                    const SizedBox(height: 35),

                    const Text(
                      "FinSight",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 34,
                        fontWeight: FontWeight.bold,
                        letterSpacing: .5,
                      ),
                    ),

                    const SizedBox(height: 10),

                    Text(
                      "Track • Analyze • Grow",
                      style: TextStyle(
                        color: Colors.white.withOpacity(.9),
                        fontSize: 18,
                      ),
                    ),

                    const SizedBox(height: 80),

                    const SizedBox(
                      width: 35,
                      height: 35,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Text(
              "Powered by FinSight",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(.7),
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
