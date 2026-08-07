import 'package:flutter/material.dart';

import '../animations/page_transition.dart';
import '../theme/app_colors.dart';
import '../widgets/animated_background.dart';
import '../widgets/brand_logo.dart';
import '../widgets/onboarding_elements.dart';
import 'onboarding_one.dart';
import 'onboarding_two.dart';
import 'role_selection_screen.dart';

class OnboardingThree extends StatefulWidget {
  const OnboardingThree({super.key});

  @override
  State<OnboardingThree> createState() => _OnboardingThreeState();
}

class _OnboardingThreeState extends State<OnboardingThree>
    with TickerProviderStateMixin {
  late final AnimationController _reveal;
  late final AnimationController _ambient;

  @override
  void initState() {
    super.initState();
    _reveal = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2500))
      ..forward();
    _ambient =
        AnimationController(vsync: this, duration: const Duration(seconds: 4))
          ..repeat();
  }

  @override
  void dispose() {
    _reveal.dispose();
    _ambient.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).height < 700;
    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(
              child: AnimatedBackdrop(warmCenter: true, showPins: false)),
          SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(27, compact ? 13 : 23, 27, 27),
              child: AnimatedBuilder(
                animation: Listenable.merge([_reveal, _ambient]),
                builder: (_, __) {
                  final trustProgress = Curves.easeOutCubic
                      .transform((_reveal.value / .42).clamp(0, 1));
                  return Column(
                    children: [
                      const KaamSetuBrand(compact: true),
                      SizedBox(height: compact ? 25 : 40),
                      Text('Building Trust,\nOne Job at a Time.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(fontSize: compact ? 34 : 39)),
                      const SizedBox(height: 17),
                      const Text(
                          'Safe hiring. Fair opportunities.\nStronger communities.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: AppColors.inkMuted,
                              fontSize: 18,
                              height: 1.36)),
                      Expanded(
                          child: TrustConnection(
                              progress: trustProgress,
                              ambient: _ambient.value)),
                      Row(
                        children: [
                          TrustFeatureCard(
                              icon: Icons.verified_user_rounded,
                              label: 'Verified\nWorkers',
                              color: AppColors.blue,
                              visible: _reveal.value > .45),
                          const SizedBox(width: 10),
                          TrustFeatureCard(
                              icon: Icons.shield_rounded,
                              label: 'Trusted\nConnections',
                              color: AppColors.green,
                              visible: _reveal.value > .58),
                          const SizedBox(width: 10),
                          TrustFeatureCard(
                              icon: Icons.home_rounded,
                              label: 'Happy\nHomes',
                              color: AppColors.orange,
                              visible: _reveal.value > .71),
                        ],
                      ),
                      const SizedBox(height: 20),
                      AnimatedSlide(
                        offset: _reveal.value > .84
                            ? Offset.zero
                            : const Offset(0, .22),
                        duration: const Duration(milliseconds: 520),
                        curve: Curves.elasticOut,
                        child: AnimatedOpacity(
                          opacity: _reveal.value > .84 ? 1 : 0,
                          duration: const Duration(milliseconds: 420),
                          child: PressableCta(
                              onPressed: () => Navigator.of(context)
                                  .pushReplacement(premiumPageRoute(
                                      const RoleSelectionScreen()))),
                        ),
                      ),
                      const SizedBox(height: 28),
                      PageDots(
                        active: 2,
                        onDotTap: (index) {
                          if (index == 2) return;
                          final route = index == 0
                              ? const OnboardingOne()
                              : const OnboardingTwo();
                          Navigator.of(context)
                              .pushReplacement(premiumPageRoute(route));
                        },
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
