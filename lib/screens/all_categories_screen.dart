import 'package:flutter/material.dart';

import '../data/job_categories.dart';
import '../theme/app_colors.dart';
import '../widgets/home/category_icon.dart';

/// "All Categories" — reached from Home's "Browse by Skill → See all".
///
/// Shows every [JobCategory] in a clean 2-column grid: rounded icon card +
/// title, nothing else. Tapping a card jumps to the Jobs tab, same as the
/// Home category row and other "See all" actions on this screen.
class AllCategoriesScreen extends StatelessWidget {
  const AllCategoriesScreen({super.key, required this.onSelectCategory});

  /// Called with the tapped category when the caller should open its jobs.
  final ValueChanged<JobCategory> onSelectCategory;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.mist,
      appBar: AppBar(
        backgroundColor: AppColors.mist,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: const BackButton(color: AppColors.navy),
        title: const Text('All Categories',
            style: TextStyle(
                color: AppColors.navy,
                fontSize: 17,
                fontWeight: FontWeight.w800)),
        centerTitle: false,
      ),
      body: SafeArea(
        top: false,
        child: GridView.builder(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          itemCount: JobCategoryMapper.all.length,
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 220,
            mainAxisSpacing: 18,
            crossAxisSpacing: 16,
            mainAxisExtent: 148,
          ),
          itemBuilder: (context, i) {
            final category = JobCategoryMapper.all[i];
            return _AllCategoriesCard(
                category: category,
                onTap: () {
                  onSelectCategory(category);
                  Navigator.of(context).pop();
                });
          },
        ),
      ),
    );
  }
}

class _AllCategoriesCard extends StatefulWidget {
  const _AllCategoriesCard({required this.category, required this.onTap});
  final JobCategory category;
  final VoidCallback onTap;

  @override
  State<_AllCategoriesCard> createState() => _AllCategoriesCardState();
}

class _AllCategoriesCardState extends State<_AllCategoriesCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scale = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 110),
      value: 1,
      lowerBound: .95,
      upperBound: 1);

  @override
  void dispose() {
    _scale.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _scale.animateTo(.95),
      onTapUp: (_) => _scale.animateTo(1),
      onTapCancel: () => _scale.animateTo(1),
      onTap: widget.onTap,
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.line.withValues(alpha: .6)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              JobCategoryIcon(category: widget.category),
              const SizedBox(height: 10),
              Text(
                JobCategoryMapper.displayName(widget.category),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: AppColors.navy,
                    fontSize: 13,
                    fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
