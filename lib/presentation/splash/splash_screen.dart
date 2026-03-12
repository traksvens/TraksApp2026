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
          // Verification is now handled securely by the React frontend
          // before the redirect occurs.
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
    // Determine if dark mode is active to set background color
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? Colors.black : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Use AnimatedTextKit for the "TRAKS" text
            // We use 'TRAKS' as the logo text.
            DefaultTextStyle(
              style: TextStyle(
                fontSize: 60.0,
                fontWeight: FontWeight.w900,
                color: textColor,
                letterSpacing: -2.0,
                fontFamily:
                    'Roboto', // Or usage generic font if custom not loaded
              ),
              child: AnimatedTextKit(
                animatedTexts: [
                  FadeAnimatedText(
                    'TRAKS',
                    duration: const Duration(milliseconds: 2000),
                    fadeInEnd: 0.4,
                    fadeOutBegin: 0.9,
                  ),
                ],
                isRepeatingAnimation: false,
                onFinished: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const AuthWrapper()),
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
