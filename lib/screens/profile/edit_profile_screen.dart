import 'dart:io' show File, SocketException;

import 'package:firebase_core/firebase_core.dart' show FirebaseException;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:image_cropper/image_cropper.dart';

import '../../data/job_categories.dart';
import '../../services/worker_auth_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/home/worker_profile_avatar.dart';
import '../../widgets/profile_photo_sheet.dart';

// ---------------------------------------------------------------------------
// Constants shared across bottom sheets
// ---------------------------------------------------------------------------

const _skillSuggestions = [
  'Painter',
  'Plumber',
  'Electrician',
  'Carpenter',
  'Cook',
  'House Cleaner',
  'Babysitter',
  'Elder Care',
  'Driver',
  'Gardener',
  'Sweeper',
  'Security Guard',
];

const _experienceOptions = [
  'Fresher',
  'Less than 1 year',
  '1–3 Years',
  '3–5 Years',
  '5–10 Years',
  '10+ Years',
];

const _availabilityOptions = [
  'Immediate',
  'Weekdays',
  'Weekends',
  'Morning',
  'Evening',
];

const _languageOptions = [
  'English',
  'Hindi',
  'Gujarati',
  'Marathi',
  'Tamil',
  'Telugu',
  'Kannada',
  'Malayalam',
  'Punjabi',
];

// ---------------------------------------------------------------------------
// Main screen
// ---------------------------------------------------------------------------

