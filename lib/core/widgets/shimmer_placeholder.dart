import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ShimmerPlaceholder extends StatelessWidget {
  final Widget child;

  const ShimmerPlaceholder({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Theme.of(context).brightness == Brightness.light
          ? Colors.grey[300]!
          : Colors.grey[900]!,
      highlightColor: Theme.of(context).brightness == Brightness.light
          ? Colors.grey[100]!
          : Colors.grey[600]!,
      child: child,
    );
  }
}
