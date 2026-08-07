import 'package:flutter/material.dart';

import '../data/job_categories.dart';
import '../repositories/jobs_repository.dart';
import '../theme/app_colors.dart';
import 'applications_screen.dart';
import 'home/worker_home_tab.dart';
import 'jobs_screen.dart';
import 'worker_profile_screen.dart';

/// Root shell for a signed-in Worker: bottom navigation (Home / Jobs /
/// Applications / Profile) driving an [IndexedStack] so each tab keeps its
/// scroll position and state when the user switches away and back.
///
/// Only the Home tab is implemented for real here. The other three are
/// deliberate placeholders — their screens will be built in later passes —
/// but the navigation shell itself is final and shouldn't need to change
/// when they land.
class WorkerHomeScreen extends StatefulWidget {
  const WorkerHomeScreen({super.key});

  @override
  State<WorkerHomeScreen> createState() => _WorkerHomeScreenState();
}

class _WorkerHomeScreenState extends State<WorkerHomeScreen> {
  int _index = 0;
  JobCategory? _selectedJobCategory;

  @override
  void initState() {
    super.initState();
    // Prime the two shared job-state caches once for the whole signed-in
    // experience. Calls from details/cards remain idempotent safeguards.
    JobsRepository.instance.ensureListening();
    JobsRepository.instance.ensureApplicationsListening();
    JobsRepository.instance.ensureJobsListening();
  }

  void _goTo(int index) => setState(() => _index = index);

  /// The single navigation gateway for every category-driven Jobs action.
  void _navigateToJobs(JobCategory? category) {
    setState(() {
      _selectedJobCategory = category;
      _index = 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.mist,
      body: IndexedStack(
        index: _index,
        children: [
          WorkerHomeTab(navigateToJobs: _navigateToJobs),
          JobsScreen(selectedCategory: _selectedJobCategory),
          ApplicationsScreen(onBrowseJobs: () => _navigateToJobs(null)),
          const WorkerProfileScreen(),
        ],
      ),
      bottomNavigationBar: _WorkerBottomNav(index: _index, onChanged: _goTo),
    );
  }
}

class _WorkerBottomNav extends StatelessWidget {
  const _WorkerBottomNav({required this.index, required this.onChanged});

  final int index;
  final ValueChanged<int> onChanged;

  static const _items = [
    (icon: Icons.home_rounded, outline: Icons.home_outlined, label: 'Home'),
    (
      icon: Icons.work_rounded,
      outline: Icons.work_outline_rounded,
      label: 'Jobs'
    ),
    (
      icon: Icons.description_rounded,
      outline: Icons.description_outlined,
      label: 'Applications'
    ),
    (
      icon: Icons.person_rounded,
      outline: Icons.person_outline_rounded,
      label: 'Profile'
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Color(0x1A102A54), blurRadius: 24, offset: Offset(0, -6))
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 62,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              for (var i = 0; i < _items.length; i++)
                _NavButton(
                  icon: i == index ? _items[i].icon : _items[i].outline,
                  label: _items[i].label,
                  selected: i == index,
                  onTap: () => onChanged(i),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatefulWidget {
  const _NavButton(
      {required this.icon,
      required this.label,
      required this.selected,
      required this.onTap});

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_NavButton> createState() => _NavButtonState();
}

class _NavButtonState extends State<_NavButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scale = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      value: 1,
      lowerBound: .88,
      upperBound: 1);

  @override
  void dispose() {
    _scale.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.selected ? AppColors.blue : AppColors.inkMuted;
    return GestureDetector(
      onTapDown: (_) => _scale.animateTo(.88),
      onTapUp: (_) => _scale.animateTo(1),
      onTapCancel: () => _scale.animateTo(1),
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: ScaleTransition(
        scale: _scale,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(widget.icon, color: color, size: 24),
              const SizedBox(height: 3),
              Text(widget.label,
                  style: TextStyle(
                      color: color,
                      fontSize: 10.5,
                      fontWeight:
                          widget.selected ? FontWeight.w800 : FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
  }
}
