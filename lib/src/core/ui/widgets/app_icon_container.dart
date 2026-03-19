import 'package:flutter/material.dart';

import '../app_radius.dart';

class AppIconContainer extends StatelessWidget {
  const AppIconContainer({required this.icon, this.size = 42, super.key});

  final IconData icon;
  final double size;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppRadius.medium),
        border: Border.all(color: scheme.primary.withValues(alpha: 0.24)),
      ),
      child: Icon(icon, color: scheme.primary),
    );
  }
}
