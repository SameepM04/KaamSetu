import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../animations/page_transition.dart';
import '../services/worker_auth_service.dart';
import '../theme/app_colors.dart';
import '../widgets/animated_background.dart';
import '../widgets/household_illustration.dart';
import '../widgets/profile_photo_sheet.dart';
import 'login_screen.dart';
import 'otp_verification_screen.dart';

/// Household Sign Up screen — matches the approved design exactly (spacing,
/// colors, fonts, shapes, illustration) while being fully interactive.
///
/// This reuses the exact same Firebase Phone Authentication service, OTP
/// screen, and profile-photo bottom sheet already built for Worker sign up
/// — nothing Firebase-related is duplicated here. The only Household-
/// specific piece is this screen's layout and passing `role: 'household'`
/// through to the shared service/OTP screen so the account lands in the
/// `households` Firestore collection instead of `workers`.
class HouseholdSignUpScreen extends StatefulWidget {
  const HouseholdSignUpScreen({super.key});

  @override
  State<HouseholdSignUpScreen> createState() => _HouseholdSignUpScreenState();
}

class _HouseholdSignUpScreenState extends State<HouseholdSignUpScreen>
    with SingleTickerProviderStateMixin {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _authService = WorkerAuthService();

  ProfilePhotoAvatar? _selectedAvatar;
  File? _galleryImage;

  late final AnimationController _photoAnim = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 260));

  bool _submitting = false;
  String? _phoneError;

  @override
  void initState() {
    super.initState();
    // Default selection matches the approved design (male avatar pre-checked).
    _selectedAvatar = ProfilePhotoAvatar.male;
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
        _galleryImage = null;
      } else if (result.imageFile != null) {
        _galleryImage = result.imageFile;
        _selectedAvatar = null;
      }
    });
    _photoAnim.forward(from: 0);
  }

  void _selectAvatar(ProfilePhotoAvatar avatar) {
    setState(() {
      _selectedAvatar = avatar;
      _galleryImage = null;
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
              galleryImage: _galleryImage,
              role: 'household',
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
          // Safety-net callback Firebase requires; manual 6-digit entry via
          // the OTP screen is the primary path for this UI, same as Worker.
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
                  const SizedBox(height: 8),
                  const _HeaderRow(),
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
                    galleryImage: _galleryImage,
                    photoAnim: _photoAnim,
                    onTapGallery: _openPhotoSheet,
                    onTapCamera: _openPhotoSheet,
                    onSelectAvatar: _selectAvatar,
                    onSubmit: _submit,
                  ),
                  const SizedBox(height: 18),
                  Center(
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(
                            color: AppColors.inkMuted, fontSize: 14.5),
                        children: [
                          const TextSpan(text: 'Already have an account? '),
                          TextSpan(
                            text: 'Login',
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
                  const SizedBox(height: 10),
                  Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.verified_user_rounded,
                            color: AppColors.blue, size: 15),
                        SizedBox(width: 6),
                        Text('Your information is safe and secure with us.',
                            style: TextStyle(
                                color: AppColors.inkMuted, fontSize: 12.5)),
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
          child: Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.navy, size: 18),
        ),
      ),
    );
  }
}

