import 'package:flutter/material.dart';

class TraksLogo extends StatelessWidget {
  final double fontSize;
  final Color? color;
  final bool centered;

  const TraksLogo({
    super.key,
    this.fontSize = 24,
    this.color,
    this.centered = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // We use a high-fidelity Stack or specialized Text to mimic the "Bold Logo"
    // The key is the FontWeight.w900 and negative letterSpacing.
    return Hero(
      tag: 'traks_logo_identity',
      child: Text(
        'TRAKS',
        textAlign: centered ? TextAlign.center : TextAlign.start,
        style: TextStyle(
          color: color ?? theme.colorScheme.onSurface,
          fontWeight: FontWeight.w900,
          fontSize: fontSize,
          letterSpacing: -1.2, // Tight tracking for that "designed" feel
          height: 0.9, // Adjust leading for tighter vertical density
          fontFamily: 'Inter', // Fallback, we can add this if needed
        ),
      ),
    );
  }
}
