import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/app_colors.dart';

/// About KaamSetu screen — logo, version, mission, vision, developer info.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  static const _version = '1.0.0';
  static const _email = 'hello@kaamsetu.in';
  static const _website = 'www.kaamsetu.in';

  void _copyEmail(BuildContext context) {
    Clipboard.setData(const ClipboardData(text: _email));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.navy,
      content: Text('Email address copied',
          style: TextStyle(fontWeight: FontWeight.w600)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.mist,
      appBar: AppBar(
        backgroundColor: AppColors.mist,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text('About KaamSetu',
            style: TextStyle(
                color: AppColors.navy, fontWeight: FontWeight.w800)),
        iconTheme: const IconThemeData(color: AppColors.navy),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
          children: [
            // Logo + brand
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF0B2457), Color(0xFF1463EC)],
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.asset(
                      'assets/branding/kaamsetu_official_logo.png',
                      width: 80,
                      height: 80,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 16),
                  RichText(
                    text: const TextSpan(
                      style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -.6),
                      children: [
                        TextSpan(
                            text: 'Kaam',
                            style: TextStyle(color: Colors.white)),
                        TextSpan(
                            text: 'Setu',
                            style: TextStyle(color: AppColors.warmGold)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text('Bridging Work. Building Trust.',
                      style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w500)),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 5),
                    decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .15),
                        borderRadius: BorderRadius.circular(20)),
                    child: Text('Version $_version',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Mission
            _AboutCard(
              icon: Icons.rocket_launch_rounded,
              iconColor: AppColors.blue,
              title: 'Our Mission',
              body:
                  'To empower India\'s daily wage workers by connecting them directly with households that need their services — quickly, fairly, and with dignity.',
            ),
            const SizedBox(height: 12),

            // Vision
            _AboutCard(
              icon: Icons.visibility_rounded,
              iconColor: AppColors.green,
              title: 'Our Vision',
              body:
                  'A future where every skilled worker in India has equal access to employment opportunities and every household can find trusted, verified help when they need it most.',
            ),
            const SizedBox(height: 12),

            // Developer
            _AboutCard(
              icon: Icons.code_rounded,
              iconColor: AppColors.orange,
              title: 'Built With ♥',
              body:
                  'KaamSetu is built with Flutter and Firebase. We are a passionate team dedicated to creating technology that makes a real difference in people\'s lives.',
            ),
            const SizedBox(height: 24),

            // Action buttons
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _copyEmail(context),
                icon: const Icon(Icons.email_rounded, size: 18),
                label: const Text('Email Us: $_email'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.blue,
                  side: const BorderSide(color: AppColors.blue),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.line),
              ),
              child: Center(
                child: Text(_website,
                    style: const TextStyle(
                        color: AppColors.inkMuted,
                        fontSize: 14,
                        fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AboutCard extends StatelessWidget {
  const _AboutCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
                color: iconColor.withValues(alpha: .12),
                shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: AppColors.navy,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                Text(body,
                    style: const TextStyle(
                        color: AppColors.inkMuted,
                        fontSize: 13,
                        height: 1.5,
                        fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
