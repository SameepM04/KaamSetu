import 'dart:typed_data';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../animations/page_transition.dart';
import '../services/worker_auth_service.dart';
import '../theme/app_colors.dart';
import '../widgets/animated_background.dart';
import '../widgets/brand_logo.dart';
import '../widgets/profile_photo_sheet.dart';
// KaamSetuBrand comes from brand_logo.dart
import 'login_screen.dart';
import 'otp_verification_screen.dart';

/// Worker Sign Up screen — matches the approved design exactly (spacing,
/// colors, fonts, shapes) while being fully interactive: avatar / gallery /
/// camera photo selection, live validation, and real Firebase Phone Auth.
class WorkerSignUpScreen extends StatefulWidget {
  const WorkerSignUpScreen({super.key});

  @override
  State<WorkerSignUpScreen> createState() => _WorkerSignUpScreenState();
}

class _WorkerSignUpScreenState extends State<WorkerSignUpScreen>
    with SingleTickerProviderStateMixin {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _authService = WorkerAuthService();

  ProfilePhotoAvatar? _selectedAvatar;
  Uint8List? _galleryImageBytes;

  late final AnimationController _photoAnim = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 260));

  bool _submitting = false;
  String? _phoneError;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(() => setState(() {}));
    _phoneController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _photoAnim.dispose();
    super.dispose();
  }

  bool get _isNameValid => _nameController.text.trim().isNotEmpty;

  bool get _isPhoneValid =>
      RegExp(r'^[6-9]\d{9}$').hasMatch(_phoneController.text.trim());

  bool get _isFormValid => _isNameValid && _isPhoneValid && !_submitting;

  Future<void> _openPhotoSheet() async {
    final result = await showProfilePhotoSheet(context);
    if (result == null) return;
    setState(() {
      if (result.avatar != null) {
        _selectedAvatar = result.avatar;
        _galleryImageBytes = null;
      } else if (result.imageBytes != null) {
        _galleryImageBytes = result.imageBytes;
        _selectedAvatar = null;
      }
    });
    _photoAnim.forward(from: 0);
  }

  Future<void> _submit() async {
    if (!_isFormValid) return;
    setState(() {
      _submitting = true;
      _phoneError = null;
    });

    final fullName = _nameController.text.trim();
    final rawPhone = _phoneController.text.trim();
    final e164Phone = '+91$rawPhone';

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
              fullName: fullName,
              selectedAvatar: _selectedAvatar,
              galleryImageBytes: _galleryImageBytes,
            ),
          ));
        },
        onFailed: (error) {
          if (!mounted) return;
          setState(() {
            _submitting = false;
            _phoneError =
                error.message ?? 'Could not send OTP. Please try again.';
          });
        },
        onAutoVerified: (credential) async {
          // Instant (SMS-retriever) verification on some Android devices.
          // We still route through the OTP screen's own flow when codeSent
          // fires; this callback is a safety net Firebase requires but the
          // dominant path for this UI is manual 6-digit entry.
        },
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _phoneError = 'Something went wrong. Please try again.';
      });
    }
  }

  void _goToLogin() {
    Navigator.of(context).push(premiumPageRoute(const LoginScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(
              child: AnimatedBackdrop(showAccentParticle: false)),
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
                  const Text(
                    'Create Your Account',
                    style: TextStyle(
                        color: AppColors.navy,
                        fontSize: 27,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -.5),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Join KaamSetu and start finding work near you.',
                    style: TextStyle(
                        color: AppColors.inkMuted, fontSize: 15, height: 1.4),
                  ),
                  const SizedBox(height: 22),
                  _FormCard(
                    nameController: _nameController,
                    phoneController: _phoneController,
                    isNameValid: _isNameValid,
                    isPhoneValid: _isPhoneValid,
                    isFormValid: _isFormValid,
                    submitting: _submitting,
                    phoneError: _phoneError,
                    selectedAvatar: _selectedAvatar,
                    galleryImageBytes: _galleryImageBytes,
                    photoAnim: _photoAnim,
                    onTapPhoto: _openPhotoSheet,
                    onSubmit: _submit,
                  ),
                  const SizedBox(height: 22),
                  Center(
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(
                            color: AppColors.inkMuted, fontSize: 14.5),
                        children: [
                          const TextSpan(text: 'Already have an account? '),
                          TextSpan(
                            text: 'Log In',
                            style: const TextStyle(
                                color: AppColors.blue,
                                fontWeight: FontWeight.w800),
                            recognizer: TapGestureRecognizer()
                              ..onTap = _goToLogin,
                          ),
                        ],
                      ),
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
          child: Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.navy, size: 18),
        ),
      ),
    );
  }
}

class _FormCard extends StatelessWidget {
  const _FormCard({
    required this.nameController,
    required this.phoneController,
    required this.isNameValid,
    required this.isPhoneValid,
    required this.isFormValid,
    required this.submitting,
    required this.phoneError,
    required this.selectedAvatar,
    required this.galleryImageBytes,
    required this.photoAnim,
    required this.onTapPhoto,
    required this.onSubmit,
  });

