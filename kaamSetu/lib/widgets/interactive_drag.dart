import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';

class InteractiveDrag extends StatefulWidget {
  const InteractiveDrag({
    super.key,
    required this.label,
    required this.icon,
    required this.onComplete,
    this.onProgress,
    this.centerThumb = false,
    this.fillColor,
  });

  final String label;
  final IconData icon;
  final VoidCallback onComplete;
  final ValueChanged<double>? onProgress;
  final bool centerThumb;

  /// Optional progress-fill color for the track. Null (default) preserves
  /// the original look used by other onboarding screens.
  final Color? fillColor;

  @override
  State<InteractiveDrag> createState() => _InteractiveDragState();
}

class _InteractiveDragState extends State<InteractiveDrag> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _completed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 300))
      ..value = widget.centerThumb ? .5 : 0
      ..addListener(() {
        widget.onProgress?.call(_controller.value);
        if (mounted) setState(() {});
      });
  }

  void _finish() {
    if (_completed) return;
    _completed = true;
    HapticFeedback.lightImpact();
    _controller.animateTo(1, curve: Curves.easeOutCubic);
    Future<void>.delayed(const Duration(milliseconds: 390), widget.onComplete);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const thumb = 66.0;
        final travel = constraints.maxWidth - thumb - 10;
        return GestureDetector(
          onHorizontalDragUpdate: (details) {
            if (_completed) return;
            _controller.value = (_controller.value + details.delta.dx / travel).clamp(0.0, 1.0).toDouble();
          },
          onHorizontalDragEnd: (_) {
            if (_controller.value > .82) {
              _finish();
            } else {
              _controller.animateTo(widget.centerThumb ? .5 : 0, curve: Curves.easeOutCubic);
            }
          },
          child: Container(
            height: 78,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .73),
              borderRadius: BorderRadius.circular(39),
              border: Border.all(color: const Color(0xFFA9C6FF), width: 1.6),
              boxShadow: const [BoxShadow(color: Color(0x233E7EEB), blurRadius: 22, offset: Offset(0, 9))],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (widget.fillColor != null)
                  Positioned(
                    left: 5,
                    top: 5,
                    bottom: 5,
                    width: (thumb / 2) + travel * _controller.value,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: widget.fillColor,
                        borderRadius: BorderRadius.circular(39),
                      ),
                    ),
                  ),
                AnimatedOpacity(
                  opacity: _controller.value > .84 ? .25 : 1,
                  duration: const Duration(milliseconds: 150),
                  child: Padding(
                    padding: const EdgeInsets.only(left: 72, right: 28),
                    child: Row(
                      children: [
                        Expanded(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(widget.label, maxLines: 1, style: const TextStyle(color: AppColors.electricBlue, fontSize: 20, fontWeight: FontWeight.w700)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward_rounded, color: AppColors.electricBlue, size: 31),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: 5 + travel * _controller.value,
                  top: 5,
                  child: Transform.scale(
                    scale: _completed ? 1.08 : 1,
                    child: Container(
                      width: thumb,
                      height: thumb,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(colors: [Color(0xFF5187FF), AppColors.blue]),
                        boxShadow: const [BoxShadow(color: Color(0x66336AF0), blurRadius: 19, offset: Offset(0, 7))],
                      ),
                      child: Icon(widget.icon, color: Colors.white, size: 32),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
