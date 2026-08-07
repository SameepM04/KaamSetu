import 'package:flutter/material.dart';


import '../../animations/page_transition.dart';
import '../../services/local_worker_session.dart';
import '../../services/worker_auth_service.dart';
import '../../theme/app_colors.dart';
import '../login_screen.dart';
import 'about_screen.dart';
import 'help_screen.dart';
import 'privacy_screen.dart';
import 'terms_screen.dart';

/// Settings hub screen.
///
/// Lists all settings categories (Help, Privacy, Terms, About) and handles
/// Logout with a Material confirmation dialog. Logout clears [LocalWorkerSession],
/// calls [WorkerAuthService.signOut()] (which also calls [FirebaseAuth.signOut()]
/// for real accounts), and navigates to [LoginScreen] clearing the entire stack.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static final _authService = WorkerAuthService();

  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log Out?',
            style: TextStyle(
                color: AppColors.navy, fontWeight: FontWeight.w800)),
        content: const Text(
          'You will be signed out and returned to the login screen.',
          style: TextStyle(color: AppColors.inkMuted, height: 1.4),
        ),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel',
                style: TextStyle(
                    color: AppColors.inkMuted, fontWeight: FontWeight.w700)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Log Out',
                style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    // Clear local session cache, then sign out from Firebase (if authenticated).
    LocalWorkerSession.clear();
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
        title: const Text('Settings',
            style: TextStyle(
                color: AppColors.navy, fontWeight: FontWeight.w800)),
        iconTheme: const IconThemeData(color: AppColors.navy),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            _SettingsGroup(
              label: 'Support',
              children: [
                _SettingsTile(
                  icon: Icons.help_rounded,
                  iconColor: AppColors.blue,
                  title: 'Help & Support',
                  subtitle: 'FAQs and contact information',
                  onTap: () => Navigator.of(context)
                      .push(premiumPageRoute(const HelpScreen())),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _SettingsGroup(
              label: 'Legal',
              children: [
                _SettingsTile(
                  icon: Icons.privacy_tip_rounded,
                  iconColor: const Color(0xFF7C5CE0),
                  title: 'Privacy Policy',
                  subtitle: 'How we handle your data',
                  onTap: () => Navigator.of(context)
                      .push(premiumPageRoute(const PrivacyScreen())),
                ),
                _SettingsDivider(),
                _SettingsTile(
                  icon: Icons.description_rounded,
                  iconColor: AppColors.green,
                  title: 'Terms & Conditions',
                  subtitle: 'Rules governing use of KaamSetu',
                  onTap: () => Navigator.of(context)
                      .push(premiumPageRoute(const TermsScreen())),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _SettingsGroup(
              label: 'About',
              children: [
                _SettingsTile(
                  icon: Icons.info_rounded,
                  iconColor: AppColors.orange,
                  title: 'About KaamSetu',
                  subtitle: 'Mission, vision and version info',
                  onTap: () => Navigator.of(context)
                      .push(premiumPageRoute(const AboutScreen())),
                ),
              ],
            ),
            const SizedBox(height: 28),
            _LogoutTile(onTap: () => _confirmLogout(context)),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared tiles
// ---------------------------------------------------------------------------

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.label, required this.children});
  final String label;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(label.toUpperCase(),
              style: const TextStyle(
                  color: AppColors.inkMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2)),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.line),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: .12),
                    shape: BoxShape.circle),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            color: AppColors.navy,
                            fontSize: 14,
                            fontWeight: FontWeight.w800)),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: const TextStyle(
                            color: AppColors.inkMuted,
                            fontSize: 12,
                            fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded,
                  color: AppColors.inkMuted, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: Divider(color: AppColors.line, height: 1),
      );
}

class _LogoutTile extends StatelessWidget {
  const _LogoutTile({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFFFDDDD)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.logout_rounded, color: Colors.redAccent, size: 20),
              SizedBox(width: 10),
              Text('Log Out',
                  style: TextStyle(
                      color: Colors.redAccent,
                      fontSize: 15,
                      fontWeight: FontWeight.w800)),
            ],
          ),
        ),
      ),
    );
  }
}
