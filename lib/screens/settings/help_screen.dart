import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/app_colors.dart';

/// Help & Support screen.
///
/// Displays FAQs, support email and phone. Email and phone are copyable
/// via Clipboard (no url_launcher dependency required).
class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  static const _supportEmail = 'support@kaamsetu.in';
  static const _supportPhone = '+91 98765 43210';

  static const _faqs = [
    _FaqItem(
      question: 'How do I apply for a job?',
      answer:
          'Browse jobs on the Marketplace tab. Tap a job card to view details, then tap "Apply Now" to submit your application.',
    ),
    _FaqItem(
      question: 'How do I improve my profile completion?',
      answer:
          'Go to My Profile → Edit Profile and fill in all sections: Skills, Experience, Availability, Languages, Working Radius, and Expected Daily Wage.',
    ),
    _FaqItem(
      question: 'When will I get paid?',
      answer:
          'Payment terms are agreed upon directly between you and the household. KaamSetu facilitates the connection but does not process payments at this time.',
    ),
    _FaqItem(
      question: 'Can I change my phone number?',
      answer:
          'Phone number is linked to your login and cannot be changed from the app. Contact support if you need to update it.',
    ),
    _FaqItem(
      question: 'How do I withdraw a job application?',
      answer:
          'Go to the Applications tab, find the job, and use the withdraw option. This is only available while the application is still pending.',
    ),
    _FaqItem(
      question: 'Will my profile photo be visible to households?',
      answer:
          'Yes. Your profile photo is visible to households when they view your application or profile.',
    ),
  ];

  void _copy(BuildContext context, String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.navy,
      content: Text('$label copied to clipboard',
          style: const TextStyle(fontWeight: FontWeight.w600)),
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
        title: const Text('Help & Support',
            style: TextStyle(
                color: AppColors.navy, fontWeight: FontWeight.w800)),
        iconTheme: const IconThemeData(color: AppColors.navy),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            // Contact cards
            _ContactCard(
              icon: Icons.email_rounded,
              label: 'Email Support',
              value: _supportEmail,
              onTap: () => _copy(context, _supportEmail, 'Email'),
            ),
            const SizedBox(height: 12),
            _ContactCard(
              icon: Icons.phone_rounded,
              label: 'Call Support',
              value: _supportPhone,
              onTap: () => _copy(context, _supportPhone, 'Phone'),
            ),
            const SizedBox(height: 28),
            const Text('Frequently Asked Questions',
                style: TextStyle(
                    color: AppColors.navy,
                    fontSize: 16,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 14),
            for (final faq in _faqs) ...[
              _FaqCard(item: faq),
              const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  const _ContactCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                    color: AppColors.paleBlue, shape: BoxShape.circle),
                child: Icon(icon, color: AppColors.blue, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: const TextStyle(
                            color: AppColors.navy,
                            fontSize: 13,
                            fontWeight: FontWeight.w800)),
                    const SizedBox(height: 2),
                    Text(value,
                        style: const TextStyle(
                            color: AppColors.inkMuted,
                            fontSize: 13,
                            fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              const Icon(Icons.copy_rounded,
                  color: AppColors.inkMuted, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

class _FaqCard extends StatefulWidget {
  const _FaqCard({required this.item});
  final _FaqItem item;

  @override
  State<_FaqCard> createState() => _FaqCardState();
}

class _FaqCardState extends State<_FaqCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () => setState(() => _expanded = !_expanded),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(widget.item.question,
                        style: const TextStyle(
                            color: AppColors.navy,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800)),
                  ),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: AppColors.inkMuted,
                  ),
                ],
              ),
              if (_expanded) ...[
                const SizedBox(height: 10),
                Text(widget.item.answer,
                    style: const TextStyle(
                        color: AppColors.inkMuted,
                        fontSize: 13,
                        height: 1.5,
                        fontWeight: FontWeight.w500)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _FaqItem {
  const _FaqItem({required this.question, required this.answer});
  final String question;
  final String answer;
}
