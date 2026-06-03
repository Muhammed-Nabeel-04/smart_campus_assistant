import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class Skeleton extends StatelessWidget {
  final double? width;
  final double? height;
  final BorderRadiusGeometry? borderRadius;

  const Skeleton({super.key, this.width, this.height, this.borderRadius});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Shimmer.fromColors(
      baseColor: isDark ? Colors.grey[800]! : Colors.grey[300]!,
      highlightColor: isDark ? Colors.grey[700]! : Colors.grey[100]!,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: borderRadius ?? BorderRadius.circular(8),
        ),
      ),
    );
  }
}

class CardSkeleton extends StatelessWidget {
  const CardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Skeleton(width: 80, height: 20),
              Skeleton(width: 60, height: 20),
            ],
          ),
          const SizedBox(height: 12),
          Skeleton(width: double.infinity, height: 20),
          const SizedBox(height: 8),
          Skeleton(width: 200, height: 16),
        ],
      ),
    );
  }
}

class AppPageSkeleton extends StatelessWidget {
  final EdgeInsetsGeometry padding;
  final int itemCount;
  final bool showHeader;

  const AppPageSkeleton({
    super.key,
    this.padding = const EdgeInsets.all(16),
    this.itemCount = 5,
    this.showHeader = true,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: padding,
      children: [
        if (showHeader) ...[
          const Skeleton(
            height: 96,
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
          const SizedBox(height: 16),
        ],
        ...List.generate(itemCount, (_) => const CardSkeleton()),
      ],
    );
  }
}

class DashboardSkeleton extends StatelessWidget {
  const DashboardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.35,
          children: List.generate(
            4,
            (_) => const Skeleton(
              borderRadius: BorderRadius.all(Radius.circular(16)),
            ),
          ),
        ),
        const SizedBox(height: 24),
        const Skeleton(width: 150, height: 24),
        const SizedBox(height: 16),
        const CardSkeleton(),
        const CardSkeleton(),
        const SizedBox(height: 12),
        const Skeleton(width: 170, height: 24),
        const SizedBox(height: 16),
        const Skeleton(
          height: 120,
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ],
    );
  }
}

class FormSkeleton extends StatelessWidget {
  final int fieldCount;

  const FormSkeleton({super.key, this.fieldCount = 6});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Skeleton(
          height: 84,
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
        const SizedBox(height: 20),
        ...List.generate(
          fieldCount,
          (_) => const Padding(
            padding: EdgeInsets.only(bottom: 14),
            child: Skeleton(
              height: 56,
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Skeleton(
          height: 48,
          borderRadius: BorderRadius.all(Radius.circular(24)),
        ),
      ],
    );
  }
}