  final TextEditingController nameController;
  final TextEditingController phoneController;
  final bool isNameValid;
  final bool isPhoneValid;
  final bool isFormValid;
  final bool submitting;
  final String? phoneError;
  final ProfilePhotoAvatar? selectedAvatar;
  final Uint8List? galleryImageBytes;
  final AnimationController photoAnim;
  final VoidCallback onTapPhoto;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final phoneTouched = phoneController.text.isNotEmpty;
    final nameTouched = nameController.text.isNotEmpty;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
              color: Color(0x184775B4), blurRadius: 26, offset: Offset(0, 14))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Text('Profile Photo',
                  style: TextStyle(
                      color: AppColors.navy,
                      fontSize: 15,
                      fontWeight: FontWeight.w800)),
              SizedBox(width: 6),
              Text('(Optional)',
                  style: TextStyle(color: AppColors.inkMuted, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 16),
          Center(
            child: GestureDetector(
              onTap: onTapPhoto,
              child: ScaleTransition(
                scale: Tween(begin: .9, end: 1.0).animate(
                  CurvedAnimation(parent: photoAnim, curve: Curves.easeOutBack),
                ),
                child: _ProfilePhotoCircle(
                    avatar: selectedAvatar, imageBytes: galleryImageBytes),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const _OrDivider(),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _QuickPickTile(
                  label: 'Male Avatar',
                  selected: selectedAvatar == ProfilePhotoAvatar.male,
                  onTap: onTapPhoto,
                  child: ClipOval(
                      child: Image.asset('assets/avatars/male_avatar.png',
                          fit: BoxFit.cover)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _QuickPickTile(
                  label: 'Female Avatar',
                  selected: selectedAvatar == ProfilePhotoAvatar.female,
                  onTap: onTapPhoto,
                  child: ClipOval(
                      child: Image.asset('assets/avatars/female_avatar.png',
                          fit: BoxFit.cover)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _QuickPickTile(
                  label: 'Choose from\nGallery',
                  selected: galleryImageBytes != null,
                  onTap: onTapPhoto,
                  child: const Icon(Icons.image_rounded,
                      color: AppColors.blue, size: 28),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const _OrDivider(),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onTapPhoto,
              icon: const Icon(Icons.camera_alt_rounded, color: AppColors.blue),
              label: const Text('Take Photo',
                  style: TextStyle(
                      color: AppColors.navy, fontWeight: FontWeight.w700)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.line, width: 1.4),
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
          const SizedBox(height: 18),
          _AppTextField(
            controller: nameController,
            hint: 'Full Name',
            icon: Icons.person_outline_rounded,
            errorText:
                nameTouched && !isNameValid ? 'Full name is required' : null,
          ),
          const SizedBox(height: 14),
          _PhoneField(
            controller: phoneController,
            errorText: phoneTouched && !isPhoneValid
                ? 'Enter a valid 10-digit Indian mobile number'
                : phoneError,
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Icon(Icons.verified_user_rounded,
                  color: AppColors.blue, size: 18),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'We will send you a 6-digit OTP to verify your number.',
                  style: TextStyle(
                      color: AppColors.inkMuted, fontSize: 13, height: 1.35),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _CreateAccountButton(
              enabled: isFormValid, submitting: submitting, onTap: onSubmit),
        ],
      ),
    );
  }
}

class _ProfilePhotoCircle extends StatelessWidget {
  const _ProfilePhotoCircle({required this.avatar, required this.imageBytes});

  final ProfilePhotoAvatar? avatar;
  final Uint8List? imageBytes;

  @override
  Widget build(BuildContext context) {
    final hasSelection = avatar != null || imageBytes != null;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 108,
          height: 108,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.paleBlue,
            border: Border.all(
              color: hasSelection ? AppColors.blue : AppColors.line,
              width: hasSelection ? 2 : 1.4,
            ),
            boxShadow: hasSelection
                ? [
                    BoxShadow(
                        color: AppColors.blue.withValues(alpha: .28),
                        blurRadius: 18,
                        spreadRadius: 1)
                  ]
                : null,
          ),
          child: ClipOval(
            child: imageBytes != null
                ? Image.memory(imageBytes!, fit: BoxFit.cover)
                : avatar != null
                    ? Image.asset(
                        avatar == ProfilePhotoAvatar.male
                            ? 'assets/avatars/male_avatar.png'
                            : 'assets/avatars/female_avatar.png',
                        fit: BoxFit.cover,
                      )
                    : const Icon(Icons.person_outline_rounded,
                        color: AppColors.inkMuted, size: 46),
          ),
        ),
        Positioned(
          right: -2,
          bottom: -2,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: AppColors.blue,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                    color: Color(0x334775B4),
                    blurRadius: 8,
                    offset: Offset(0, 3))
              ],
            ),
            child: const Icon(Icons.camera_alt_rounded,
                color: Colors.white, size: 16),
          ),
        ),
      ],
    );
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    return Row(children: const [
      Expanded(child: Divider(color: AppColors.line)),
      Padding(
          padding: EdgeInsets.symmetric(horizontal: 10),
          child: Text('or',
              style: TextStyle(color: AppColors.inkMuted, fontSize: 13))),
      Expanded(child: Divider(color: AppColors.line)),
    ]);
  }
}

