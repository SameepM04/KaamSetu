import 'package:flutter/material.dart';

import '../../data/job_categories.dart';
import '../../data/worker_filters.dart';
import '../../theme/app_colors.dart';

/// Opens the Household "Filter Workers" bottom sheet and resolves with the
/// [WorkerFilters] the user applied, or `null` if dismissed without
/// applying.
///
/// Entirely separate component from `widgets/jobs/job_filter_sheet.dart` —
/// that sheet filters job postings for Workers, this one filters worker
/// profiles for Households. Nothing is shared beyond visual styling
/// (colors, spacing, chip/slider shapes) so the two can evolve
/// independently without risk of cross-contamination.
Future<WorkerFilters?> showWorkerFilterSheet(
  BuildContext context,
  WorkerFilters current,
) {
  return showModalBottomSheet<WorkerFilters>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (_) => _WorkerFilterSheet(initial: current),
  );
}

class _WorkerFilterSheet extends StatefulWidget {
  const _WorkerFilterSheet({required this.initial});
  final WorkerFilters initial;

  @override
  State<_WorkerFilterSheet> createState() => _WorkerFilterSheetState();
}

class _WorkerFilterSheetState extends State<_WorkerFilterSheet> {
  late Set<JobCategory> _categories = {...widget.initial.categories};
  late ExperienceTier _experience = widget.initial.experience;
  late double _minRating = widget.initial.minRating;
  late double _maxDistance = widget.initial.maxDistance;
  late Set<String> _availability = {...widget.initial.availability};
  late bool _verifiedOnly = widget.initial.verifiedOnly;

  void _reset() {
    setState(() {
      _categories = {};
      _experience = ExperienceTier.any;
      _minRating = 0;
      _maxDistance = WorkerFilterBounds.maxDistance;
      _availability = {};
      _verifiedOnly = false;
    });
  }

  void _apply() {
    Navigator.of(context).pop(WorkerFilters(
      categories: _categories,
      experience: _experience,
      minRating: _minRating,
      maxDistance: _maxDistance,
      availability: _availability,
      verifiedOnly: _verifiedOnly,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.viewInsetsOf(context);
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(bottom: viewInsets.bottom),
        child: DraggableScrollableSheet(
          initialChildSize: .82,
          minChildSize: .5,
          maxChildSize: .95,
          expand: false,
          builder: (context, scrollController) => Column(
            children: [
              const _SheetHandle(),
              _SheetHeader(onReset: _reset),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                  children: [
                    const _SectionLabel('Work Type'),
                    _WorkTypePicker(
                      selected: _categories,
                      onChanged: (value) =>
                          setState(() => _categories = value),
                    ),
                    const SizedBox(height: 22),
                    const _SectionLabel('Experience'),
                    _ExperiencePicker(
                      selected: _experience,
                      onChanged: (value) =>
                          setState(() => _experience = value),
                    ),
                    const SizedBox(height: 22),
                    const _SectionLabel('Minimum Rating'),
                    _RatingPicker(
                      selected: _minRating,
                      onChanged: (value) => setState(() => _minRating = value),
                    ),
                    const SizedBox(height: 22),
                    const _SectionLabel('Distance'),
                    _DistanceControl(
                      value: _maxDistance,
                      onChanged: (value) =>
                          setState(() => _maxDistance = value),
                    ),
                    const SizedBox(height: 22),
                    const _SectionLabel('Availability'),
                    _MultiChoiceChips(
                      options: kWorkerAvailabilityOptionsList,
                      selected: _availability,
                      onChanged: (value) =>
                          setState(() => _availability = value),
                    ),
                    const SizedBox(height: 8),
                    _ToggleRow(
                      label: 'Verified workers only',
                      value: _verifiedOnly,
                      onChanged: (value) =>
                          setState(() => _verifiedOnly = value),
                    ),
                  ],
                ),
              ),
              _SheetFooter(onApply: _apply),
            ],
          ),
        ),
      ),
    );
  }
}

/// Same worker-availability values already used by the Worker profile form
/// and, previously, by `job_filter_sheet.dart`'s `kWorkerAvailabilityOptions`
/// — kept as a plain list here since this sheet has no other dependency on
/// the Jobs-filter file.
const kWorkerAvailabilityOptionsList = <String>[
  'Full Week',
  'Weekdays',
  'Weekends',
  'Morning Shift',
  'Evening Shift',
];

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 10, bottom: 4),
        child: Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
              color: AppColors.line, borderRadius: BorderRadius.circular(3)),
        ),
      );
}

class _SheetHeader extends StatelessWidget {
  const _SheetHeader({required this.onReset});
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 12, 0),
        child: Row(
          children: [
            const Expanded(
              child: Text('Filter Workers',
                  style: TextStyle(
                      color: AppColors.navy,
                      fontSize: 18,
                      fontWeight: FontWeight.w800)),
            ),
            TextButton(onPressed: onReset, child: const Text('Reset')),
          ],
        ),
      );
}

