import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter/material.dart';
import 'package:tracks_app/presentation/auth/auth_wrapper.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkPaymentRedirect();
  }

  Future<void> _checkPaymentRedirect() async {
    try {
      final uri = Uri.base;
      if (uri.queryParameters['status'] == 'success') {
        final userId = uri.queryParameters['userId'];
        if (userId != null && userId.isNotEmpty) {
          debugPrint(
            "Payment success redirect received for user: $userId on Web",
          );
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Verification Successful! 🎉'),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      }
    } catch (e) {
      debugPrint("Payment redirect check error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? const Color(0xFF050505) : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black;
    final logoAsset = isDarkMode 
        ? 'assets/images/logo-light.png' 
        : 'assets/images/logo-dark.png';

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Themed Logo Image
            Hero(
              tag: 'app_logo',
              child: Image.asset(
                logoAsset,
                height: 80,
                filterQuality: FilterQuality.high,
              ),
            ),
            const SizedBox(height: 24),
            // Minimal Animated Text
            DefaultTextStyle(
              style: TextStyle(
                fontSize: 24.0,
                fontWeight: FontWeight.w800,
                color: textColor.withValues(alpha: 0.8),
                letterSpacing: 4.0,
                fontFamily: 'Inter',
              ),
              child: AnimatedTextKit(
                animatedTexts: [
                  FadeAnimatedText(
                    'TRACKS',
                    duration: const Duration(milliseconds: 2000),
                  ),
                ],
                isRepeatingAnimation: false,
                onFinished: () {
                  Navigator.of(context).pushReplacement(
                    PageRouteBuilder(
                      pageBuilder: (_, __, ___) => const AuthWrapper(),
                      transitionsBuilder: (_, animation, __, child) {
                        return FadeTransition(opacity: animation, child: child);
                      },
                      transitionDuration: const Duration(milliseconds: 800),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
