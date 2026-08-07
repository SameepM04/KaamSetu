import 'dart:async';

import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// Debounced Material 3 search field for the Jobs screen.
///
/// Keeps its own [TextEditingController] and debounce [Timer] so parent
/// widgets never rebuild on every keystroke — [onChanged] only fires once
/// typing settles (or immediately when cleared).
class JobSearchBar extends StatefulWidget {
  const JobSearchBar({
    super.key,
    required this.onChanged,
    this.hintText = 'Search jobs, employers, skills…',
    this.debounce = const Duration(milliseconds: 350),
  });

  final ValueChanged<String> onChanged;
  final String hintText;
  final Duration debounce;

  @override
  State<JobSearchBar> createState() => _JobSearchBarState();
}

class _JobSearchBarState extends State<JobSearchBar> {
  final _controller = TextEditingController();
  Timer? _debounceTimer;
  bool _hasText = false;

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _handleChanged(String value) {
    // Keep the clear button's visibility in sync without waiting for the
    // debounce, so the UI never lags behind what's typed.
    final hasText = value.isNotEmpty;
    if (hasText != _hasText) setState(() => _hasText = hasText);

    _debounceTimer?.cancel();
    _debounceTimer = Timer(widget.debounce, () => widget.onChanged(value));
  }

  void _clear() {
    _debounceTimer?.cancel();
    _controller.clear();
    setState(() => _hasText = false);
    widget.onChanged('');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line),
        boxShadow: const [
          BoxShadow(
              color: Color(0x14102A54), blurRadius: 16, offset: Offset(0, 6)),
        ],
      ),
      child: TextField(
        controller: _controller,
        onChanged: _handleChanged,
        textInputAction: TextInputAction.search,
        style: const TextStyle(
            color: AppColors.navy,
            fontSize: 13.5,
            fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          isDense: true,
          hintText: widget.hintText,
          hintStyle: TextStyle(
              color: AppColors.inkMuted.withValues(alpha: .85),
              fontSize: 13.5,
              fontWeight: FontWeight.w500),
          prefixIcon: const Icon(Icons.search_rounded,
              color: AppColors.inkMuted, size: 21),
          suffixIcon: _hasText
              ? IconButton(
                  icon: const Icon(Icons.close_rounded,
                      color: AppColors.inkMuted, size: 19),
                  tooltip: 'Clear search',
                  onPressed: _clear,
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 15),
        ),
      ),
    );
  }
}
