import 'dart:async';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../animations/page_transition.dart';
import '../services/worker_auth_service.dart';
import '../theme/app_colors.dart';
import '../widgets/animated_background.dart';
import '../widgets/brand_logo.dart';
import '../widgets/otp_field_row.dart';
import '../widgets/profile_photo_sheet.dart';
import 'complete_profile_screen.dart';

/// OTP Verification screen — matches the approved design exactly. Verifies
/// the code against Firebase Phone Auth and, on success, creates the
/// worker's account + Firestore document, then navigates to Complete Profile.
class OtpVerificationScreen extends StatefulWidget {
  const OtpVerificationScreen({
    super.key,
    required this.verificationId,
    required this.phoneNumber,
    required this.fullName,
    this.selectedAvatar,
    this.galleryImage,
  });

  final String verificationId;
  final String phoneNumber;
  final String fullName;
  final ProfilePhotoAvatar? selectedAvatar;
  final File? galleryImage;

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final _authService = WorkerAuthService();
  final _otpKey = GlobalKey<OtpFieldRowState>();

  late String _verificationId = widget.verificationId;
  String _code = '';
  bool _verifying = false;
  String? _error;

  Timer? _resendTimer;
  int _secondsLeft = 45;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    super.dispose();
  }

  void _startResendTimer() {
    _resendTimer?.cancel();
    setState(() => _secondsLeft = 45);
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft <= 1) {
        timer.cancel();
        setState(() => _secondsLeft = 0);
      } else {
        setState(() => _secondsLeft -= 1);
      }
    });
  }

  Future<void> _resend() async {
    if (_secondsLeft > 0) return;
    setState(() => _error = null);
    await _authService.sendOtp(
      phoneNumber: widget.phoneNumber,
      onCodeSent: (verificationId) {
        if (!mounted) return;
        setState(() => _verificationId = verificationId);
        _startResendTimer();
      },
      onFailed: (e) {
        if (!mounted) return;
        setState(() => _error = e.message ?? 'Could not resend OTP.');
      },
      onAutoVerified: (_) {},
    );
  }

  Future<void> _verify([String? code]) async {
    final otp = code ?? _code;
    if (otp.length != 6 || _verifying) return;
    setState(() {
      _verifying = true;
      _error = null;
    });
    try {
      await _authService.verifyOtpAndCreateWorker(
        verificationId: _verificationId,
        smsCode: otp,
        fullName: widget.fullName,
        phoneNumber: widget.phoneNumber,
        selectedAvatar: widget.selectedAvatar,
        galleryImage: widget.galleryImage,
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        premiumPageRoute(CompleteProfileScreen(fullName: widget.fullName)),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _verifying = false;
        _error = e.code == 'invalid-verification-code'
            ? 'Incorrect OTP. Please try again.'
            : (e.message ?? 'Verification failed. Please try again.');
      });
      _otpKey.currentState?.clear();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _verifying = false;
        _error = 'Something went wrong. Please try again.';
      });
    }
  }

  String get _formattedTimer {
    final m = (_secondsLeft ~/ 60).toString().padLeft(2, '0');
    final s = (_secondsLeft % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: AnimatedBackdrop(showAccentParticle: false)),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _BackButton(onTap: () => Navigator.of(context).maybePop()),
                  const SizedBox(height: 4),
                  const Center(child: KaamSetuBrand(compact: true)),
                  const SizedBox(height: 22),
                  RichText(
                    text: const TextSpan(
                      style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, height: 1.1, letterSpacing: -.5),
                      children: [
                        TextSpan(text: 'Verify Your\n', style: TextStyle(color: AppColors.navy)),
                        TextSpan(text: 'Mobile Number', style: TextStyle(color: AppColors.blue)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(color: AppColors.inkMuted, fontSize: 15, height: 1.4),
                      children: [
                        const TextSpan(text: "We've sent a 6-digit OTP to\n"),
                        TextSpan(text: widget.phoneNumber, style: const TextStyle(color: AppColors.blue, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 22),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: const [BoxShadow(color: Color(0x184775B4), blurRadius: 26, offset: Offset(0, 14))],
                    ),
                    child: Column(
                      children: [
                        const Text('Enter the 6-digit OTP',
                            style: TextStyle(color: AppColors.navy, fontSize: 17, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 6),
                        RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            style: const TextStyle(color: AppColors.inkMuted, fontSize: 13.5),
                            children: [
                              const TextSpan(text: 'Enter the code sent to '),
                              TextSpan(text: widget.phoneNumber, style: const TextStyle(color: AppColors.blue, fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 22),
                        OtpFieldRow(
                          key: _otpKey,
                          length: 6,
                          onChanged: (v) => setState(() {
                            _code = v;
                            _error = null;
                          }),
                          onCompleted: _verify,
                        ),
                        if (_error != null) ...[
                          const SizedBox(height: 12),
                          Text(_error!, style: TextStyle(color: Colors.red.shade400, fontSize: 13)),
                        ],
                        const SizedBox(height: 20),
                        Text("Didn't receive the code?", style: const TextStyle(color: AppColors.inkMuted, fontSize: 14)),
                        const SizedBox(height: 4),
                        GestureDetector(
                          onTap: _resend,
                          child: RichText(
                            text: TextSpan(
                              style: const TextStyle(color: AppColors.inkMuted, fontSize: 14.5),
                              children: [
                                TextSpan(text: _secondsLeft > 0 ? 'Resend OTP in ' : 'Resend OTP'),
                                if (_secondsLeft > 0)
                                  TextSpan(text: _formattedTimer, style: const TextStyle(color: AppColors.blue, fontWeight: FontWeight.w800)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 22),
                        _VerifyButton(
                          enabled: _code.length == 6 && !_verifying,
                          submitting: _verifying,
                          onTap: () => _verify(),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.verified_user_rounded, color: AppColors.blue, size: 16),
                            SizedBox(width: 6),
                            Text('Your info is secure with us.', style: TextStyle(color: AppColors.inkMuted, fontSize: 13)),
                          ],
                        ),
                      ],
                    ),
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

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 2,
      shadowColor: const Color(0x224775B4),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: const Padding(
          padding: EdgeInsets.all(10),
          child: Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.navy, size: 18),
        ),
      ),
    );
  }
}

class _VerifyButton extends StatefulWidget {
  const _VerifyButton({required this.enabled, required this.submitting, required this.onTap});

  final bool enabled;
  final bool submitting;
  final VoidCallback onTap;

  @override
  State<_VerifyButton> createState() => _VerifyButtonState();
}

class _VerifyButtonState extends State<_VerifyButton> with SingleTickerProviderStateMixin {
  late final AnimationController _tap =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 120), value: 1, lowerBound: .96, upperBound: 1);

  @override
  void dispose() {
    _tap.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.enabled ? (_) => _tap.animateTo(.96) : null,
      onTapUp: widget.enabled ? (_) => _tap.animateTo(1) : null,
      onTapCancel: widget.enabled ? () => _tap.animateTo(1) : null,
      onTap: widget.enabled ? widget.onTap : null,
      child: ScaleTransition(
        scale: _tap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 17),
          decoration: BoxDecoration(
            gradient: widget.enabled
                ? const LinearGradient(colors: [AppColors.blue, AppColors.electricBlue])
                : LinearGradient(colors: [AppColors.line, AppColors.line.withValues(alpha: .8)]),
            borderRadius: BorderRadius.circular(18),
            boxShadow: widget.enabled
                ? [const BoxShadow(color: Color(0x554775F0), blurRadius: 20, offset: Offset(0, 10))]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.submitting)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2.4, valueColor: AlwaysStoppedAnimation(Colors.white)),
                )
              else ...[
                Text('Verify OTP',
                    style: TextStyle(color: widget.enabled ? Colors.white : AppColors.inkMuted, fontSize: 16, fontWeight: FontWeight.w800)),
                const SizedBox(width: 10),
                CircleAvatar(
                  radius: 12,
                  backgroundColor: Colors.white.withValues(alpha: widget.enabled ? .25 : 0),
                  child: Icon(Icons.arrow_forward_rounded, color: widget.enabled ? Colors.white : AppColors.inkMuted, size: 15),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
