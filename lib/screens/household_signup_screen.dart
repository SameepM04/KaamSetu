import 'dart:typed_data';

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
  Uint8List? _galleryImageBytes;

  late final AnimationController _photoAnim = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 260));

  bool _submitting = false;
  String? _phoneError;

  @override
  void initState() {
    super.initState();
    // Default selection: the premium Family avatar (matches the Household
    // "Choose Your Profile" design — family is pre-checked).
    _selectedAvatar = ProfilePhotoAvatar.familyHousehold;
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

  void _selectAvatar(ProfilePhotoAvatar avatar) {
    setState(() {
      _selectedAvatar = avatar;
      _galleryImageBytes = null;
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
                    galleryImageBytes: _galleryImageBytes,
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
                        style: TextStyle(
                            color: AppColors.hint(context), fontSize: 14.5),
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
                      children: [
                        Icon(Icons.verified_user_rounded,
                            color: AppColors.blue, size: 15),
                        SizedBox(width: 6),
                        Text('Your information is safe and secure with us.',
                            style: TextStyle(
                                color: AppColors.hint(context), fontSize: 12.5)),
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
      color: AppColors.surface(context),
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
                Text('Welcome!',
                    style: TextStyle(
                        color: AppColors.label(context),
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
                Text(
                  'Join KaamSetu and hire trusted local\nworkers for your daily needs.',
                  style: TextStyle(
                      color: AppColors.hint(context), fontSize: 13.5, height: 1.4),
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
    required this.galleryImageBytes,
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
  final Uint8List? galleryImageBytes;
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
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
              color: Color(0x184775B4), blurRadius: 26, offset: Offset(0, 14))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Text('Choose Your Profile',
                style: TextStyle(
                    color: AppColors.label(context),
                    fontSize: 18,
                    fontWeight: FontWeight.w800)),
          ),
          const SizedBox(height: 4),
          Center(
            child: Text('Pick a premium avatar or upload your own photo',
                style: TextStyle(color: AppColors.hint(context), fontSize: 13)),
          ),
          const SizedBox(height: 18),
          ScaleTransition(
            scale: Tween(begin: .94, end: 1.0).animate(
                CurvedAnimation(parent: photoAnim, curve: Curves.easeOutBack)),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _PremiumAvatarCard(
                        assetPath:
                            'assets/images/household/male_household.png',
                        heroTag: 'household-avatar-male',
                        label: 'Male',
                        selected:
                            selectedAvatar == ProfilePhotoAvatar.maleHousehold,
                        onTap: () =>
                            onSelectAvatar(ProfilePhotoAvatar.maleHousehold),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _PremiumAvatarCard(
                        assetPath:
                            'assets/images/household/female_household.png',
                        heroTag: 'household-avatar-female',
                        label: 'Female',
                        selected: selectedAvatar ==
                            ProfilePhotoAvatar.femaleHousehold,
                        onTap: () =>
                            onSelectAvatar(ProfilePhotoAvatar.femaleHousehold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(flex: 1, child: const SizedBox()),
                    Expanded(
                      flex: 2,
                      child: _PremiumAvatarCard(
                        assetPath: 'assets/images/household/family_avatar.png',
                        heroTag: 'household-avatar-family',
                        label: 'Family',
                        selected: selectedAvatar ==
                            ProfilePhotoAvatar.familyHousehold,
                        onTap: () =>
                            onSelectAvatar(ProfilePhotoAvatar.familyHousehold),
                      ),
                    ),
                    Expanded(flex: 1, child: const SizedBox()),
                  ],
                ),
                const SizedBox(height: 16),
                Row(children: [
                  Expanded(child: Divider(color: AppColors.line)),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: Text('OR',
                        style: TextStyle(
                            color: AppColors.hint(context),
                            fontSize: 11,
                            fontWeight: FontWeight.w700)),
                  ),
                  Expanded(child: Divider(color: AppColors.line)),
                ]),
                const SizedBox(height: 12),
                Row(
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
                  ],
                ),
              ],
            ),
          ),
          if (galleryImageBytes != null) ...[
            const SizedBox(height: 14),
            Center(
              child: ClipOval(
                child: Image.memory(galleryImageBytes!,
                    width: 64, height: 64, fit: BoxFit.cover),
              ),
            ),
          ],
          const SizedBox(height: 22),
          Text('Full Name',
              style: TextStyle(
                  color: AppColors.label(context),
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
          Text('Mobile Number',
              style: TextStyle(
                  color: AppColors.label(context),
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
            children: [
              Icon(Icons.verified_user_rounded,
                  color: AppColors.blue, size: 16),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'We will send a 6-digit OTP to verify your number.',
                  style: TextStyle(
                      color: AppColors.hint(context), fontSize: 12.5, height: 1.35),
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
                  style: TextStyle(
                      color: AppColors.label(context),
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

/// Premium, tappable avatar card used only by the Household "Choose Your
/// Profile" picker (male / female / family). Material 3 styling with a
/// scale-on-tap animation, ripple feedback, soft shadow, blue selection
/// border + checkmark badge, and a Hero tag so the same image can transition
/// into a profile screen if one is pushed from here.
class _PremiumAvatarCard extends StatefulWidget {
  const _PremiumAvatarCard({
    required this.assetPath,
    required this.heroTag,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String assetPath;
  final String heroTag;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_PremiumAvatarCard> createState() => _PremiumAvatarCardState();
}

class _PremiumAvatarCardState extends State<_PremiumAvatarCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scale = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      value: 1,
      lowerBound: .92,
      upperBound: 1);

  @override
  void dispose() {
    _scale.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _scale.animateTo(.92),
      onTapUp: (_) => _scale.animateTo(1),
      onTapCancel: () => _scale.animateTo(1),
      child: ScaleTransition(
        scale: _scale,
        child: Material(
          color: AppColors.surface(context),
          borderRadius: BorderRadius.circular(20),
          elevation: widget.selected ? 6 : 3,
          shadowColor: const Color(0x334775F0),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: widget.onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: widget.selected ? AppColors.blue : AppColors.border(context),
                  width: widget.selected ? 2.4 : 1.2,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AspectRatio(
                    aspectRatio: 1,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Hero(
                            tag: widget.heroTag,
                            // These premium avatar source PNGs are large,
                            // full-resolution exports (~1254px, ~2MB)
                            // displayed inside a small card (roughly
                            // 130-160dp here). Without cacheWidth/cacheHeight,
                            // Image.asset decodes the full source resolution
                            // on every build; on Android that oversized
                            // decode can get pushed through a lower-quality
                            // mip level under the engine's image-cache
                            // memory pressure, which is what was showing up
                            // as "washed out" avatars there (Flutter Web's
                            // browser-native decode path doesn't hit the
                            // same limit, which is why Chrome looked fine).
                            // Bounding the decode to the actual on-screen
                            // size (scaled for device pixel ratio) fixes
                            // this without touching the Worker avatars,
                            // which use much smaller source files and never
                            // hit this path.
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                final dpr = MediaQuery.of(context)
                                    .devicePixelRatio;
                                final decodeSize =
                                    (constraints.maxWidth * dpr)
                                        .round()
                                        .clamp(1, 2000)
                                        .toInt();
                                return Image.asset(
                                  widget.assetPath,
                                  fit: BoxFit.cover,
                                  cacheWidth: decodeSize,
                                  cacheHeight: decodeSize,
                                );
                              },
                            ),
                          ),
                        ),
                        AnimatedOpacity(
                          duration: const Duration(milliseconds: 200),
                          opacity: widget.selected ? 1 : 0,
                          child: Positioned(
                            top: -6,
                            right: -6,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: AppColors.blue,
                                shape: BoxShape.circle,
                                border:
                                    Border.all(color: AppColors.surface(context), width: 2),
                                boxShadow: const [
                                  BoxShadow(
                                      color: Color(0x554775F0),
                                      blurRadius: 6,
                                      offset: Offset(0, 2)),
                                ],
                              ),
                              child: Icon(Icons.check_rounded,
                                  color: AppColors.surface(context), size: 14),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(widget.label,
                      style: TextStyle(
                          color: widget.selected
                              ? AppColors.blue
                              : AppColors.label(context),
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ),
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
          style: TextStyle(
              color: AppColors.label(context), fontSize: 15, fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
                color: AppColors.hint(context), fontWeight: FontWeight.w400),
            prefixIcon: Icon(icon, color: AppColors.blue, size: 20),
            filled: true,
            fillColor: AppColors.surface(context),
            contentPadding:
                const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide:
                    BorderSide(color: AppColors.border(context), width: 1.4)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                    color: errorText != null
                        ? Colors.red.shade300
                        : AppColors.border(context),
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
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('+91',
                      style: TextStyle(
                          color: AppColors.label(context),
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
                  style: TextStyle(
                      color: AppColors.label(context),
                      fontSize: 15,
                      fontWeight: FontWeight.w600),
                  decoration: InputDecoration(
                    hintText: 'Enter your mobile number',
                    hintStyle: TextStyle(
                        color: AppColors.hint(context),
                        fontWeight: FontWeight.w400,
                        fontSize: 13.5),
                    prefixIcon: const Icon(Icons.call_outlined,
                        color: AppColors.blue, size: 18),
                    filled: true,
                    fillColor: AppColors.surface(context),
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
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      valueColor: AlwaysStoppedAnimation(AppColors.surface(context))),
                )
              else ...[
                Text('Create Account',
                    style: TextStyle(
                        color:
                            widget.enabled ? AppColors.surface(context) : AppColors.hint(context),
                        fontSize: 16,
                        fontWeight: FontWeight.w800)),
                const SizedBox(width: 10),
                CircleAvatar(
                  radius: 12,
                  backgroundColor:
                      AppColors.surface(context).withValues(alpha: widget.enabled ? .25 : 0),
                  child: Icon(Icons.arrow_forward_rounded,
                      color: widget.enabled ? AppColors.surface(context) : AppColors.inkMuted,
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
