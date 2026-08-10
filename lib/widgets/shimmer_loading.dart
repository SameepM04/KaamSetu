import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// A subtle, premium shimmer sweep used to build skeleton loading states
/// (worker cards, job cards, lists) without pulling in an extra package.
///
/// Wrap any placeholder layout (boxes shaped like the real content) with
/// [ShimmerLoading] and it will animate a soft light sweep across it.
class ShimmerLoading extends StatefulWidget {
  const ShimmerLoading({super.key, required this.child, this.enabled = true});

  final Widget child;
  final bool enabled;

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => ShaderMask(
        blendMode: BlendMode.srcATop,
        shaderCallback: (bounds) => LinearGradient(
          colors: [
            AppColors.line.withValues(alpha: .55),
            Colors.white.withValues(alpha: .95),
            AppColors.line.withValues(alpha: .55),
          ],
          stops: const [0.35, 0.5, 0.65],
          begin: Alignment(-1 - _controller.value * 3, 0),
          end: Alignment(1 - _controller.value * 3, 0),
        ).createShader(bounds),
        child: child,
      ),
      child: widget.child,
    );
  }
}

/// A single rounded shimmer block — the basic building block for skeletons.
class ShimmerBox extends StatelessWidget {
  const ShimmerBox({
    super.key,
    this.width,
    this.height = 16,
    this.borderRadius = 10,
  });

  final double? width;
  final double height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) => Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: AppColors.line.withValues(alpha: .45),
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      );
}

/// Skeleton placeholder shaped like [WorkerCard] / a horizontal profile row —
/// avatar circle + two lines of text + a trailing chip.
class WorkerCardSkeleton extends StatelessWidget {
  const WorkerCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) => ShimmerLoading(
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.line.withValues(alpha: .5)),
          ),
          child: Row(
            children: [
              const ShimmerBox(width: 56, height: 56, borderRadius: 28),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    ShimmerBox(width: 140, height: 15),
                    SizedBox(height: 8),
                    ShimmerBox(width: 90, height: 12),
                    SizedBox(height: 10),
                    ShimmerBox(width: 70, height: 12),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              const ShimmerBox(width: 56, height: 30, borderRadius: 15),
            ],
          ),
        ),
      );
}

/// Skeleton placeholder shaped like a job/list card — title + two metadata
/// lines + trailing price block.
class JobCardSkeleton extends StatelessWidget {
  const JobCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) => ShimmerLoading(
        child: Container(
          height: 92,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.line.withValues(alpha: .5)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    ShimmerBox(width: 160, height: 15),
                    SizedBox(height: 10),
                    ShimmerBox(width: 110, height: 11),
                    SizedBox(height: 8),
                    ShimmerBox(width: 80, height: 11),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              const ShimmerBox(width: 54, height: 20, borderRadius: 8),
            ],
          ),
        ),
      );
}

/// A vertically-stacked list of [count] skeleton items, separated to match
/// the real list's spacing. Pass a [builder] for a custom skeleton shape.
class SkeletonList extends StatelessWidget {
  const SkeletonList({
    super.key,
    this.count = 5,
    this.spacing = 12,
    this.padding = const EdgeInsets.fromLTRB(20, 16, 20, 24),
    this.itemBuilder,
  });

  final int count;
  final double spacing;
  final EdgeInsets padding;
  final WidgetBuilder? itemBuilder;

  @override
  Widget build(BuildContext context) => ListView.separated(
        padding: padding,
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemCount: count,
        separatorBuilder: (_, __) => SizedBox(height: spacing),
        itemBuilder: (context, i) =>
            itemBuilder?.call(context) ?? const JobCardSkeleton(),
      );
}
