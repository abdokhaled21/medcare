import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:medcare/core/routes/app_router.dart';
import 'package:medcare/core/theme/app_theme.dart';
import 'package:medcare/features/auth/presentation/pages/login_page.dart';
import 'package:medcare/features/home/presentation/pages/home_page.dart';
import 'package:medcare/features/onboarding/presentation/pages/onboarding_page.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _start() async {
    // Keep the splash for 2 seconds
    _timer = Timer(const Duration(seconds: 2), () async {
      bool seen = false;
      try {
        final prefs = await SharedPreferences.getInstance();
        seen = prefs.getBool('onboarding_seen') ?? false;
      } catch (_) {
        // ignore and default to not seen
      }
      if (!mounted) return;
      // If onboarding seen, route based on auth state
      if (seen) {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          _pushWithTransition(const HomePage(), routeName: AppRoutes.home);
        } else {
          _pushWithTransition(const LoginPage(), routeName: AppRoutes.login);
        }
      } else {
        _pushWithTransition(const OnboardingPage(), routeName: AppRoutes.onboarding);
      }
    });
  }

  void _pushWithTransition(Widget page, {required String routeName}) {
    Navigator.of(context).pushReplacement(PageRouteBuilder(
      settings: RouteSettings(name: routeName),
      transitionDuration: const Duration(milliseconds: 1200),
      reverseTransitionDuration: const Duration(milliseconds: 500),
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        // Delay the reveal a bit, then animate smoothly
        final radiusAnim = CurvedAnimation(
          parent: animation,
          curve: const Interval(0.12, 1.0, curve: Curves.easeOutCubic),
        );
        final fadeAnim = CurvedAnimation(
          parent: animation,
          curve: const Interval(0.18, 1.0, curve: Curves.easeOut),
        );
        return LayoutBuilder(
          builder: (ctx, constraints) {
            final size = Size(constraints.maxWidth, constraints.maxHeight);
            final maxRadius = math.sqrt(size.width * size.width + size.height * size.height);
            final radius = radiusAnim.value * maxRadius;
            return Stack(
              children: [
                // Circular reveal of the next page from the center
                ClipPath(
                  clipper: _CircleRevealClipper(
                    radius: radius,
                    center: Offset(size.width / 2, size.height / 2),
                  ),
                  child: FadeTransition(opacity: fadeAnim, child: child),
                ),
              ],
            );
          },
        );
      },
    ));
  }

  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
        child: Container(
          decoration: AppDecorations.gradientBackground,
          width: double.infinity,
          height: double.infinity,
          child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 108,
                height: 108,
                decoration: AppDecorations.roundedIconContainerStrong(),
                child: const Center(
                  child: Icon(
                    Icons.medication,
                    color: AppColors.purpleTop,
                    size: 56,
                  ),
                ),
              ),
              const SizedBox(height: 28),
              Text('MediCare+', style: Theme.of(context).textTheme.headlineLarge),
              const SizedBox(height: 8),
              Text(
                'Your Health Companion',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withOpacity(.85),
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ],
          ),
        ),
        ),
      ),
    );
  }
}

class _CircleRevealClipper extends CustomClipper<Path> {
  final double radius;
  final Offset center;

  _CircleRevealClipper({required this.radius, required this.center});

  @override
  Path getClip(Size size) {
    final path = Path();
    path.addOval(Rect.fromCircle(center: center, radius: radius));
    return path;
  }

  @override
  bool shouldReclip(_CircleRevealClipper oldClipper) {
    return oldClipper.radius != radius || oldClipper.center != center;
  }
}
