import 'package:flutter/material.dart';

import '../animations/page_transition.dart';
import '../data/profile_completion.dart';
import '../services/local_worker_session.dart';
import '../services/worker_auth_service.dart';
import '../theme/app_colors.dart';
import '../widgets/home/profile_avatar_editor.dart';
import 'profile/edit_profile_screen.dart';
import 'profile/ratings_screen.dart';
import 'settings/settings_screen.dart';

/// Worker Profile screen (Phase 4 — final structure).
///
/// My Profile
/// ├── Profile Header (photo, name, phone, address)
/// ├── Completion Progress Bar
/// ├── Edit Profile Button  → opens unified [EditProfileScreen]
/// ├── Portfolio Card       → "Coming Soon" SnackBar (no upload)
/// ├── Ratings & Reviews    → [RatingsScreen]
/// └── Settings             → [SettingsScreen]
///
/// All editing of Basic + Professional information lives inside
/// [EditProfileScreen]. There are no standalone section cards pointing to
/// separate edit screens.
class WorkerProfileScreen extends StatefulWidget {
  const WorkerProfileScreen({super.key});

  @override
  State<WorkerProfileScreen> createState() => _WorkerProfileScreenState();
}

class _WorkerProfileScreenState extends State<WorkerProfileScreen> {
  static final _workerService = WorkerAuthService();

  @override
  Widget build(BuildContext context) {
    final uid = _workerService.currentUserId;

    if (uid == null) {
      return _WorkerProfileBody(
        data: LocalWorkerSession.data,
        loading: false,
        hasError: false,
        onEditComplete: () => setState(() {}),
      );
    }

    return StreamBuilder<Map<String, dynamic>>(
      stream: _workerService.workerProfileStream(uid),
      builder: (context, snapshot) {
        final loading =
            snapshot.connectionState == ConnectionState.waiting;
        final hasError = snapshot.hasError;
        final data = snapshot.data ?? const <String, dynamic>{};
        return _WorkerProfileBody(
          data: data,
          loading: loading,
          hasError: hasError,
          onEditComplete: null,
        );
      },
    );
  }
}

class _WorkerProfileBody extends StatefulWidget {
  const _WorkerProfileBody({
    required this.data,
    required this.loading,
    required this.hasError,
    this.onEditComplete,
  });

  final Map<String, dynamic> data;
  final bool loading;
  final bool hasError;
  final VoidCallback? onEditComplete;

  @override
  State<_WorkerProfileBody> createState() => _WorkerProfileBodyState();
}

class _WorkerProfileBodyState extends State<_WorkerProfileBody> {
  bool _errorShown = false;

  @override
  void didUpdateWidget(covariant _WorkerProfileBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.hasError && !_errorShown) {
      _errorShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _showError());
    }
    if (!widget.hasError) _errorShown = false;
  }

  @override
  void initState() {
    super.initState();
    if (widget.hasError) {
      _errorShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _showError());
    }
  }

  void _showError() {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.navy,
        content: Text(
          "Couldn't load your profile. Pull down to try again.",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.mist,
      body: SafeArea(
        bottom: false,
        child: widget.loading
            ? const _ProfileSkeleton()
            : _ProfileContent(data: widget.data, onEditComplete: widget.onEditComplete),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Profile content
// ---------------------------------------------------------------------------

class _ProfileContent extends StatelessWidget {
  const _ProfileContent({required this.data, this.onEditComplete});
  final Map<String, dynamic> data;
  final VoidCallback? onEditComplete;

  @override
  Widget build(BuildContext context) {
    final completion = ProfileCompletion.compute(data);

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ProfileTopBar(),
                const SizedBox(height: 18),
                _ProfileHeaderCard(data: data, completion: completion, onEditComplete: onEditComplete),
                const SizedBox(height: 22),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
          sliver: SliverList.list(children: [
            _PortfolioCard(),
            const SizedBox(height: 12),
            _RatingsCard(),
            const SizedBox(height: 12),
            _SettingsCard(),
            const SizedBox(height: 24),
          ]),
        ),
      ],
    );
  }
}

