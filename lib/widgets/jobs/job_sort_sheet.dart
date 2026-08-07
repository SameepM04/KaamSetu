import 'package:flutter/material.dart';

import '../../data/job_filters.dart';
import '../../theme/app_colors.dart';

/// Opens the Jobs sort bottom sheet and resolves with the chosen
/// [SortOption], or `null` if the user dismissed it without picking one.
Future<SortOption?> showJobSortSheet(BuildContext context, SortOption current) {
  return showModalBottomSheet<SortOption>(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (_) => _JobSortSheet(current: current),
  );
}

class _JobSortSheet extends StatelessWidget {
  const _JobSortSheet({required this.current});
  final SortOption current;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 10, 8, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                  color: AppColors.line,
                  borderRadius: BorderRadius.circular(3)),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Sort By',
                    style: TextStyle(
                        color: AppColors.navy,
                        fontSize: 18,
                        fontWeight: FontWeight.w800)),
              ),
            ),
            RadioGroup<SortOption>(
              groupValue: current,
              onChanged: (value) => Navigator.of(context).pop(value),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final option in SortOptionMapper.all)
                    RadioListTile<SortOption>(
                      value: option,
                      activeColor: AppColors.blue,
                      title: Text(SortOptionMapper.displayName(option),
                          style: const TextStyle(
                              color: AppColors.navy,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600)),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
