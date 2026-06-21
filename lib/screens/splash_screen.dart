import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kids_tracing_app/constants/app_constants.dart';
import 'package:kids_tracing_app/screens/home_screen.dart';

/// Entry splash screen with logo and automatic navigation.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.92, end: 1.08).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    Future<void>.delayed(AppConstants.splashDuration, _goToLearning);
  }

  void _goToLearning() {
    if (!mounted) {
      return;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const HomeScreen()),
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
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFFFF8E7),
              Color(0xFFFFE4F3),
              Color(0xFFE8F4FF),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScaleTransition(
              scale: _scaleAnimation,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  color: AppConstants.primaryColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppConstants.primaryColor.withValues(alpha: 0.35),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.edit_rounded,
                  size: 72,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 28),
            Text(
              AppConstants.appTitle,
              style: GoogleFonts.baloo2(
                fontSize: 34,
                fontWeight: FontWeight.w800,
                color: AppConstants.primaryColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Learn numbers 1 to 20!',
              style: GoogleFonts.baloo2(
                fontSize: 20,
                color: AppConstants.secondaryColor,
              ),
            ),
            const SizedBox(height: 36),
            const CircularProgressIndicator(
              color: AppConstants.secondaryColor,
            ),
          ],
        ),
      ),
    );
  }
}
