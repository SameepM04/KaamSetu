import 'package:flutter/material.dart';

import '../../animations/page_transition.dart';
import '../../services/worker_auth_service.dart';
import '../../theme/app_colors.dart';
import '../login_screen.dart';

/// Shared placeholder destination for every Profile section card (Skills,
/// Experience, Preferred Categories, Availability, Working Radius, Expected
/// Daily Wage, Languages Known, Portfolio, Ratings & Reviews, Settings).
///
/// Only navigation is wired up in this pass — the real editing UI for each
/// section is intentionally out of scope and will replace this screen
/// section-by-section in a later pass. Keeping a single reusable screen
/// (parameterised by [title]/[icon]/[description]) avoids ten near-identical
/// placeholder files that would all need to be deleted later anyway.
///
/// [showLogout], set only for the Settings card, adds a Log Out action —
/// the app's only sign-out entry point. It clears the current session
/// (Fake OTP or Firebase, whichever is active — see
/// [WorkerAuthService.signOut]) and returns to the Login screen, clearing
/// the navigation stack behind it exactly like a production sign-out would.
class ProfileSectionEditScreen extends StatelessWidget {
  const ProfileSectionEditScreen({
    super.key,
    required this.title,
    required this.icon,
    this.description,
    this.showLogout = false,
  });

  final String title;
  final IconData icon;
  final String? description;
  final bool showLogout;

  static final _authService = WorkerAuthService();

  Future<void> _logout(BuildContext context) async {
    await _authService.signOut();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      premiumPageRoute(const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.mist,
      appBar: AppBar(
        backgroundColor: AppColors.mist,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(title,
            style: const TextStyle(
                color: AppColors.navy, fontWeight: FontWeight.w800)),
        iconTheme: const IconThemeData(color: AppColors.navy),
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 84,
                  height: 84,
                  decoration: const BoxDecoration(
                      color: AppColors.paleBlue, shape: BoxShape.circle),
                  child: Icon(icon, color: AppColors.blue, size: 38),
                ),
                const SizedBox(height: 20),
                Text('$title — coming soon',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: AppColors.navy,
                        fontSize: 17,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                Text(
                  description ??
                      'Editing for this section will be available in an upcoming update.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: AppColors.inkMuted,
                      fontSize: 13.5,
                      height: 1.4,
                      fontWeight: FontWeight.w500),
                ),
                if (showLogout) ...[
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    child: GestureDetector(
                      onTap: () => _logout(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.line),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.logout_rounded,
                                color: Colors.redAccent, size: 18),
                            SizedBox(width: 8),
                            Text('Log Out',
                                style: TextStyle(
                                    color: Colors.redAccent,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