class _ProfileTopBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(
          child: Text('My Profile',
              style: TextStyle(
                  color: AppColors.navy,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -.4)),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Profile header card
// ---------------------------------------------------------------------------

class _ProfileHeaderCard extends StatelessWidget {
  const _ProfileHeaderCard(
      {required this.data, required this.completion, this.onEditComplete});

  final Map<String, dynamic> data;
  final double completion;
  final VoidCallback? onEditComplete;

  @override
  Widget build(BuildContext context) {
    final fullName = (data['fullName'] as String?)?.trim();
    final name =
        (fullName == null || fullName.isEmpty) ? 'Worker' : fullName;
    final phone = (data['phoneNumber'] as String?)?.trim();
    final address = (data['address'] as String?)?.trim();
    final selectedAvatar = data['selectedAvatar'] as String?;
    final profilePhotoURL = data['profilePhotoURL'] as String?;
    final percent = (completion * 100).round();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.line),
        boxShadow: const [
          BoxShadow(
              color: Color(0x14102A54),
              blurRadius: 18,
              offset: Offset(0, 8))
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ProfileAvatarEditor(
                selectedAvatar: selectedAvatar,
                profilePhotoURL: profilePhotoURL,
                size: 72,
                onPhotoPicked: (bytes) => WorkerAuthService().updateProfilePhoto(bytes),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: AppColors.navy,
                            fontSize: 18,
                            fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.call_rounded,
                            color: AppColors.inkMuted, size: 14),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            (phone == null || phone.isEmpty)
                                ? 'No phone on file'
                                : phone,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: AppColors.inkMuted,
                                fontSize: 13,
                                fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                    if (address != null && address.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          const Icon(Icons.place_rounded,
                              color: AppColors.inkMuted, size: 14),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(address,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    color: AppColors.inkMuted,
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w500)),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _CompletionBar(percent: percent),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () async {
                await Navigator.of(context).push(premiumPageRoute(
                  EditProfileScreen(
                    initialFullName: name == 'Worker' ? '' : name,
                    initialAddress: address ?? '',
                    initialPhoneNumber: phone ?? '',
                    initialSelectedAvatar: selectedAvatar,
                    initialProfilePhotoURL: profilePhotoURL,
                    initialSkills: (data['skills'] as List?)
                            ?.cast<String>() ??
                        const [],
                    initialExperience:
                        data['experienceYears'] as String?,
                    initialCategories:
                        (data['preferredCategories'] as List?)
                                ?.cast<String>() ??
                            const [],
                    initialAvailability:
                        (data['availability'] as List?)
                                ?.cast<String>() ??
                            const [],
                    initialWorkingRadius:
                        ((data['workingRadiusKm'] as num?)
                                    ?.toDouble() ??
                                5)
                            .clamp(5.0, 50.0),
                    initialDailyWage:
                        (data['expectedDailyWage'] as num?)?.toInt(),
                    initialLanguages:
                        (data['languagesKnown'] as List?)
                                ?.cast<String>() ??
                            const [],
                  ),
                ));
                onEditComplete?.call();
              },
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              icon: const Icon(Icons.edit_rounded, size: 18),
              label: const Text('Edit Profile',
                  style: TextStyle(fontWeight: FontWeight.w800)),
            ),
          ),
        ],
      ),
    );
  }
}

class _CompletionBar extends StatelessWidget {
  const _CompletionBar({required this.percent});
  final int percent;

