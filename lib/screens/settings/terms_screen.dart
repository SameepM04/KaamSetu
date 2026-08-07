import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// Terms & Conditions screen — read-only scrollable content.
class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.mist,
      appBar: AppBar(
        backgroundColor: AppColors.mist,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text('Terms & Conditions',
            style: TextStyle(
                color: AppColors.navy, fontWeight: FontWeight.w800)),
        iconTheme: const IconThemeData(color: AppColors.navy),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
          children: const [
            _TermsSection(
              title: '1. Acceptance of Terms',
              body:
                  'By downloading or using the KaamSetu application, you agree to be bound by these Terms & Conditions. If you do not agree, please do not use the app.',
            ),
            _TermsSection(
              title: '2. Eligibility',
              body:
                  'You must be at least 18 years of age to use KaamSetu. By using the app, you confirm that you meet this requirement and that the information you provide is accurate.',
            ),
            _TermsSection(
              title: '3. Account Registration',
              body:
                  'You are responsible for maintaining the confidentiality of your account. You agree to provide accurate information during registration and to keep it updated. KaamSetu is not responsible for any loss resulting from unauthorised use of your account.',
            ),
            _TermsSection(
              title: '4. Worker Obligations',
              body:
                  'As a worker registered on KaamSetu, you agree to:\n\n'
                  '• Provide accurate information about your skills and experience\n'
                  '• Respond promptly to job inquiries\n'
                  '• Maintain professional conduct with households\n'
                  '• Honour commitments made through the platform\n'
                  '• Not misrepresent your qualifications or experience',
            ),
            _TermsSection(
              title: '5. Platform Use',
              body:
                  'KaamSetu is a platform that connects workers and households. We do not employ workers directly and are not responsible for the quality, safety, or legality of jobs posted, or the conduct of any user.',
            ),
            _TermsSection(
              title: '6. Prohibited Activities',
              body:
                  'You may not:\n\n'
                  '• Use the app for any unlawful purpose\n'
                  '• Post false or misleading information\n'
                  '• Harass or threaten other users\n'
                  '• Attempt to reverse-engineer or compromise the app\n'
                  '• Use automated bots or scrapers',
            ),
            _TermsSection(
              title: '7. Limitation of Liability',
              body:
                  'KaamSetu is not liable for any indirect, incidental, or consequential damages arising from your use of the platform. Our total liability shall not exceed the amount paid by you to us in the 12 months preceding the claim.',
            ),
            _TermsSection(
              title: '8. Termination',
              body:
                  'We reserve the right to suspend or terminate your account at any time if you violate these Terms or if we believe your use is harmful to the platform or other users.',
            ),
            _TermsSection(
              title: '9. Changes to Terms',
              body:
                  'We may update these Terms at any time. Continued use of the app after changes constitutes your acceptance of the revised Terms. Significant changes will be communicated via the app.',
            ),
            _TermsSection(
              title: '10. Governing Law',
              body:
                  'These Terms are governed by the laws of India. Any disputes shall be subject to the exclusive jurisdiction of the courts of Mumbai, Maharashtra.',
            ),
            _TermsSection(
              title: '11. Contact',
              body:
                  'For questions about these Terms, contact us at:\n\nEmail: legal@kaamsetu.in\nPhone: +91 98765 43210',
            ),
          ],
        ),
      ),
    );
  }
}

class _TermsSection extends StatelessWidget {
  const _TermsSection({required this.title, required this.body});
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
