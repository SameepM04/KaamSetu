import 'package:flutter/material.dart';

import '../animations/page_transition.dart';
import '../theme/app_colors.dart';
import '../widgets/animated_background.dart';
import '../widgets/brand_logo.dart';
import '../widgets/interactive_drag.dart';
import '../widgets/onboarding_elements.dart';
import '../widgets/skip_button.dart';
import 'onboarding_two.dart';
import 'role_selection_screen.dart';

class OnboardingOne extends StatefulWidget {
  const OnboardingOne({super.key});

  @override
  State<OnboardingOne> createState() => _OnboardingOneState();
}

class _OnboardingOneState extends State<OnboardingOne>
    with TickerProviderStateMixin {
  late final AnimationController _entry;
  late final AnimationController _ambient;
  double _dragProgress = 0;

  @override
  void initState() {
    super.initState();
    _entry = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700))
      ..forward();
    _ambient =
        AnimationController(vsync: this, duration: const Duration(seconds: 4))
          ..repeat();
  }

  @override
  void dispose() {
    _entry.dispose();
    _ambient.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).height < 700;
    final entryCurve =
        CurvedAnimation(parent: _entry, curve: Curves.easeOutCubic);
    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(
              child: AnimatedBackdrop(showAccentParticle: false)),
          SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(31, compact ? 13 : 25, 31, 27),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.topRight,
                    child: SkipButton(
                      onSkip: () => Navigator.of(context).pushReplacement(
                          premiumPageRoute(const RoleSelectionScreen())),
                    ),
                  ),
                  FadeTransition(
                      opacity: entryCurve,
                      child: ScaleTransition(
                          scale: Tween<double>(begin: .92, end: 1)
                              .animate(entryCurve),
                          child: const KaamSetuBrand(compact: true))),
                  SizedBox(height: compact ? 28 : 49),
                  Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    children: [
                      Text.rich(
                        TextSpan(
                          children: [
                            const TextSpan(text: 'Connecting\n'),
                            TextSpan(
                                text: 'Opportunities.',
                                style: const TextStyle(
                                    color: AppColors.electricBlue)),
                          ],
                        ),
                        textAlign: TextAlign.center,
                        style: Theme.of(context)
                            .textTheme
                            .headlineLarge
                            ?.copyWith(fontSize: compact ? 40 : 47),
                      ),
                      Positioned(
                        bottom: 4,
                        right: -18,
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                              color: Color(0x66FFB65A), shape: BoxShape.circle),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text(
                      'Helping skilled workers and trusted\nhouseholds find each other effortlessly.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: AppColors.inkMuted,
                          fontSize: 18,
                          height: 1.36)),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) => AnimatedBuilder(
                        animation: Listenable.merge([_entry, _ambient]),
                        builder: (_, __) => Stack(
                          children: [
                            Align(
                              alignment: Alignment.lerp(
                                  const Alignment(-1.75, .05),
                                  const Alignment(-.74, .05),
                                  entryCurve.value)!,
                              child: SizedBox(
                                  width: constraints.maxWidth * .44,
                                  height: constraints.maxWidth * .44,
                                  child: WorkerCard(
                                      progress: _dragProgress,
                                      ambient: _ambient.value)),
                            ),
                            Align(
                              alignment: Alignment.lerp(
                                  const Alignment(1.75, .05),
                                  const Alignment(.74, .05),
                                  entryCurve.value)!,
                              child: SizedBox(
                                  width: constraints.maxWidth * .44,
                                  height: constraints.maxWidth * .44,
                                  child: HouseCard(
                                      progress: _dragProgress,
                                      ambient: _ambient.value)),
                            ),
                            Positioned.fill(
                                child: IgnorePointer(
                                    child: AnimatedBridge(
                                        time: _ambient.value,
                                        progress: _dragProgress))),
                          ],
                        ),
                      ),
                    ),
                  ),
                  InteractiveDrag(
                    label: 'Swipe to Connect',
                    icon: Icons.handshake_outlined,
                    onProgress: (value) =>
                        setState(() => _dragProgress = value),
                    onComplete: () => Navigator.of(context).pushReplacement(
                        premiumPageRoute(const OnboardingTwo())),
                  ),
                  const SizedBox(height: 30),
                  const PageDots(active: 0),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
