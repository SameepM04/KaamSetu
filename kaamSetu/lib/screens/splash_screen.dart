import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../widgets/splash_elements.dart';
import 'onboarding_one.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _enter;
  Timer? _navigationTimer;

  @override
  void initState() {
    super.initState();
    _enter = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2300),
    )..forward();
    _navigationTimer = Timer(const Duration(milliseconds: 2500), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(_onboardingRoute());
      }
    });
  }

  Route<void> _onboardingRoute() => PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 450),
        reverseTransitionDuration: const Duration(milliseconds: 350),
        pageBuilder: (_, __, ___) => const OnboardingOne(),
        transitionsBuilder: (_, animation, __, child) {
          final curve = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          );
          return FadeTransition(
            opacity: curve,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(.035, .018),
                end: Offset.zero,
              ).animate(curve),
              child: child,
            ),
          );
        },
      );

  @override
  void dispose() {
    _navigationTimer?.cancel();
    _enter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final background = CurvedAnimation(
      parent: _enter,
      curve: const Interval(0, .12, curve: Curves.easeOut),
    );
    final decor = CurvedAnimation(
      parent: _enter,
      curve: const Interval(.08, .28, curve: Curves.easeOutCubic),
    );
    final brand = CurvedAnimation(
      parent: _enter,
      curve: const Interval(.26, .5, curve: Curves.easeOutBack),
    );
    final title = CurvedAnimation(
      parent: _enter,
      curve: const Interval(.47, .64, curve: Curves.easeOutCubic),
    );
    final scene = CurvedAnimation(
      parent: _enter,
      curve: const Interval(.51, .75, curve: Curves.easeOutCubic),
    );
    final features = CurvedAnimation(
      parent: _enter,
      curve: const Interval(.62, .82, curve: Curves.easeOutCubic),
    );
    final loader = CurvedAnimation(
      parent: _enter,
      curve: const Interval(.73, .95, curve: Curves.easeOutCubic),
    );

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: FadeTransition(
              opacity: background,
              child: const SplashBackdrop(),
            ),
          ),
          Positioned.fill(
            child: FadeTransition(
              opacity: decor,
              child: const SplashDecorations(),
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final height = constraints.maxHeight;
                final compact = height < 700;
                final logoTop = height * (compact ? .185 : .215);
                final sceneTop = height * (compact ? .5 : .525);
                final featureTop = height * (compact ? .7 : .705);
                final loaderTop = height * (compact ? .9 : .905);
                final logoWidth = (constraints.maxWidth * (compact ? .3 : .325))
                    .clamp(104.0, 138.0)
                    .toDouble();

                return Stack(
                  children: [
                    Positioned(
                      top: logoTop,
                      left: 24,
                      right: 24,
                      child: FadeTransition(
                        opacity: brand,
                        child: ScaleTransition(
                          scale:
                              Tween<double>(begin: .85, end: 1).animate(brand),
                          child: SplashBrand(logoWidth: logoWidth),
                        ),
                      ),
                    ),
                    Positioned(
                      top: logoTop + logoWidth + (compact ? 0 : 4),
                      left: 20,
                      right: 20,
                      child: FadeTransition(
                        opacity: title,
                        child: const _BrandWords(),
                      ),
                    ),
                    Positioned(
                      top: sceneTop,
                      left: 0,
                      right: 0,
                      height: (height * .22).clamp(150.0, 184.0).toDouble(),
                      child: FadeTransition(
                        opacity: scene,
                        child: const SplashConnectionScene(),
                      ),
                    ),
                    Positioned(
                      top: featureTop,
                      left: 17,
                      right: 17,
                      child: FadeTransition(
                        opacity: features,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, .06),
                            end: Offset.zero,
                          ).animate(features),
                          child: SplashFeaturePanel(entry: _enter),
                        ),
                      ),
                    ),
                    Positioned(
                      top: loaderTop,
                      left: 76,
                      right: 76,
                      child: FadeTransition(
                        opacity: loader,
                        child: SplashLoadingIndicator(progress: _enter),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _BrandWords extends StatelessWidget {
  const _BrandWords();

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          RichText(
            text: const TextSpan(
              style: TextStyle(
                fontSize: 42,
                height: .92,
                letterSpacing: -1.8,
                fontWeight: FontWeight.w700,
              ),
              children: [
                TextSpan(text: 'Kaam', style: TextStyle(color: AppColors.blue)),
                TextSpan(
                    text: 'Setu', style: TextStyle(color: AppColors.orange)),
              ],
            ),
          ),
          const SizedBox(height: 10),
          const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _TaglineDot(color: AppColors.blue),
              SizedBox(width: 8),
              Text(
                'Bridging Work. Building Trust.',
                style: TextStyle(
                  color: AppColors.navy,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(width: 8),
              _TaglineDot(color: AppColors.orange),
            ],
          ),
        ],
      );
}

class _TaglineDot extends StatelessWidget {
  const _TaglineDot({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      );
}