/// Unified Edit Profile screen (Phase 4).
///
/// Contains BOTH Basic Information and Professional Information in a
/// single scrollable form. All professional fields open bottom sheets
/// — no navigation to sub-pages. A single "Save Profile" button at the
/// bottom calls [WorkerAuthService.saveCompleteProfile] exactly once,
/// producing one Firestore document write.
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({
    super.key,
    required this.initialFullName,
    required this.initialAddress,
    required this.initialPhoneNumber,
    this.initialSelectedAvatar,
    this.initialProfilePhotoURL,
    this.initialSkills = const [],
    this.initialExperience,
    this.initialCategories = const [],
    this.initialAvailability = const [],
    this.initialWorkingRadius = 5.0,
    this.initialDailyWage,
    this.initialLanguages = const [],
  });

  // Basic info
  final String initialFullName;
  final String initialAddress;
  final String initialPhoneNumber;
  final String? initialSelectedAvatar;
  final String? initialProfilePhotoURL;

  // Professional info
  final List<String> initialSkills;
  final String? initialExperience;
  final List<String> initialCategories;
  final List<String> initialAvailability;
  final double initialWorkingRadius;
  final int? initialDailyWage;
  final List<String> initialLanguages;

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  static final _workerService = WorkerAuthService();

  // Basic info state
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _addressController;

  // Avatar/photo state
  File? _pendingPhotoFile;
  String? _pendingAvatar; // 'male' | 'female' | null
  bool _pickingPhoto = false;

  // Professional info state (local until Save is pressed)
  late Set<String> _skills;
  late String? _experience;
  late Set<JobCategory> _categories;
  late Set<String> _availability;
  late double _workingRadius;
  late final TextEditingController _wageController;
  late Set<String> _languages;

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialFullName);
    _addressController = TextEditingController(text: widget.initialAddress);

    _skills = {...widget.initialSkills};
    _experience = widget.initialExperience;
    _categories = {
      for (final raw in widget.initialCategories)
        if (JobCategoryMapper.fromStorage(raw) != null)
          JobCategoryMapper.fromStorage(raw)!
    };
    _availability = {...widget.initialAvailability};
    _workingRadius = widget.initialWorkingRadius.clamp(5.0, 50.0);
    _wageController = TextEditingController(
        text: widget.initialDailyWage?.toString() ?? '');
    _languages = {...widget.initialLanguages};
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _wageController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Photo / Avatar picking
  // ---------------------------------------------------------------------------

  Future<void> _pickPhoto() async {
    if (_saving || _pickingPhoto) return;
    setState(() => _pickingPhoto = true);
    try {
      final selection = await showProfilePhotoSheet(context);
      if (selection == null || !mounted) return;

      if (selection.avatar != null) {
        // Avatar selected (male / female) — fix for the previous bug where
        // this branch was silently dropped.
        setState(() {
          _pendingAvatar = selection.avatar!.name; // 'male' or 'female'
          _pendingPhotoFile = null; // clear any pending upload
        });
      } else if (selection.imageFile != null) {
        // Gallery / Camera image — crop before applying.
        final cropped = await ImageCropper().cropImage(
          sourcePath: selection.imageFile!.path,
          aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
          compressQuality: 90,
          uiSettings: [
            AndroidUiSettings(
              toolbarTitle: 'Crop Photo',
              toolbarColor: AppColors.navy,
              toolbarWidgetColor: Colors.white,
              lockAspectRatio: true,
            ),
            IOSUiSettings(
              title: 'Crop Photo',
              aspectRatioLockEnabled: true,
            ),
          ],
        );
        if (cropped != null && mounted) {
          setState(() {
            _pendingPhotoFile = File(cropped.path);
            _pendingAvatar = null; // clear avatar when a real photo is chosen
          });
        }
      }
    } on PlatformException catch (_) {
      _showError('Could not process that image. Please try another one.');
    } catch (_) {
      _showError('Something went wrong picking your photo.');
    } finally {
      if (mounted) setState(() => _pickingPhoto = false);
    }
  }

  // ---------------------------------------------------------------------------
  // Save — ONE repository call → ONE Firestore write
  // ---------------------------------------------------------------------------

  Future<void> _save() async {
    if (_saving) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final wage = int.tryParse(_wageController.text.trim());
    if (wage == null || wage < 100 || wage > 10000) {
      _showError('Expected daily wage must be between ₹100 and ₹10,000.');
      return;
    }

    setState(() => _saving = true);
    try {
      await _workerService.saveCompleteProfile(
        fullName: _nameController.text.trim(),
        address: _addressController.text.trim(),
        selectedAvatar: _pendingAvatar,
        newPhotoFile: _pendingPhotoFile,
        skills: _skills.toList(),
        experience: _experience ?? '',
        preferredCategories:
            _categories.map(JobCategoryMapper.filterValue).toList(),
        availability: _availability.toList(),
        workingRadius: _workingRadius,
        expectedDailyWage: wage,
        languages: _languages.toList(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.green,
          content: Text('Profile saved successfully!',
              style: TextStyle(fontWeight: FontWeight.w700)),
        ));
      Navigator.of(context).pop();
    } on FirebaseException catch (e) {
      _showError(_firebaseMessage(e));
    } on SocketException catch (_) {
      _showError('No internet connection. Please try again.');
    } catch (_) {
      _showError('Could not save your changes. Please try again.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _firebaseMessage(FirebaseException e) => switch (e.code) {
        'permission-denied' =>
          "You don't have permission to update this profile.",
        'unavailable' => 'Service is unavailable right now. Try again later.',
        'canceled' => 'Upload was cancelled.',
        _ => 'Could not save your changes. Please try again.',
      };

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.navy,
        content: Text(message,
            style: const TextStyle(fontWeight: FontWeight.w600)),
      ));
  }

  // ---------------------------------------------------------------------------
  // Bottom sheets
  // ---------------------------------------------------------------------------

  Future<void> _openSkillsSheet() async {
    final result = await showModalBottomSheet<Set<String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SkillsSheet(selected: Set.from(_skills)),
    );
    if (result != null && mounted) setState(() => _skills = result);
  }

  Future<void> _openExperienceSheet() async {
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ExperienceSheet(selected: _experience),
    );
    if (result != null && mounted) setState(() => _experience = result);
  }

  Future<void> _openCategoriesSheet() async {
    final result = await showModalBottomSheet<Set<JobCategory>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CategoriesSheet(selected: Set.from(_categories)),
    );
    if (result != null && mounted) setState(() => _categories = result);
  }

  Future<void> _openAvailabilitySheet() async {
    final result = await showModalBottomSheet<Set<String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AvailabilitySheet(selected: Set.from(_availability)),
    );
    if (result != null && mounted) setState(() => _availability = result);
  }

  Future<void> _openRadiusSheet() async {
    final result = await showModalBottomSheet<double>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _WorkingRadiusSheet(value: _workingRadius),
    );
    if (result != null && mounted) setState(() => _workingRadius = result);
  }

  Future<void> _openWageSheet() async {
    final result = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _WageSheet(
          current: int.tryParse(_wageController.text.trim()) ?? 800),
    );
    if (result != null && mounted) {
      setState(() => _wageController.text = result.toString());
    }
  }

  Future<void> _openLanguagesSheet() async {
    final result = await showModalBottomSheet<Set<String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _LanguagesSheet(selected: Set.from(_languages)),
    );
    if (result != null && mounted) setState(() => _languages = result);
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    // Determine displayed avatar: pending pick overrides initial values
    final displayAvatar = _pendingAvatar ?? widget.initialSelectedAvatar;
    final displayPhotoURL =
        _pendingPhotoFile != null ? null : widget.initialProfilePhotoURL;

    return Scaffold(
      backgroundColor: AppColors.mist,
      appBar: AppBar(
        backgroundColor: AppColors.mist,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text('Edit Profile',
            style: TextStyle(
                color: AppColors.navy, fontWeight: FontWeight.w800)),
        iconTheme: const IconThemeData(color: AppColors.navy),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 110),
            children: [
              // ── Profile Photo ──────────────────────────────────────────
              Center(
                child: _PhotoPicker(
                  pendingFile: _pendingPhotoFile,
                  selectedAvatar: displayAvatar,
                  profilePhotoURL: displayPhotoURL,
                  busy: _pickingPhoto,
                  onTap: _pickPhoto,
                ),
              ),
              const SizedBox(height: 28),

              // ── Basic Information ──────────────────────────────────────
              _SectionHeader(
                  icon: Icons.person_rounded, label: 'Basic Information'),
              const SizedBox(height: 14),
              _FieldLabel('Full Name'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                maxLength: 60,
                decoration: _inputDecoration('Enter your full name'),
                validator: (value) {
                  final v = value?.trim() ?? '';
                  if (v.isEmpty) return 'Full name is required';
                  if (v.length < 2) return 'Minimum 2 characters';
                  return null;
                },
              ),
              const SizedBox(height: 18),
              _FieldLabel('Phone Number'),
              const SizedBox(height: 8),
              TextFormField(
                initialValue: widget.initialPhoneNumber.isEmpty
                    ? 'No phone number on file'
                    : widget.initialPhoneNumber,
                enabled: false,
                decoration: _inputDecoration('').copyWith(
                  filled: true,
                  fillColor: AppColors.paleBlue.withValues(alpha: .5),
                  suffixIcon: const Icon(Icons.lock_rounded,
                      color: AppColors.inkMuted, size: 18),
                ),
              ),
              const SizedBox(height: 18),
              _FieldLabel('Address'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _addressController,
                maxLines: 3,
                maxLength: 250,
                decoration: _inputDecoration('Enter your address'),
                validator: (value) {
                  final v = value?.trim() ?? '';
                  if (v.isEmpty) return 'Address is required';
                  if (v.length < 5) return 'Minimum 5 characters';
                  return null;
                },
              ),
              const SizedBox(height: 28),

              // ── Professional Information ──────────────────────────────
              _SectionHeader(
                  icon: Icons.work_rounded,
                  label: 'Professional Information'),
              const SizedBox(height: 14),

              _ProFieldRow(
                icon: Icons.build_rounded,
                label: 'Skills',
                value: _skills.isEmpty
                    ? 'Tap to select skills'
                    : _skills.join(', '),
                onTap: _openSkillsSheet,
                showChips: _skills.isNotEmpty,
                chips: _skills.take(4).toList(),
              ),
              const SizedBox(height: 12),
              _ProFieldRow(
                icon: Icons.work_history_rounded,
                label: 'Experience',
                value: _experience ?? 'Tap to select experience',
                onTap: _openExperienceSheet,
              ),
              const SizedBox(height: 12),
              _ProFieldRow(
                icon: Icons.category_rounded,
                label: 'Preferred Categories',
                value: _categories.isEmpty
                    ? 'Tap to select categories'
                    : _categories
                        .map(JobCategoryMapper.displayName)
                        .join(', '),
                onTap: _openCategoriesSheet,
                showChips: _categories.isNotEmpty,
                chips: _categories
                    .map(JobCategoryMapper.displayName)
                    .take(4)
                    .toList(),
              ),
              const SizedBox(height: 12),
              _ProFieldRow(
                icon: Icons.event_available_rounded,
                label: 'Availability',
                value: _availability.isEmpty
                    ? 'Tap to select availability'
                    : _availability.join(', '),
                onTap: _openAvailabilitySheet,
                showChips: _availability.isNotEmpty,
                chips: _availability.toList(),
              ),
              const SizedBox(height: 12),
              _ProFieldRow(
                icon: Icons.social_distance_rounded,
                label: 'Working Radius',
                value: '${_workingRadius.round()} km',
                onTap: _openRadiusSheet,
              ),
              const SizedBox(height: 12),
              _ProFieldRow(
                icon: Icons.currency_rupee_rounded,
                label: 'Expected Daily Wage',
                value: _wageController.text.isEmpty
                    ? 'Tap to set daily wage'
                    : '₹${_wageController.text}/day',
                onTap: _openWageSheet,
              ),
              const SizedBox(height: 12),
              _ProFieldRow(
                icon: Icons.translate_rounded,
                label: 'Languages Known',
                value: _languages.isEmpty
                    ? 'Tap to select languages'
                    : _languages.join(', '),
                onTap: _openLanguagesSheet,
                showChips: _languages.isNotEmpty,
                chips: _languages.toList(),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _saving ? null : _save,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.4, color: Colors.white),
                    )
                  : const Text('Save Profile',
                      style: TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 15)),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) => InputDecoration(
        hintText: hint,
        hintStyle:
            const TextStyle(color: AppColors.inkMuted, fontSize: 13.5),
        filled: true,
        fillColor: Colors.white,
        counterStyle:
            const TextStyle(color: AppColors.inkMuted, fontSize: 11),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.blue, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.6),
        ),
      );
}

