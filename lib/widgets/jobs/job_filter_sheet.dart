import 'package:flutter/material.dart';

import '../../data/job_categories.dart';
import '../../data/job_filters.dart';
import '../../data/job_previews.dart';
import '../../theme/app_colors.dart';

/// Opens the filter bottom sheet and resolves with the filters the user
/// applied, or `null` if they dismissed it without applying.
///
/// [forWorkers] switches the sheet's lower section from the Jobs-search
/// filters (Experience / Job Type / Today's Jobs / Verified Employers) to
/// the Household worker-search filters (Availability / Minimum Rating) —
/// Category, [Daily Wage / Salary] Range and Distance are shared as-is by
/// both, since they mean the same thing for a job post and a worker. The
/// sheet, its styling and its Category/Salary/Distance controls are the
/// same component either way — nothing is duplicated.
Future<JobFilters?> showJobFilterSheet(
  BuildContext context,
  JobFilters current, {
  bool forWorkers = false,
}) {
  return showModalBottomSheet<JobFilters>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (_) => _JobFilterSheet(initial: current, forWorkers: forWorkers),
  );
}

class _JobFilterSheet extends StatefulWidget {
  const _JobFilterSheet({required this.initial, required this.forWorkers});
  final JobFilters initial;
  final bool forWorkers;

  @override
  State<_JobFilterSheet> createState() => _JobFilterSheetState();
}

class _JobFilterSheetState extends State<_JobFilterSheet> {
  late JobCategory? _category = widget.initial.category;
  late RangeValues _salaryRange = RangeValues(
      widget.initial.salaryRange.$1.toDouble(),
      widget.initial.salaryRange.$2.toDouble());
  late double _maxDistance = widget.initial.maxDistance;
  late Set<ExperienceLevel> _experienceLevels = {
    ...widget.initial.experienceLevels
  };
  late Set<JobType> _jobTypes = {...widget.initial.jobTypes};
  late bool _todayOnly = widget.initial.todayOnly;
  late bool _nearbyOnly = widget.initial.nearbyOnly;
  late bool _verifiedOnly = widget.initial.verifiedOnly;
  late Set<String> _availability = {...widget.initial.availability};
  late double _minRating = widget.initial.minRating;

  void _reset() {
    setState(() {
      _category = null;
      _salaryRange = RangeValues(JobFilterBounds.minSalary.toDouble(),
          JobFilterBounds.maxSalary.toDouble());
      _maxDistance = JobFilterBounds.maxDistance;
      _experienceLevels = {};
      _jobTypes = {};
      _todayOnly = false;
      _nearbyOnly = false;
      _verifiedOnly = false;
      _availability = {};
      _minRating = 0;
    });
  }