class _HeaderRow extends StatelessWidget {
  const _HeaderRow();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final illustrationSize = constraints.maxWidth * .34;
      return Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 6,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Welcome!',
                    style: TextStyle(
                        color: AppColors.navy,
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -.5)),
                const Text('Create Your\nAccount',
                    style: TextStyle(
                        color: AppColors.blue,
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        height: 1.08,
                        letterSpacing: -.5)),
                const SizedBox(height: 10),
                const Text(
                  'Join KaamSetu and hire trusted local\nworkers for your daily needs.',
                  style: TextStyle(
                      color: AppColors.inkMuted, fontSize: 13.5, height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 4,
            child: SizedBox(
              height: illustrationSize.clamp(96, 160).toDouble(),
              child: const HouseholdIllustration(),
            ),
          ),
        ],
      );
    });
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
    required this.galleryImage,
    required this.photoAnim,
    required this.onTapGallery,
    required this.onTapCamera,
    required this.onSelectAvatar,
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
  final File? galleryImage;
  final AnimationController photoAnim;
  final VoidCallback onTapGallery;
  final VoidCallback onTapCamera;
  final void Function(ProfilePhotoAvatar) onSelectAvatar;
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
          const Center(
            child: Text('Add Profile',
                style: TextStyle(
                    color: AppColors.navy,
                    fontSize: 18,
                    fontWeight: FontWeight.w800)),
          ),
          const SizedBox(height: 4),
          const Center(
            child: Text('Choose an avatar or upload a photo',
                style: TextStyle(color: AppColors.inkMuted, fontSize: 13)),
          ),
          const SizedBox(height: 18),
          ScaleTransition(
            scale: Tween(begin: .94, end: 1.0).animate(
                CurvedAnimation(parent: photoAnim, curve: Curves.easeOutBack)),
            child: Row(
              children: [
                Expanded(
                  child: _DashedTile(
                    icon: Icons.image_outlined,
                    label: 'Select from\nGallery',
                    onTap: onTapGallery,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _DashedTile(
                    icon: Icons.camera_alt_outlined,
                    label: 'Take\nPhoto',
                    onTap: onTapCamera,
                  ),
                ),
                const _OrPill(),
                Expanded(
                  child: _AvatarTile(
                    assetPath: 'assets/avatars/male_avatar.png',
                    selected: selectedAvatar == ProfilePhotoAvatar.male,
                    onTap: () => onSelectAvatar(ProfilePhotoAvatar.male),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _AvatarTile(
                    assetPath: 'assets/avatars/female_avatar.png',
                    selected: selectedAvatar == ProfilePhotoAvatar.female,
                    onTap: () => onSelectAvatar(ProfilePhotoAvatar.female),
                  ),
                ),
              ],
            ),
          ),
          if (galleryImage != null) ...[
            const SizedBox(height: 14),
            Center(
              child: ClipOval(
                child: Image.file(galleryImage!,
                    width: 64, height: 64, fit: BoxFit.cover),
              ),
            ),
          ],
          const SizedBox(height: 22),
          const Text('Full Name',
              style: TextStyle(
                  color: AppColors.navy,
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          _AppTextField(
            controller: nameController,
            hint: 'Enter your full name',
            icon: Icons.person_outline_rounded,
            errorText:
                nameTouched && !isNameValid ? 'Full name is required' : null,
          ),
          const SizedBox(height: 16),
          const Text('Mobile Number',
              style: TextStyle(
                  color: AppColors.navy,
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          _PhoneField(
            controller: phoneController,
            errorText: phoneTouched && !isPhoneValid
                ? 'Enter a valid 10-digit Indian mobile number'
                : phoneError,
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Icon(Icons.verified_user_rounded,
                  color: AppColors.blue, size: 16),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'We will send a 6-digit OTP to verify your number.',
                  style: TextStyle(
                      color: AppColors.inkMuted, fontSize: 12.5, height: 1.35),
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

class _DashedTile extends StatelessWidget {
  const _DashedTile(
      {required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: CustomPaint(
        painter: _DashedBorderPainter(color: AppColors.line),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: AppColors.blue, size: 24),
              const SizedBox(height: 8),
              Text(label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: AppColors.navy,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      height: 1.2)),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  _DashedBorderPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final rrect =
        RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(14));
    final path = Path()..addRRect(rrect);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    const dashWidth = 4.5;
    const dashSpace = 3.5;
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = distance + dashWidth;
        canvas.drawPath(
            metric.extractPath(
                distance, next.clamp(0, metric.length).toDouble()),
            paint);
        distance = next + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _OrPill extends StatelessWidget {
  const _OrPill();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 1, height: 26, color: AppColors.line),
          Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
                color: AppColors.mist, borderRadius: BorderRadius.circular(10)),
            child: const Text('OR',
                style: TextStyle(
                    color: AppColors.inkMuted,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700)),
          ),
          Container(width: 1, height: 26, color: AppColors.line),
        ],
      ),
    );
  }
}

class _AvatarTile extends StatelessWidget {
  const _AvatarTile(
      {required this.assetPath, required this.selected, required this.onTap});

  final String assetPath;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AspectRatio(
        aspectRatio: 1,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: selected ? AppColors.blue : AppColors.line,
                    width: selected ? 2 : 1.4),
              ),
              clipBehavior: Clip.antiAlias,
              child: Image.asset(assetPath, fit: BoxFit.cover),
            ),
            if (selected)
              Positioned(
                top: -6,
                right: -6,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                      color: AppColors.blue, shape: BoxShape.circle),
                  child: const Icon(Icons.check_rounded,
                      color: Colors.white, size: 12),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _AppTextField extends StatelessWidget {
  const _AppTextField(
      {required this.controller,
      required this.hint,
      required this.icon,
      this.errorText});

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
            prefixIcon: Icon(icon, color: AppColors.blue, size: 20),
            filled: true,
            fillColor: Colors.white,
            contentPadding:
                const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide:
                    const BorderSide(color: AppColors.line, width: 1.4)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                    color: errorText != null
                        ? Colors.red.shade300
                        : AppColors.line,
                    width: 1.4)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
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
    final borderColor =
        errorText != null ? Colors.red.shade300 : AppColors.line;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 52,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: borderColor, width: 1.4),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('+91',
                      style: TextStyle(
                          color: AppColors.navy,
                          fontWeight: FontWeight.w700,
                          fontSize: 15)),
                  SizedBox(width: 4),
                  Icon(Icons.keyboard_arrow_down_rounded,
                      color: AppColors.inkMuted, size: 18),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: SizedBox(
                height: 52,
                child: TextField(
                  controller: controller,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10)
                  ],
                  style: const TextStyle(
                      color: AppColors.navy,
                      fontSize: 15,
                      fontWeight: FontWeight.w600),
                  decoration: InputDecoration(
                    hintText: 'Enter your mobile number',
                    hintStyle: const TextStyle(
                        color: AppColors.inkMuted,
                        fontWeight: FontWeight.w400,
                        fontSize: 13.5),
                    prefixIcon: const Icon(Icons.call_outlined,
                        color: AppColors.blue, size: 18),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: borderColor, width: 1.4)),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: borderColor, width: 1.4)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide:
                            const BorderSide(color: AppColors.blue, width: 2)),
                  ),
                ),
              ),
            ),
          ],
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
