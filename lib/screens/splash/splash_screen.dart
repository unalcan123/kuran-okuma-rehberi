import 'package:flutter/material.dart';

import '../../core/responsive.dart';
import '../home/home_screen.dart';

/// App splash — the book cover image is the entire screen. It carries
/// its own title/branding, so nothing is drawn on top of it: no app
/// name, no extra logo, no button. [BoxFit.contain] keeps the cover's
/// aspect ratio intact on every screen size; any letterboxed space is
/// filled with a background close to the cover's own blue so the
/// image never looks cropped or stretched.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  static const _splashDuration = Duration(milliseconds: 1800);
  static const _splashBackground = Color(0xFF35579A);

  @override
  void initState() {
    super.initState();
    Future.delayed(_splashDuration, _goToHome);
  }

  void _goToHome() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    const cover = Image(
      image: AssetImage('assets/images/splash/kapak_splash.png'),
      fit: BoxFit.contain,
    );

    // Phones: let the cover use the full screen (still BoxFit.contain,
    // so it's never stretched or cropped). Tablet/desktop/web: cap it
    // to a sensible reader-sized box instead of blowing the cover up
    // to fill a whole monitor.
    final body =
        Responsive.isMobile(context)
            ? SizedBox.expand(child: cover)
            : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 420,
                  maxHeight: 640,
                ),
                child: cover,
              ),
            );

    return Scaffold(backgroundColor: _splashBackground, body: body);
  }
}