// ---------------------------------------------------------------------------
// Shared form widgets
// ---------------------------------------------------------------------------

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: const BoxDecoration(
              color: AppColors.paleBlue, shape: BoxShape.circle),
          child: Icon(icon, color: AppColors.blue, size: 18),
        ),
        const SizedBox(width: 10),
        Text(label,
            style: const TextStyle(
                color: AppColors.navy,
                fontSize: 15,
                fontWeight: FontWeight.w800)),
      ],
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(
          color: AppColors.navy,
          fontSize: 13.5,
          fontWeight: FontWeight.w800));
}

/// A tappable row that displays a professional field's current value and
/// opens a bottom sheet for editing. Never navigates to a sub-page.
class _ProFieldRow extends StatelessWidget {
  const _ProFieldRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
    this.showChips = false,
    this.chips = const [],
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;
  final bool showChips;
  final List<String> chips;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.line),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: const BoxDecoration(
                    color: AppColors.paleBlue, shape: BoxShape.circle),
                child: Icon(icon, color: AppColors.blue, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: const TextStyle(
                            color: AppColors.navy,
                            fontSize: 13,
                            fontWeight: FontWeight.w800)),
                    const SizedBox(height: 3),
                    if (showChips && chips.isNotEmpty)
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          for (final chip in chips)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.paleBlue,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(chip,
                                  style: const TextStyle(
                                      color: AppColors.blue,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700)),
                            ),
                        ],
                      )
                    else
                      Text(value,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              color: value.contains('Tap')
                                  ? AppColors.inkMuted
                                  : AppColors.navy,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.edit_rounded,
                  color: AppColors.inkMuted, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Photo picker widget
// ---------------------------------------------------------------------------

class _PhotoPicker extends StatelessWidget {
  const _PhotoPicker({
    required this.pendingFile,
    required this.selectedAvatar,
    required this.profilePhotoURL,
    required this.busy,
    required this.onTap,
  });

  final File? pendingFile;
  final String? selectedAvatar;
  final String? profilePhotoURL;
  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: busy ? null : onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          if (pendingFile != null)
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: const [
                  BoxShadow(
                      color: Color(0x22102A54),
                      blurRadius: 10,
                      offset: Offset(0, 4))
                ],
              ),
              child: ClipOval(child: Image.file(pendingFile!, fit: BoxFit.cover)),
            )
          else
            WorkerProfileAvatar(
              selectedAvatar: selectedAvatar,
              profilePhotoURL: profilePhotoURL,
              size: 100,
            ),
          Positioned(
            right: -2,
            bottom: -2,
            child: Container(
              width: 34,
              height: 34,
              decoration: const BoxDecoration(
                  color: AppColors.blue,
                  shape: BoxShape.circle,
                  border: Border.fromBorderSide(
                      BorderSide(color: Colors.white, width: 2))),
              child: Center(
                child: busy
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.camera_alt_rounded,
                        color: Colors.white, size: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Bottom Sheets
// ---------------------------------------------------------------------------

/// Shared bottom-sheet container scaffold.
class _SheetContainer extends StatelessWidget {
  const _SheetContainer({
    required this.title,
    required this.child,
    this.onSave,
  });

  final String title;
  final Widget child;
  final VoidCallback? onSave;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: EdgeInsets.fromLTRB(20, 14, 20, 20 + bottomInset),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: const [
            BoxShadow(
                color: Color(0x22102A54),
                blurRadius: 30,
                offset: Offset(0, 12))
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: AppColors.line,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(title,
                      style: const TextStyle(
                          color: AppColors.navy,
                          fontSize: 17,
                          fontWeight: FontWeight.w800)),
                ),
                if (onSave != null)
                  FilledButton(
                    onPressed: onSave,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Done',
                        style: TextStyle(fontWeight: FontWeight.w800)),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

// ── Skills ─────────────────────────────────────────────────────────────────

class _SkillsSheet extends StatefulWidget {
  const _SkillsSheet({required this.selected});
  final Set<String> selected;

  @override
  State<_SkillsSheet> createState() => _SkillsSheetState();
}

class _SkillsSheetState extends State<_SkillsSheet> {
  late Set<String> _selected;
  String _query = '';
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selected = Set.from(widget.selected);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _toggle(String skill) {
    setState(() {
      if (_selected.contains(skill)) {
        _selected.remove(skill);
      } else {
        _selected.add(skill);
      }
    });
  }

  void _addCustom() {
    final v = _searchCtrl.text.trim();
    if (v.isEmpty) return;
    setState(() {
      _selected.add(v);
      _searchCtrl.clear();
      _query = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _skillSuggestions
        .where((s) => s.toLowerCase().contains(_query.toLowerCase()))
        .toList();

    return _SheetContainer(
      title: 'Select Skills',
      onSave: () => Navigator.of(context).pop(_selected),
      child: ConstrainedBox(
        constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * .55),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_selected.isNotEmpty) ...[
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final s in _selected)
                      InputChip(
                        label: Text(s),
                        onDeleted: () => _toggle(s),
                        deleteIconColor: AppColors.blue,
                        backgroundColor: AppColors.paleBlue,
                        labelStyle: const TextStyle(
                            color: AppColors.blue,
                            fontWeight: FontWeight.w700,
                            fontSize: 12.5),
                        side: BorderSide.none,
                      ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
              TextField(
                controller: _searchCtrl,
                onChanged: (v) => setState(() => _query = v),
                onSubmitted: (_) => _addCustom(),
                decoration: InputDecoration(
                  hintText: 'Search or add a skill',
                  hintStyle: const TextStyle(
                      color: AppColors.inkMuted, fontSize: 13.5),
                  filled: true,
                  fillColor: AppColors.mist,
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.add_rounded, color: AppColors.blue),
                    onPressed: _addCustom,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: AppColors.line)),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: AppColors.line)),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                          color: AppColors.blue, width: 1.6)),
                ),
              ),
              if (filtered.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final s in filtered)
                      FilterChip(
                        label: Text(s),
                        selected: _selected.contains(s),
                        onSelected: (_) => _toggle(s),
                        selectedColor: AppColors.paleBlue,
                        checkmarkColor: AppColors.blue,
                        labelStyle: TextStyle(
                            color: _selected.contains(s)
                                ? AppColors.blue
                                : AppColors.navy,
                            fontWeight: FontWeight.w600,
                            fontSize: 12.5),
                        backgroundColor: Colors.white,
                        side: BorderSide(
                            color: _selected.contains(s)
                                ? AppColors.blue
                                : AppColors.line),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── Experience ─────────────────────────────────────────────────────────────

class _ExperienceSheet extends StatefulWidget {
  const _ExperienceSheet({required this.selected});
  final String? selected;

  @override
  State<_ExperienceSheet> createState() => _ExperienceSheetState();
}

class _ExperienceSheetState extends State<_ExperienceSheet> {
  late String? _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.selected;
  }

  @override
  Widget build(BuildContext context) {
    return _SheetContainer(
      title: 'Experience Level',
      onSave: _selected != null
          ? () => Navigator.of(context).pop(_selected)
          : null,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final option in _experienceOptions)
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () {
                  setState(() => _selected = option);
                  Future.delayed(const Duration(milliseconds: 150), () {
                    if (context.mounted) Navigator.of(context).pop(option);
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 4, vertical: 10),
                  child: Row(
                    children: [
                      Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _selected == option
                                ? AppColors.blue
                                : AppColors.line,
                            width: 2,
                          ),
                          color: _selected == option
                              ? AppColors.blue
                              : Colors.transparent,
                        ),
                        child: _selected == option
                            ? const Icon(Icons.check_rounded,
                                color: Colors.white, size: 14)
                            : null,
                      ),
                      const SizedBox(width: 14),
                      Text(option,
                          style: TextStyle(
                              color: _selected == option
                                  ? AppColors.blue
                                  : AppColors.navy,
                              fontWeight: _selected == option
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                              fontSize: 14)),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Preferred Categories ───────────────────────────────────────────────────

class _CategoriesSheet extends StatefulWidget {
  const _CategoriesSheet({required this.selected});
  final Set<JobCategory> selected;

  @override
  State<_CategoriesSheet> createState() => _CategoriesSheetState();
}

class _CategoriesSheetState extends State<_CategoriesSheet> {
  late Set<JobCategory> _selected;

  @override
  void initState() {
    super.initState();
    _selected = Set.from(widget.selected);
  }

  void _toggle(JobCategory cat) => setState(() {
        if (_selected.contains(cat)) {
          _selected.remove(cat);
        } else {
          _selected.add(cat);
        }
      });

  @override
  Widget build(BuildContext context) {
    return _SheetContainer(
      title: 'Preferred Categories',
      onSave: () => Navigator.of(context).pop(_selected),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final cat in JobCategoryMapper.all)
            FilterChip(
              avatar: Icon(Icons.circle,
                  size: 10,
                  color: JobCategoryMapper.accentColor(cat)),
              label: Text(JobCategoryMapper.displayName(cat)),
              selected: _selected.contains(cat),
              onSelected: (_) => _toggle(cat),
              selectedColor: AppColors.paleBlue,
              checkmarkColor: AppColors.blue,
              labelStyle: TextStyle(
                  color: _selected.contains(cat)
                      ? AppColors.blue
                      : AppColors.navy,
                  fontWeight: FontWeight.w700,
                  fontSize: 12.5),
              backgroundColor: Colors.white,
              side: BorderSide(
                  color: _selected.contains(cat)
                      ? AppColors.blue
                      : AppColors.line),
            ),
        ],
      ),
    );
  }
}

// ── Availability ───────────────────────────────────────────────────────────

class _AvailabilitySheet extends StatefulWidget {
  const _AvailabilitySheet({required this.selected});
  final Set<String> selected;

  @override
  State<_AvailabilitySheet> createState() => _AvailabilitySheetState();
}

class _AvailabilitySheetState extends State<_AvailabilitySheet> {
  late Set<String> _selected;

  @override
  void initState() {
    super.initState();
    _selected = Set.from(widget.selected);
  }

  @override
  Widget build(BuildContext context) {
    return _SheetContainer(
      title: 'Availability',
      onSave: () => Navigator.of(context).pop(_selected),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final option in _availabilityOptions)
            CheckboxListTile(
              value: _selected.contains(option),
              title: Text(option,
                  style: const TextStyle(
                      color: AppColors.navy,
                      fontWeight: FontWeight.w600,
                      fontSize: 14)),
              activeColor: AppColors.blue,
              checkColor: Colors.white,
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              onChanged: (checked) => setState(() {
                if (checked == true) {
                  _selected.add(option);
                } else {
                  _selected.remove(option);
                }
              }),
            ),
        ],
      ),
    );
  }
}