class _SheetFooter extends StatelessWidget {
  const _SheetFooter({required this.onApply});
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
        child: SizedBox(
          width: double.infinity,
          height: 50,
          child: FilledButton(
            onPressed: onApply,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.blue,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text('Apply Filters',
                style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ),
      );
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);
  final String label;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(label,
            style: const TextStyle(
                color: AppColors.navy,
                fontSize: 13.5,
                fontWeight: FontWeight.w800)),
      );
}

class _WorkTypePicker extends StatelessWidget {
  const _WorkTypePicker({required this.selected, required this.onChanged});
  final Set<JobCategory> selected;
  final ValueChanged<Set<JobCategory>> onChanged;

  @override
  Widget build(BuildContext context) => Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final category in JobCategoryMapper.all)
            FilterChip(
              label: Text(JobCategoryMapper.displayName(category)),
              selected: selected.contains(category),
              onSelected: (isSelected) {
                final next = {...selected};
                if (isSelected) {
                  next.add(category);
                } else {
                  next.remove(category);
                }
                onChanged(next);
              },
              selectedColor: JobCategoryMapper.backgroundColor(category),
              labelStyle: TextStyle(
                  color: selected.contains(category)
                      ? JobCategoryMapper.accentColor(category)
                      : AppColors.inkMuted,
                  fontWeight: FontWeight.w700),
              side: BorderSide(
                  color: selected.contains(category)
                      ? Colors.transparent
                      : AppColors.line),
            ),
        ],
      );
}

class _ExperiencePicker extends StatelessWidget {
  const _ExperiencePicker({required this.selected, required this.onChanged});
  final ExperienceTier selected;
  final ValueChanged<ExperienceTier> onChanged;

  @override
  Widget build(BuildContext context) => Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final tier in ExperienceTierMapper.all)
            ChoiceChip(
              label: Text(ExperienceTierMapper.displayName(tier)),
              selected: selected == tier,
              onSelected: (_) => onChanged(tier),
              selectedColor: AppColors.blue.withValues(alpha: .14),
              labelStyle: TextStyle(
                  color: selected == tier ? AppColors.blue : AppColors.inkMuted,
                  fontWeight: FontWeight.w700),
              side: BorderSide(
                  color: selected == tier ? Colors.transparent : AppColors.line),
            ),
        ],
      );
}

class _RatingPicker extends StatelessWidget {
  const _RatingPicker({required this.selected, required this.onChanged});
  final double selected;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) => Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final option in kWorkerRatingOptions)
            ChoiceChip(
              label: Text(option == 0 ? 'Any' : '${option.toStringAsFixed(1)}+'),
              avatar: option == 0
                  ? null
                  : Icon(Icons.star_rounded,
                      size: 16,
                      color: selected == option
                          ? AppColors.warmGold
                          : AppColors.inkMuted),
              selected: selected == option,
              onSelected: (_) => onChanged(option),
              selectedColor: AppColors.blue.withValues(alpha: .14),
              labelStyle: TextStyle(
                  color:
                      selected == option ? AppColors.blue : AppColors.inkMuted,
                  fontWeight: FontWeight.w700),
              side: BorderSide(
                  color: selected == option
                      ? Colors.transparent
                      : AppColors.line),
            ),
        ],
      );
}

class _DistanceControl extends StatelessWidget {
  const _DistanceControl({required this.value, required this.onChanged});
  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final isAny = value >= WorkerFilterBounds.maxDistance;
    return Column(
      children: [
        Slider(
          value: value,
          min: WorkerFilterBounds.minDistance,
          max: WorkerFilterBounds.maxDistance,
          divisions: 20,
          activeColor: AppColors.blue,
          label: isAny ? 'Any distance' : '${value.toStringAsFixed(0)} km',
          onChanged: onChanged,
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
              isAny ? 'Any distance' : 'Within ${value.toStringAsFixed(0)} km',
              style: const TextStyle(
                  color: AppColors.inkMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}

class _MultiChoiceChips extends StatelessWidget {
  const _MultiChoiceChips({
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  final List<String> options;
  final Set<String> selected;
  final ValueChanged<Set<String>> onChanged;

  @override
  Widget build(BuildContext context) => Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final option in options)
            FilterChip(
              label: Text(option),
              selected: selected.contains(option),
              onSelected: (isSelected) {
                final next = {...selected};
                if (isSelected) {
                  next.add(option);
                } else {
                  next.remove(option);
                }
                onChanged(next);
              },
              selectedColor: AppColors.blue.withValues(alpha: .14),
              labelStyle: TextStyle(
                  color: selected.contains(option)
                      ? AppColors.blue
                      : AppColors.inkMuted,
                  fontWeight: FontWeight.w700),
              side: BorderSide(
                  color: selected.contains(option)
                      ? Colors.transparent
                      : AppColors.line),
            ),
        ],
      );
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow(
      {required this.label, required this.value, required this.onChanged});
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => SwitchListTile.adaptive(
        value: value,
        onChanged: onChanged,
        activeThumbColor: AppColors.blue,
        contentPadding: EdgeInsets.zero,
        title: Text(label,
            style: const TextStyle(
                color: AppColors.navy,
                fontSize: 13.5,
                fontWeight: FontWeight.w600)),
      );
}
