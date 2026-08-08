import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../widgets/animated_background.dart';

/// Placeholder destination for the Household role. Replace with the real
/// Household Sign Up flow when that screen's design is approved.
class HouseholdSignUpScreen extends StatelessWidget {
  const HouseholdSignUpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: AnimatedBackdrop()),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    alignment: Alignment.centerLeft,
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.navy),
                  ),
                  const Spacer(),
                  const Icon(Icons.home_rounded, color: AppColors.orange, size: 64),
                  const SizedBox(height: 16),
                  const Text('Household Sign Up', style: TextStyle(color: AppColors.navy, fontSize: 24, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  const Text('Coming soon.', style: TextStyle(color: AppColors.inkMuted, fontSize: 15)),
                  const Spacer(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
