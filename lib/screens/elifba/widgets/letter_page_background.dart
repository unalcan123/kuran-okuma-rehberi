import 'package:flutter/material.dart';

/// Decorative backdrop for the "Tek Harf" hero screen — the designed
/// illustration (arch, lanterns, mosque skyline on rolling hills,
/// rosette watermark). Purely ornamental — painted once behind the
/// real content, never intercepts touches.
class LetterPageBackground extends StatelessWidget {
  const LetterPageBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return const Positioned.fill(
      child: IgnorePointer(
        child: Image(
          image: AssetImage('assets/images/backgrounds/tek_harf_bg.png'),
          fit: BoxFit.cover,
          alignment: Alignment.center,
        ),
      ),
    );
  }
}