// ── Working Radius ─────────────────────────────────────────────────────────

class _WorkingRadiusSheet extends StatefulWidget {
  const _WorkingRadiusSheet({required this.value});
  final double value;

  @override
  State<_WorkingRadiusSheet> createState() => _WorkingRadiusSheetState();
}

class _WorkingRadiusSheetState extends State<_WorkingRadiusSheet> {
  late double _value;

  @override
  void initState() {
    super.initState();
    _value = widget.value;
  }

  @override
  Widget build(BuildContext context) {
    return _SheetContainer(
      title: 'Working Radius',
      onSave: () => Navigator.of(context).pop(_value),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('5 km',
                  style: TextStyle(
                      color: AppColors.inkMuted, fontSize: 12.5)),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                    color: AppColors.paleBlue,
                    borderRadius: BorderRadius.circular(12)),
                child: Text('${_value.round()} km',
                    style: const TextStyle(
                        color: AppColors.blue,
                        fontSize: 18,
                        fontWeight: FontWeight.w800)),
              ),
              const Text('50 km',
                  style: TextStyle(
                      color: AppColors.inkMuted, fontSize: 12.5)),
            ],
          ),
          const SizedBox(height: 8),
          Slider(
            value: _value,
            min: 5,
            max: 50,
            divisions: 45,
            activeColor: AppColors.blue,
            inactiveColor: AppColors.paleBlue,
            onChanged: (v) => setState(() => _value = v),
          ),
          const SizedBox(height: 4),
          Text('You will see jobs within ${_value.round()} km from you.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: AppColors.inkMuted,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

// ── Expected Daily Wage ────────────────────────────────────────────────────

class _WageSheet extends StatefulWidget {
  const _WageSheet({required this.current});
  final int current;

  @override
  State<_WageSheet> createState() => _WageSheetState();
}

class _WageSheetState extends State<_WageSheet> {
  late double _value;
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _value = widget.current.clamp(800, 2500).toDouble();
    _ctrl = TextEditingController(text: widget.current.toString());
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onSliderChange(double v) {
    setState(() {
      _value = v;
      _ctrl.text = v.round().toString();
      _ctrl.selection = TextSelection.collapsed(offset: _ctrl.text.length);
    });
  }

  void _onTextChange(String v) {
    final parsed = int.tryParse(v);
    if (parsed != null && parsed >= 800 && parsed <= 2500) {
      setState(() => _value = parsed.toDouble());
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return _SheetContainer(
      title: 'Expected Daily Wage',
      onSave: () {
        final parsed = int.tryParse(_ctrl.text.trim());
        final finalWage = (parsed != null && parsed >= 100 && parsed <= 10000)
            ? parsed
            : _value.round();
        Navigator.of(context).pop(finalWage);
      },
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomInset > 0 ? 8 : 0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Text('₹',
                    style: TextStyle(
                        color: AppColors.navy,
                        fontSize: 22,
                        fontWeight: FontWeight.w800)),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    keyboardType: TextInputType.number,
                    onChanged: _onTextChange,
                    style: const TextStyle(
                        color: AppColors.navy,
                        fontSize: 22,
                        fontWeight: FontWeight.w800),
                    decoration: InputDecoration(
                      hintText: '800',
                      hintStyle: const TextStyle(
                          color: AppColors.inkMuted, fontSize: 22),
                      suffixText: '/day',
                      suffixStyle: const TextStyle(
                          color: AppColors.inkMuted,
                          fontSize: 16,
                          fontWeight: FontWeight.w500),
                      border: InputBorder.none,
                      filled: true,
                      fillColor: AppColors.paleBlue,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                              color: AppColors.blue, width: 1.6)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text('₹800/day',
                    style: TextStyle(
                        color: AppColors.inkMuted, fontSize: 12)),
                Text('₹2,500/day',
                    style: TextStyle(
                        color: AppColors.inkMuted, fontSize: 12)),
              ],
            ),
            Slider(
              value: _value,
              min: 800,
              max: 2500,
              divisions: 170,
              activeColor: AppColors.blue,
              inactiveColor: AppColors.paleBlue,
              onChanged: _onSliderChange,
            ),
            Text(
              'You can also type any amount between ₹100–₹10,000.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: AppColors.inkMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Languages ──────────────────────────────────────────────────────────────

class _LanguagesSheet extends StatefulWidget {
  const _LanguagesSheet({required this.selected});
  final Set<String> selected;

  @override
  State<_LanguagesSheet> createState() => _LanguagesSheetState();
}

class _LanguagesSheetState extends State<_LanguagesSheet> {
  late Set<String> _selected;

  @override
  void initState() {
    super.initState();
    _selected = Set.from(widget.selected);
  }

  @override
  Widget build(BuildContext context) {
    return _SheetContainer(
      title: 'Languages Known',
      onSave: () => Navigator.of(context).pop(_selected),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final lang in _languageOptions)
            CheckboxListTile(
              value: _selected.contains(lang),
              title: Text(lang,
                  style: const TextStyle(
                      color: AppColors.navy,
                      fontWeight: FontWeight.w600,
                      fontSize: 14)),
              activeColor: AppColors.blue,
              checkColor: Colors.white,
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              onChanged: (checked) => setState(() {
                if (checked == true) {
                  _selected.add(lang);
                } else {
                  _selected.remove(lang);
                }
              }),
            ),
        ],
      ),
    );
  }
}
