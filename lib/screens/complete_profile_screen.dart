import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../widgets/animated_background.dart';

/// Destination shown right after a Worker verifies their OTP. Collects
/// Skills, Experience, Expected Wage, Availability and Working Radius.
/// Replace with the real Complete Profile design when it is approved —
/// this placeholder exists only so the sign-up flow has somewhere to land.
class CompleteProfileScreen extends StatelessWidget {
  const CompleteProfileScreen(
      {super.key, required this.fullName, this.role = 'worker'});

  final String fullName;

  /// `'worker'` or `'household'`. Only changes the copy shown below —
  /// both roles land on the same placeholder until each role's real
  /// Complete Profile design is approved.
  final String role;

  @override
  Widget build(BuildContext context) {
    final isHousehold = role == 'household';
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
                  Icon(
                    isHousehold
                        ? Icons.home_rounded
                        : Icons.assignment_turned_in_rounded,
                    color: AppColors.blue,
                    size: 64,
                  ),
                  const SizedBox(height: 16),
                  Text('Welcome, $fullName!',
                      style: const TextStyle(
                          color: AppColors.navy,
                          fontSize: 22,
                          fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  Text(
                    isHousehold
                        ? 'Next, tell us about your home and the kind of help\nyou\'re usually looking for.'
                        : 'Next, tell us about your skills, experience, expected wage,\navailability and working radius.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: AppColors.inkMuted, fontSize: 15, height: 1.4),
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
