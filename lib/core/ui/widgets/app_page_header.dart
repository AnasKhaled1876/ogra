import 'package:flutter/material.dart';

import '../app_spacing.dart';

class AppPageHeader extends StatelessWidget {
  const AppPageHeader({required this.title, this.subtitle, super.key});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(title, style: Theme.of(context).textTheme.headlineLarge),
        if (subtitle != null) ...<Widget>[
          const SizedBox(height: AppSpacing.xs),
          Text(subtitle!, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ],
    );
  }
}
