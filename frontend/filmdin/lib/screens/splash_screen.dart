import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigate();
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(seconds: 3));
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const LoginScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppTheme.gold,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.movie_creation,
                color: Colors.black,
                size: 60,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'FILMDIN',
              style: TextStyle(
                color: AppTheme.gold,
                fontSize: 36,
                fontWeight: FontWeight.bold,
                letterSpacing: 8,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Connect. Create. Collaborate.',
              style: AppTheme.subheading,
            ),
            const SizedBox(height: 60),
            const CircularProgressIndicator(
              color: AppTheme.gold,
              strokeWidth: 2,
            ),
          ],
        ),
      ),
    );
  }
}