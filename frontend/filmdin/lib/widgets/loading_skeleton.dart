import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class SkeletonBox extends StatelessWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;

  const SkeletonBox({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppTheme.darkGrey,
        borderRadius: borderRadius ?? BorderRadius.circular(10),
      ),
    );
  }
}

class SkeletonList extends StatelessWidget {
  final int itemCount;
  final double itemHeight;
  final EdgeInsetsGeometry padding;

  const SkeletonList({
    super.key,
    this.itemCount = 4,
    this.itemHeight = 90,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: padding,
      itemCount: itemCount,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return SkeletonBox(
          width: double.infinity,
          height: itemHeight,
          borderRadius: BorderRadius.circular(14),
        );
      },
    );
  }
}

class ProfileSkeleton extends StatelessWidget {
  const ProfileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: const [
          SizedBox(height: 8),
          SkeletonBox(
            width: 92,
            height: 92,
            borderRadius: BorderRadius.all(Radius.circular(46)),
          ),
          SizedBox(height: 16),
          SkeletonBox(width: 180, height: 20),
          SizedBox(height: 10),
          SkeletonBox(width: 220, height: 14),
          SizedBox(height: 24),
          SkeletonBox(width: double.infinity, height: 120),
          SizedBox(height: 16),
          SkeletonBox(width: double.infinity, height: 84),
          SizedBox(height: 12),
          SkeletonBox(width: double.infinity, height: 84),
          SizedBox(height: 12),
          SkeletonBox(width: double.infinity, height: 84),
        ],
      ),
    );
  }
}
