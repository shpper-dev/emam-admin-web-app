import 'package:emam_admin_web_app/core/constants/app_constants.dart';
import 'package:flutter/material.dart';

/// Placeholder shown while content loads: a few rounded rows that pulse
/// gently, so the page keeps its shape instead of jumping when data lands.
/// Pulsing stops when the OS asks for reduced motion.
class SkeletonList extends StatefulWidget {
  const SkeletonList({super.key, this.rows = 3, this.rowHeight = 56});

  final int rows;
  final double rowHeight;

  @override
  State<SkeletonList> createState() => _SkeletonListState();
}

class _SkeletonListState extends State<SkeletonList>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.of(context).disableAnimations) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Loading',
      child: ExcludeSemantics(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final opacity = 0.5 + 0.5 * _controller.value;
            return Opacity(
              opacity: opacity,
              child: Column(
                children: [
                  for (var i = 0; i < widget.rows; i++) ...[
                    if (i > 0) const SizedBox(height: AppConstants.space12),
                    _SkeletonRow(height: widget.rowHeight),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SkeletonRow extends StatelessWidget {
  const _SkeletonRow({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    Widget bar(double? width, double h) => Container(
      width: width,
      height: h,
      decoration: BoxDecoration(
        color: AppConstants.textPrimary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
      ),
    );

    return Container(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.space12),
      decoration: BoxDecoration(
        color: AppConstants.textPrimary.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(AppConstants.radiusMd),
      ),
      child: Row(
        children: [
          Container(
            width: height * 0.55,
            height: height * 0.55,
            decoration: BoxDecoration(
              color: AppConstants.textPrimary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppConstants.space12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [bar(160, 10), const SizedBox(height: 8), bar(null, 8)],
            ),
          ),
        ],
      ),
    );
  }
}
