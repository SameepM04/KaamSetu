import 'dart:async';

import 'package:flutter/material.dart';

import '../animations/page_transition.dart';
import '../widgets/animated_background.dart';
import '../widgets/brand_logo.dart';
import '../widgets/interactive_drag.dart';
import '../widgets/onboarding_elements.dart';
import '../widgets/skip_button.dart';
import 'onboarding_one.dart';
import 'onboarding_three.dart';
import 'role_selection_screen.dart';

/// Second onboarding screen — "Bring Hands Together."
///
/// Only this screen was touched: splash, onboarding one/three, login,
/// theme, routing, colors, fonts and assets used elsewhere are untouched.
/// The left_hand.png / right_hand.png / center_glow.png assets are used
/// as-is (see HandsStage in onboarding_elements.dart) — nothing is redrawn.
class OnboardingTwo extends StatefulWidget {
  const OnboardingTwo({super.key});

  @override
  State<OnboardingTwo> createState() => _OnboardingTwoState();
}

class _OnboardingTwoState extends State<OnboardingTwo> with TickerProviderStateMixin {
  // Idle ambient loop (drives the subtle hand float / glow shimmer).
  late final AnimationController _ambient;

  // One-shot entrance: logo / headline / subtitle fade in, hands slide
  // inward, glow + bridge dots fade in. 500ms, easeOutCubic per spec.
  late final AnimationController _entry;
  late final Animation<double> _entryCurve;

  // Resting hand separation once the entrance has settled (matches the
  // reference image); the drag gesture pushes this from .16 up to ~.92.
  double _restProgress = .16;

  Timer? _handshakeTimer;
  Timer? _navigationTimer;

  @override
  void initState() {
    super.initState();
    _ambient = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat();
    _entry = AnimationController(vsync: this, duration: const Duration(milliseconds: 500))..forward();
    _entryCurve = CurvedAnimation(parent: _entry, curve: Curves.easeOutCubic);
  }

  void _completeSequence() {
    setState(() => _restProgress = .9);
    _handshakeTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _restProgress = 1);
    });
    _navigationTimer = Timer(const Duration(milliseconds: 800), () {
      if (mounted) Navigator.of(context).pushReplacement(premiumPageRoute(const OnboardingThree()));
    });
  }

  @override
  void dispose() {
    _ambient.dispose();
    _entry.dispose();
    _handshakeTimer?.cancel();
    _navigationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).height < 700;
    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: AnimatedBackdrop(warmCenter: true)),
          SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(31, compact ? 13 : 25, 31, 27),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.topRight,
                    child: SkipButton(
                      onSkip: () => Navigator.of(context).pushReplacement(premiumPageRoute(const RoleSelectionScreen())),
                    ),
                  ),
                  FadeTransition(
                    opacity: _entryCurve,
                    child: const KaamSetuBrand(compact: true),
                  ),
                  SizedBox(height: compact ? 28 : 48),
                  FadeTransition(
                    opacity: _entryCurve,
                    child: SlideTransition(
                      position: Tween<Offset>(begin: const Offset(0, .18), end: Offset.zero).animate(_entryCurve),
                      child: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: 'Bring Hands\n',
                              style: TextStyle(color: const Color(0xFF122A72), fontWeight: FontWeight.w800),
                            ),
                            TextSpan(
                              text: 'Together.',
                              style: TextStyle(color: const Color(0xFF2563FF), fontWeight: FontWeight.w800),
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontSize: compact ? 40 : 47),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  FadeTransition(
                    opacity: _entryCurve,
                    child: Text(
                      'Build trust through meaningful\nlocal connections.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: const Color(0xFF394867).withValues(alpha: .9), fontSize: 18, height: 1.36),
                    ),
                  ),
                  Expanded(
                    child: AnimatedBuilder(
                      animation: Listenable.merge([_ambient, _entryCurve]),
                      builder: (_, __) => HandsStage(
                        progress: _restProgress * _entryCurve.value,
                        ambient: _ambient.value,
                      ),
                    ),
                  ),
                  InteractiveDrag(
                    label: 'Drag to build the bridge',
                    icon: Icons.double_arrow_rounded,
                    centerThumb: false,
                    onProgress: (value) => setState(() => _restProgress = (.16 + value * .76).clamp(.16, .92)),
                    onComplete: _completeSequence,
                  ),
                  const SizedBox(height: 30),
                  PageDots(
                    active: 1,
                    onDotTap: (index) {
                      if (index == 1) return;
                      final route = index == 0 ? const OnboardingOne() : const OnboardingThree();
                      Navigator.of(context).pushReplacement(premiumPageRoute(route));
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
