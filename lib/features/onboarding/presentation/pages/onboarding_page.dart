import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:medcare/core/routes/app_router.dart';
import 'package:medcare/core/theme/app_theme.dart';
import 'package:medcare/features/onboarding/presentation/cubit/onboarding_cubit.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _controller = PageController();

  final _pages = const [
    _OnboardStep(
      iconColor: Color(0xFF6F7EFF),
      title: 'Track Your Medications',
      subtitle: 'Never miss a dose with our smart reminder system',
      icon: Icons.medication_liquid,
    ),
    _OnboardStep(
      iconColor: Color(0xFF7C4DFF),
      title: 'Set Custom Schedules',
      subtitle: 'Create personalized medication schedules that fit your lifestyle',
      icon: Icons.access_time,
    ),
    _OnboardStep(
      iconColor: Color(0xFFEA80FC),
      title: 'Monitor Your Health',
      subtitle: 'Keep track of your medication history and health progress',
      icon: Icons.health_and_safety,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => OnboardingCubit(_pages.length),
      child: Builder(
        // Use inner context so Provider is found
        builder: (innerContext) => Scaffold(
          backgroundColor: AppColors.lightBg,
          body: AnnotatedRegion<SystemUiOverlayStyle>(
            value: const SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: Brightness.dark,
              statusBarBrightness: Brightness.light,
            ),
            child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  const SizedBox(height: 24),
                  Expanded(
                    child: PageView.builder(
                      controller: _controller,
                      itemCount: _pages.length,
                      onPageChanged: (i) => innerContext.read<OnboardingCubit>().setIndex(i),
                      itemBuilder: (_, i) => _pages[i],
                    ),
                  ),
                  const SizedBox(height: 8),
                  BlocBuilder<OnboardingCubit, OnboardingState>(
                    builder: (context, state) {
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton(
                            onPressed: _completeOnboarding,
                            child: const Text('Skip', style: TextStyle(color: AppColors.textLight)),
                          ),
                          _Dots(current: state.index, total: state.total),
                          SizedBox(
                            width: 120,
                            child: ElevatedButton(
                              onPressed: () {
                                if (state.isLast) {
                                  _completeOnboarding();
                                } else {
                                  _controller.nextPage(
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeOut,
                                  );
                                }
                              },
                              child: Text(state.isLast ? 'Get Started' : 'Next'),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 18),
                ],
              ),
            ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('onboarding_seen', true);
    } catch (_) {
      // ignore persistence errors; still navigate to login
    }
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, AppRoutes.login);
  }
}

class _OnboardStep extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color iconColor;
  const _OnboardStep({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Spacer(flex: 3),
        // Icon block
        Container(
          width: 150,
          height: 150,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(.14),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 80),
        ),
        const SizedBox(height: 36),
        // Text block in the visual middle
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Column(
            children: [
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 10),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
        const Spacer(flex: 4),
      ],
    );
  }
}

class _Dots extends StatelessWidget {
  final int current;
  final int total;
  const _Dots({required this.current, required this.total});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(total, (i) {
        final active = i == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          height: 6,
          width: active ? 20 : 6,
          decoration: BoxDecoration(
            color: active ? AppColors.primary : const Color(0xFFD1D1D6),
            borderRadius: BorderRadius.circular(6),
          ),
        );
      }),
    );
  }
}
