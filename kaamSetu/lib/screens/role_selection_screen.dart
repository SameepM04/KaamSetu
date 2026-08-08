import 'package:flutter/material.dart';

import '../animations/page_transition.dart';
import '../theme/app_colors.dart';
import '../widgets/brand_logo.dart';
import '../widgets/role_card.dart';
import '../widgets/role_selection_ambient_overlay.dart';
import 'household_signup_screen.dart';
import 'login_screen.dart';
import 'worker_signup_screen.dart';

/// Role Selection screen — pixel-matched to the approved design.
class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}
class _RoleSelectionScreenState extends State<RoleSelectionScreen>
    with TickerProviderStateMixin {
  late final AnimationController _entry = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 650),
  )..forward();

  late final AnimationController _breathe = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 3),
  )..repeat(reverse: true);

  late final AnimationController _banner = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _entry.dispose();
    _breathe.dispose();
    _banner.dispose();
    super.dispose();
  }

  void _goToWorkerSignUp() {
    Navigator.of(context).push(premiumPageRoute(const WorkerSignUpScreen()));
  }

  void _goToHouseholdSignUp() {
    Navigator.of(context).push(premiumPageRoute(const HouseholdSignUpScreen()));
  }

  void _goToLogin() {
    Navigator.of(context).push(premiumPageRoute(const LoginScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final entryCurve = CurvedAnimation(parent: _entry, curve: Curves.easeOutCubic);

    return Scaffold(
      body: Stack(
        children: [
          // Approved background artwork — sunrise skyline, network lines,
          // location pins. Kept as a single static asset so the pixels
          // match the source design exactly.
          const Positioned.fill(
            child: Image(
              image: AssetImage('assets/role_selection/bg_sunrise.png'),
              fit: BoxFit.cover,
            ),
          ),
          const Positioned.fill(child: RoleSelectionAmbientOverlay()),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxHeight < 720;
                return SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(24, compact ? 10 : 18, 24, 20),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight - (compact ? 20 : 38)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Back button
                        FadeTransition(
                          opacity: entryCurve,
                          child: _BackButton(onTap: () => Navigator.of(context).maybePop()),
                        ),
                        SizedBox(height: compact ? 4 : 10),

                        // Logo + tagline
                        FadeTransition(
                          opacity: entryCurve,
                          child: ScaleTransition(
                            scale: Tween<double>(begin: .94, end: 1).animate(entryCurve),
                            child: AnimatedBuilder(
                              animation: _breathe,
                              builder: (context, child) {
                                final breatheScale = 1 + (_breathe.value * .018);
                                return Transform.scale(scale: breatheScale, child: child);
                              },
                              child: const Center(child: KaamSetuBrand(compact: true)),
                            ),
                          ),
                        ),
                        SizedBox(height: compact ? 18 : 28),

                        // Headline
                        FadeTransition(
                          opacity: entryCurve,
                          child: const Text(
                            'Choose Your Role',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.navy,
                              fontSize: 29,
                              letterSpacing: -.6,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        FadeTransition(
                          opacity: entryCurve,
                          child: const Text(
                            'Select how you want to use KaamSetu',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.inkMuted,
                              fontSize: 14.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        SizedBox(height: compact ? 22 : 32),

                        // Role cards
                        FadeTransition(
                          opacity: entryCurve,
                          child: SlideTransition(
                            position: Tween<Offset>(begin: const Offset(0, .05), end: Offset.zero)
                                .animate(entryCurve),
                            child: IntrinsicHeight(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(
                                    child: RoleCard(
                                      imageAsset: 'assets/role_selection/worker.png',
                                      title: 'I am a Worker',
                                      subtitle: 'Find daily work near you and grow your skills.',
                                      accentColor: AppColors.blue,
                                      backgroundGradient: const [Color(0xFFFDFEFF), Color(0xFFEFF6FF)],
                                      floatPhase: -1,
                                      onTap: _goToWorkerSignUp,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: RoleCard(
                                      imageAsset: 'assets/role_selection/house.png',
                                      title: 'I am a Household',
                                      subtitle: 'Hire trusted local workers for your daily needs.',
                                      accentColor: AppColors.orange,
                                      backgroundGradient: const [Color(0xFFFFFDF9), Color(0xFFFFF3E4)],
                                      floatPhase: 1,
                                      onTap: _goToHouseholdSignUp,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: compact ? 20 : 30),

                        // Trust banner
                        FadeTransition(
                          opacity: entryCurve,
                          child: AnimatedBuilder(
                            animation: _banner,
                            builder: (context, child) {
                              final lift = (_banner.value - .5) * 6;
                              return Transform.translate(offset: Offset(0, lift), child: child);
                            },
                            child: const _TrustBanner(),
                          ),
                        ),
                        SizedBox(height: compact ? 16 : 22),

                        // Log in
                        FadeTransition(
                          opacity: entryCurve,
                          child: Center(
                            child: Column(
                              children: [
                                const Text(
                                  'Already have an account?',
                                  style: TextStyle(color: AppColors.inkMuted, fontSize: 13.5, fontWeight: FontWeight.w500),
                                ),
                                const SizedBox(height: 4),
                                _LogInLink(onTap: _goToLogin),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: compact ? 8 : 16),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _BackButton extends StatefulWidget {
  const _BackButton({required this.onTap});
  final VoidCallback onTap;

  @override
  State<_BackButton> createState() => _BackButtonState();
}

class _BackButtonState extends State<_BackButton> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 150),
    reverseDuration: const Duration(milliseconds: 200),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => Transform.scale(scale: 1 - _controller.value * .12, child: child),
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTapDown: (_) => _controller.forward(),
          onTapCancel: () => _controller.reverse(),
          onTapUp: (_) => _controller.reverse(),
          onTap: widget.onTap,
          splashColor: AppColors.blue.withValues(alpha: .18),
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [BoxShadow(color: AppColors.blue.withValues(alpha: .18), blurRadius: 12, offset: const Offset(0, 5))],
            ),
            child: const Icon(Icons.chevron_left_rounded, color: AppColors.navy, size: 26),
          ),
        ),
      ),
    );
  }
}

class _TrustBanner extends StatelessWidget {
  const _TrustBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .72),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withValues(alpha: .9), width: 1.2),
        boxShadow: const [BoxShadow(color: Color(0x144775B4), blurRadius: 18, offset: Offset(0, 8))],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.blue.withValues(alpha: .14)),
            child: const Icon(Icons.verified_user_rounded, color: AppColors.blue, size: 15),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              'Safe. Verified. Trusted by Your Community.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.navy, fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _LogInLink extends StatelessWidget {
  const _LogInLink({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Text('Log In', style: TextStyle(color: AppColors.blue, fontSize: 15, fontWeight: FontWeight.w800)),
              Icon(Icons.chevron_right_rounded, color: AppColors.blue, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