class _QuickPickTile extends StatelessWidget {
  const _QuickPickTile(
      {required this.label,
      required this.child,
      required this.selected,
      required this.onTap});

  final String label;
  final Widget child;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
        decoration: BoxDecoration(
          border: Border.all(
              color: selected ? AppColors.blue : AppColors.line,
              width: selected ? 2 : 1.4),
          borderRadius: BorderRadius.circular(16),
          color: selected
              ? AppColors.paleBlue.withValues(alpha: .5)
              : Colors.white,
        ),
        child: Column(
          children: [
            SizedBox(width: 52, height: 52, child: child),
            const SizedBox(height: 8),
            Text(label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: AppColors.navy,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    height: 1.2)),
          ],
        ),
      ),
    );
  }
}

class _AppTextField extends StatelessWidget {
  const _AppTextField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.errorText,
  });

  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          style: const TextStyle(
              color: AppColors.navy, fontSize: 15, fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
                color: AppColors.inkMuted, fontWeight: FontWeight.w400),
            prefixIcon: Icon(icon, color: AppColors.inkMuted, size: 20),
            filled: true,
            fillColor: AppColors.mist,
            contentPadding:
                const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide:
                    const BorderSide(color: AppColors.line, width: 1.4)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                    color: errorText != null
                        ? Colors.red.shade300
                        : AppColors.line,
                    width: 1.4)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppColors.blue, width: 2)),
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(errorText!,
                style: TextStyle(color: Colors.red.shade400, fontSize: 12.5)),
          ),
        ],
      ],
    );
  }
}

class _PhoneField extends StatelessWidget {
  const _PhoneField({required this.controller, this.errorText});

  final TextEditingController controller;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          keyboardType: TextInputType.phone,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(10)
          ],
          style: const TextStyle(
              color: AppColors.navy, fontSize: 15, fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            hintText: 'Mobile Number',
            hintStyle: const TextStyle(
                color: AppColors.inkMuted, fontWeight: FontWeight.w400),
            prefixIcon: const Padding(
              padding: EdgeInsets.only(left: 16, right: 8),
              child: Icon(Icons.call_outlined,
                  color: AppColors.inkMuted, size: 20),
            ),
            prefixIconConstraints: const BoxConstraints(minWidth: 0),
            prefix: const Padding(
              padding: EdgeInsets.only(right: 8),
              child: Text('+91  |  ',
                  style: TextStyle(
                      color: AppColors.blue,
                      fontWeight: FontWeight.w700,
                      fontSize: 15)),
            ),
            filled: true,
            fillColor: AppColors.mist,
            contentPadding:
                const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide:
                    const BorderSide(color: AppColors.line, width: 1.4)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                    color: errorText != null
                        ? Colors.red.shade300
                        : AppColors.line,
                    width: 1.4)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppColors.blue, width: 2)),
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(errorText!,
                style: TextStyle(color: Colors.red.shade400, fontSize: 12.5)),
          ),
        ],
      ],
    );
  }
}

class _CreateAccountButton extends StatefulWidget {
  const _CreateAccountButton(
      {required this.enabled, required this.submitting, required this.onTap});

  final bool enabled;
  final bool submitting;
  final VoidCallback onTap;

  @override
  State<_CreateAccountButton> createState() => _CreateAccountButtonState();
}

class _CreateAccountButtonState extends State<_CreateAccountButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _tap = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      value: 1,
      lowerBound: .96,
      upperBound: 1);

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
                ? const LinearGradient(
                    colors: [AppColors.blue, AppColors.electricBlue])
                : LinearGradient(colors: [
                    AppColors.line,
                    AppColors.line.withValues(alpha: .8)
                  ]),
            borderRadius: BorderRadius.circular(18),
            boxShadow: widget.enabled
                ? [
                    const BoxShadow(
                        color: Color(0x554775F0),
                        blurRadius: 20,
                        offset: Offset(0, 10))
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.submitting)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      valueColor: AlwaysStoppedAnimation(Colors.white)),
                )
              else ...[
                Text('Create Account',
                    style: TextStyle(
                        color:
                            widget.enabled ? Colors.white : AppColors.inkMuted,
                        fontSize: 16,
                        fontWeight: FontWeight.w800)),
                const SizedBox(width: 10),
                CircleAvatar(
                  radius: 12,
                  backgroundColor:
                      Colors.white.withValues(alpha: widget.enabled ? .25 : 0),
                  child: Icon(Icons.arrow_forward_rounded,
                      color: widget.enabled ? Colors.white : AppColors.inkMuted,
                      size: 15),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