  void _apply() {
    Navigator.of(context).pop(JobFilters(
      category: _category,
      salaryRange: (_salaryRange.start.round(), _salaryRange.end.round()),
      maxDistance: _maxDistance,
      experienceLevels: _experienceLevels,
      jobTypes: _jobTypes,
      todayOnly: _todayOnly,
      nearbyOnly: _nearbyOnly,
      verifiedOnly: _verifiedOnly,
      availability: _availability,
      minRating: _minRating,
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
                    const _SectionLabel('Category'),
                    _CategoryPicker(
                      selected: _category,
                      onChanged: (value) => setState(() => _category = value),
                    ),
                    const SizedBox(height: 22),
                    _SectionLabel(
                        widget.forWorkers ? 'Daily Wage' : 'Salary Range'),
                    _SalaryRangeControl(
                      values: _salaryRange,
                      onChanged: (value) =>
                          setState(() => _salaryRange = value),
                    ),
                    const SizedBox(height: 22),
                    const _SectionLabel('Distance'),
                    _DistanceControl(
                      value: _maxDistance,
                      onChanged: (value) =>
                          setState(() => _maxDistance = value),
                    ),
                    const SizedBox(height: 22),
                    if (widget.forWorkers) ...[
                      const _SectionLabel('Availability'),
                      _MultiChoiceChips<String>(
                        options: kWorkerAvailabilityOptions,
                        labelOf: (v) => v,
                        selected: _availability,
                        onChanged: (value) =>
                            setState(() => _availability = value),
                      ),
                      const SizedBox(height: 22),
                      const _SectionLabel('Minimum Rating'),
                      _RatingControl(
                        value: _minRating,
                        onChanged: (value) =>
                            setState(() => _minRating = value),
                      ),
                    ] else ...[
                      const _SectionLabel('Experience'),
                      _MultiChoiceChips<ExperienceLevel>(
                        options: ExperienceLevelMapper.all,
                        labelOf: ExperienceLevelMapper.displayName,
                        selected: _experienceLevels,
                        onChanged: (value) =>
                            setState(() => _experienceLevels = value),
                      ),
                      const SizedBox(height: 22),
                      const _SectionLabel('Job Type'),
                      _MultiChoiceChips<JobType>(
                        options: JobTypeMapper.all,
                        labelOf: JobTypeMapper.displayName,
                        selected: _jobTypes,
                        onChanged: (value) =>
                            setState(() => _jobTypes = value),
                      ),
                      const SizedBox(height: 22),
                      const _SectionLabel('Quick Filters'),
                      _ToggleRow(
                        label: "Today's Jobs",
                        value: _todayOnly,
                        onChanged: (value) =>
                            setState(() => _todayOnly = value),
                      ),
                      _ToggleRow(
                        label: 'Nearby Only',
                        value: _nearbyOnly,
                        onChanged: (value) =>
                            setState(() => _nearbyOnly = value),
                      ),
                      _ToggleRow(
                        label: 'Verified Employers',
                        value: _verifiedOnly,
                        onChanged: (value) =>
                            setState(() => _verifiedOnly = value),
                      ),
                    ],
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
              child: Text('Filters',
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
  Widget build(BuildContext context) => DecoratedBox(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppColors.line)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
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

class _CategoryPicker extends StatelessWidget {
  const _CategoryPicker({required this.selected, required this.onChanged});
  final JobCategory? selected;
  final ValueChanged<JobCategory?> onChanged;

  @override
  Widget build(BuildContext context) => Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final category in JobCategoryMapper.all)
            ChoiceChip(
              label: Text(JobCategoryMapper.displayName(category)),
              selected: selected == category,
              onSelected: (isSelected) =>
                  onChanged(isSelected ? category : null),
              selectedColor: JobCategoryMapper.backgroundColor(category),
              labelStyle: TextStyle(
                  color: selected == category
                      ? JobCategoryMapper.accentColor(category)
                      : AppColors.inkMuted,
                  fontWeight: FontWeight.w700),
              side: BorderSide(
                  color: selected == category
                      ? Colors.transparent
                      : AppColors.line),
            ),
        ],
      );
}

class _SalaryRangeControl extends StatelessWidget {
  const _SalaryRangeControl({required this.values, required this.onChanged});
  final RangeValues values;
  final ValueChanged<RangeValues> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        RangeSlider(
          values: values,
          min: JobFilterBounds.minSalary.toDouble(),
          max: JobFilterBounds.maxSalary.toDouble(),
          divisions: 30,
          activeColor: AppColors.blue,
          labels:
              RangeLabels('₹${values.start.round()}', '₹${values.end.round()}'),
          onChanged: onChanged,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('₹${values.start.round()} / day',
                style: const TextStyle(
                    color: AppColors.inkMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
            Text('₹${values.end.round()} / day',
                style: const TextStyle(
                    color: AppColors.inkMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ],
    );
  }
}

class _DistanceControl extends StatelessWidget {
  const _DistanceControl({required this.value, required this.onChanged});
  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Slider(
          value: value,
          min: JobFilterBounds.minDistance,
          max: JobFilterBounds.maxDistance,
          divisions: 20,
          activeColor: AppColors.blue,
          label: '${value.toStringAsFixed(1)} km',
          onChanged: onChanged,
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: Text('Within ${value.toStringAsFixed(1)} km',
              style: const TextStyle(
                  color: AppColors.inkMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}

class _RatingControl extends StatelessWidget {
  const _RatingControl({required this.value, required this.onChanged});
  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          for (var star = 1; star <= 5; star++)
            GestureDetector(
              onTap: () =>
                  onChanged(value == star.toDouble() ? 0 : star.toDouble()),
              child: Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Icon(
                  value >= star
                      ? Icons.star_rounded
                      : Icons.star_outline_rounded,
                  color: AppColors.warmGold,
                  size: 30,
                ),
              ),
            ),
          const SizedBox(width: 10),
          Text(
            value > 0 ? '${value.toInt()}+ stars' : 'Any rating',
            style: const TextStyle(
                color: AppColors.inkMuted,
                fontSize: 12,
                fontWeight: FontWeight.w600),
          ),
        ],
      );
}

class _MultiChoiceChips<T> extends StatelessWidget {
  const _MultiChoiceChips({
    required this.options,
    required this.labelOf,
    required this.selected,
    required this.onChanged,
  });

  final List<T> options;
  final String Function(T) labelOf;
  final Set<T> selected;
  final ValueChanged<Set<T>> onChanged;

  @override
  Widget build(BuildContext context) => Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final option in options)
            FilterChip(
              label: Text(labelOf(option)),
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
