import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/worker_auth_service.dart';
import '../theme/app_colors.dart';
import '../widgets/animated_background.dart';
import '../widgets/brand_logo.dart';
import 'otp_verification_screen.dart';
import '../animations/page_transition.dart';

/// Login screen — Firebase Phone Authentication only (mobile number + Send
/// OTP), matching the same visual language as Sign Up / OTP screens.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneController = TextEditingController();
  final _authService = WorkerAuthService();
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _phoneController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  bool get _isPhoneValid => RegExp(r'^[6-9]\d{9}$').hasMatch(_phoneController.text.trim());

  Future<void> _sendOtp() async {
    if (!_isPhoneValid || _submitting) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    final e164Phone = '+91${_phoneController.text.trim()}';
    try {
      await _authService.sendOtp(
        phoneNumber: e164Phone,
        onCodeSent: (verificationId) {
          if (!mounted) return;
          setState(() => _submitting = false);
          Navigator.of(context).push(premiumPageRoute(
            OtpVerificationScreen(
              verificationId: verificationId,
              phoneNumber: e164Phone,
              fullName: '',
            ),
          ));
        },
        onFailed: (e) {
          if (!mounted) return;
          setState(() {
            _submitting = false;
            _error = e.message ?? 'Could not send OTP. Please try again.';
          });
        },
        onAutoVerified: (_) {},
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = 'Something went wrong. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final phoneTouched = _phoneController.text.isNotEmpty;
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
                  Material(
                    color: Colors.white,
                    shape: const CircleBorder(),
                    elevation: 2,
                    shadowColor: const Color(0x224775B4),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => Navigator.of(context).maybePop(),
                      child: const Padding(
                        padding: EdgeInsets.all(10),
                        child: Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.navy, size: 18),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Center(child: KaamSetuBrand(compact: true)),
                  const SizedBox(height: 28),
                  const Text('Welcome Back',
                      style: TextStyle(color: AppColors.navy, fontSize: 27, fontWeight: FontWeight.w800, letterSpacing: -.5)),
                  const SizedBox(height: 8),
                  const Text('Log in with your mobile number to continue.',
                      style: TextStyle(color: AppColors.inkMuted, fontSize: 15, height: 1.4)),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: const [BoxShadow(color: Color(0x184775B4), blurRadius: 26, offset: Offset(0, 14))],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
                          style: const TextStyle(color: AppColors.navy, fontSize: 15, fontWeight: FontWeight.w600),
                          decoration: InputDecoration(
                            hintText: 'Mobile Number',
                            hintStyle: const TextStyle(color: AppColors.inkMuted, fontWeight: FontWeight.w400),
                            prefixIconConstraints: const BoxConstraints(minWidth: 0),
                            prefixIcon: const Padding(
                              padding: EdgeInsets.only(left: 16, right: 8),
                              child: Icon(Icons.call_outlined, color: AppColors.inkMuted, size: 20),
                            ),
                            prefix: const Padding(
                              padding: EdgeInsets.only(right: 8),
                              child: Text('+91  |  ', style: TextStyle(color: AppColors.blue, fontWeight: FontWeight.w700, fontSize: 15)),
                            ),
                            filled: true,
                            fillColor: AppColors.mist,
                            contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.line, width: 1.4)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: (phoneTouched && !_isPhoneValid) ? Colors.red.shade300 : AppColors.line, width: 1.4)),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.blue, width: 2)),
                          ),
                        ),
                        if ((phoneTouched && !_isPhoneValid) || _error != null) ...[
                          const SizedBox(height: 6),
                          Padding(
                            padding: const EdgeInsets.only(left: 4),
                            child: Text(
                              _error ?? 'Enter a valid 10-digit Indian mobile number',
                              style: TextStyle(color: Colors.red.shade400, fontSize: 12.5),
                            ),
                          ),
                        ],
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: GestureDetector(
                            onTap: (_isPhoneValid && !_submitting) ? _sendOtp : null,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(vertical: 17),
                              decoration: BoxDecoration(
                                gradient: (_isPhoneValid && !_submitting)
                                    ? const LinearGradient(colors: [AppColors.blue, AppColors.electricBlue])
                                    : LinearGradient(colors: [AppColors.line, AppColors.line.withValues(alpha: .8)]),
                                borderRadius: BorderRadius.circular(18),
                                boxShadow: (_isPhoneValid && !_submitting)
                                    ? [const BoxShadow(color: Color(0x554775F0), blurRadius: 20, offset: Offset(0, 10))]
                                    : null,
                              ),
                              child: Center(
                                child: _submitting
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(strokeWidth: 2.4, valueColor: AlwaysStoppedAnimation(Colors.white)),
                                      )
                                    : Text('Send OTP',
                                        style: TextStyle(
                                          color: (_isPhoneValid && !_submitting) ? Colors.white : AppColors.inkMuted,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                        )),
                              ),
                            ),
                          ),
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
