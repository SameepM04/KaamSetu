import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// Privacy Policy screen — read-only scrollable content.
class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.mist,
      appBar: AppBar(
        backgroundColor: AppColors.mist,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text('Privacy Policy',
            style: TextStyle(
                color: AppColors.navy, fontWeight: FontWeight.w800)),
        iconTheme: const IconThemeData(color: AppColors.navy),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
          children: const [
            _PolicySection(
              title: 'Introduction',
              body:
                  'KaamSetu ("we", "our", or "us") is committed to protecting your privacy. This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you use our mobile application.',
            ),
            _PolicySection(
              title: 'Information We Collect',
              body:
                  'We collect information you provide directly, including:\n\n'
                  '• Name and contact details (phone number)\n'
                  '• Profile photo\n'
                  '• Work skills, experience, and availability\n'
                  '• Location data (working radius preferences)\n'
                  '• Language preferences\n'
                  '• Expected wage information\n\n'
                  'We also collect usage data such as pages viewed and features used to improve the app experience.',
            ),
            _PolicySection(
              title: 'How We Use Your Information',
              body:
                  'We use your information to:\n\n'
                  '• Provide and improve our services\n'
                  '• Connect workers with households\n'
                  '• Personalise job recommendations\n'
                  '• Send service-related communications\n'
                  '• Comply with legal obligations',
            ),
            _PolicySection(
              title: 'Data Storage and Security',
              body:
                  'Your data is stored securely using Google Firebase services. We implement industry-standard security measures including encrypted transmission and access controls. However, no method of electronic transmission is 100% secure.',
            ),
            _PolicySection(
              title: 'Data Sharing',
              body:
                  'We do not sell your personal data. We share your profile information with households who are looking for workers matching your skills. Third-party service providers (Firebase) may access your data only to help us deliver our services.',
            ),
            _PolicySection(
              title: 'Your Rights',
              body:
                  'You have the right to:\n\n'
                  '• Access your personal data\n'
                  '• Request correction of inaccurate data\n'
                  '• Request deletion of your account\n'
                  '• Withdraw consent at any time\n\n'
                  'To exercise these rights, contact us at support@kaamsetu.in.',
            ),
            _PolicySection(
              title: 'Changes to This Policy',
              body:
                  'We may update this Privacy Policy from time to time. We will notify you of significant changes through the app. Your continued use after changes constitutes acceptance of the updated policy.',
            ),
            _PolicySection(
              title: 'Contact Us',
              body:
                  'If you have questions about this Privacy Policy, please contact us at:\n\nEmail: support@kaamsetu.in\nPhone: +91 98765 43210',
            ),
          ],
        ),
      ),
    );
  }
}

class _PolicySection extends StatelessWidget {
  const _PolicySection({required this.title, required this.body});
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  color: AppColors.navy,
                  fontSize: 15,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text(body,
              style: const TextStyle(
                  color: AppColors.inkMuted,
                  fontSize: 13.5,
                  height: 1.6,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