  @override
  Widget build(BuildContext context) {
    final color = percent >= 80
        ? AppColors.green
        : percent >= 40
            ? AppColors.orange
            : AppColors.blue;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Profile Completion',
                style: TextStyle(
                    color: AppColors.navy,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700)),
            Text('$percent%',
                style: TextStyle(
                    color: color,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800)),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: percent / 100,
            minHeight: 8,
            backgroundColor: AppColors.paleBlue,
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Portfolio, Ratings, Settings cards
// ---------------------------------------------------------------------------

class _PortfolioCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(const SnackBar(
              behavior: SnackBarBehavior.floating,
              backgroundColor: AppColors.navy,
              content: Text('Portfolio feature is coming soon.',
                  style: TextStyle(fontWeight: FontWeight.w600)),
            ));
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.line)),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: const BoxDecoration(
                    color: AppColors.paleBlue, shape: BoxShape.circle),
                child: const Icon(Icons.photo_library_rounded,
                    color: AppColors.blue, size: 20),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('Portfolio',
                            style: TextStyle(
                                color: AppColors.navy,
                                fontSize: 14,
                                fontWeight: FontWeight.w800)),
                        SizedBox(width: 8),
                        _ComingSoonBadge(),
                      ],
                    ),
                    SizedBox(height: 2),
                    Text('Showcase your completed work and projects.',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color: AppColors.inkMuted,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded,
                  color: AppColors.inkMuted, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}

class _ComingSoonBadge extends StatelessWidget {
  const _ComingSoonBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
          color: AppColors.orange.withValues(alpha: .12),
          borderRadius: BorderRadius.circular(20)),
      child: const Text('Coming Soon',
          style: TextStyle(
              color: AppColors.orange,
              fontSize: 10,
              fontWeight: FontWeight.w800)),
    );
  }
}

class _RatingsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _SimpleCard(
      icon: Icons.star_rounded,
      iconColor: AppColors.warmGold,
      title: 'Ratings & Reviews',
      subtitle: 'What households say about you',
      onTap: () => Navigator.of(context)
          .push(premiumPageRoute(const RatingsScreen())),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _SimpleCard(
      icon: Icons.settings_rounded,
      iconColor: AppColors.inkMuted,
      title: 'Settings',
      subtitle: 'Help, privacy, terms and logout',
      onTap: () => Navigator.of(context)
          .push(premiumPageRoute(const SettingsScreen())),
    );
  }
}

class _SimpleCard extends StatelessWidget {
  const _SimpleCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.line)),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: .12),
                    shape: BoxShape.circle),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            color: AppColors.navy,
                            fontSize: 14,
                            fontWeight: FontWeight.w800)),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: AppColors.inkMuted,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded,
                  color: AppColors.inkMuted, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Loading skeleton
// ---------------------------------------------------------------------------

class _ProfileSkeleton extends StatefulWidget {
  const _ProfileSkeleton();

  @override
  State<_ProfileSkeleton> createState() => _ProfileSkeletonState();
}

class _ProfileSkeletonState extends State<_ProfileSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1100))
    ..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final opacity = .35 + (_controller.value * .35);
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
          physics: const BouncingScrollPhysics(),
          children: [
            _skeletonBlock(height: 26, width: 140, opacity: opacity),
            const SizedBox(height: 18),
            _skeletonHeaderCard(opacity),
            const SizedBox(height: 22),
            for (var i = 0; i < 3; i++) ...[
              _skeletonRow(opacity),
              const SizedBox(height: 12),
            ],
          ],
        );
      },
    );
  }

  Widget _skeletonHeaderCard(double opacity) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.line)),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _skeletonCircle(72, opacity),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _skeletonBlock(
                        height: 16, width: 120, opacity: opacity),
                    const SizedBox(height: 8),
                    _skeletonBlock(
                        height: 12, width: 160, opacity: opacity),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _skeletonBlock(
              height: 8, width: double.infinity, opacity: opacity),
          const SizedBox(height: 18),
          _skeletonBlock(
              height: 44, width: double.infinity, opacity: opacity),
        ],
      ),
    );
  }

  Widget _skeletonRow(double opacity) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.line)),
      child: Row(
        children: [
          _skeletonCircle(42, opacity),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _skeletonBlock(height: 12, width: 100, opacity: opacity),
                const SizedBox(height: 6),
                _skeletonBlock(height: 10, width: 140, opacity: opacity),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _skeletonCircle(double size, double opacity) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.line.withValues(alpha: opacity)),
      );

  Widget _skeletonBlock(
      {required double height,
      required double width,
      required double opacity}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: height,
        width: width,
        color: AppColors.line.withValues(alpha: opacity),
      ),
    );
  }
}