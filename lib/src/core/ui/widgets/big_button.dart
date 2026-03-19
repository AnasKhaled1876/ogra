import 'package:flutter/material.dart';

import '../app_colors.dart';

class BigButton extends StatelessWidget {
  const BigButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isSelected = false,
    this.height = 62,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isSelected;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: isSelected
          ? ElevatedButton(
              onPressed: onPressed,
              child: Text(label, textAlign: TextAlign.center),
            )
          : OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.borderSubtle),
              ),
              onPressed: onPressed,
              child: Text(label, textAlign: TextAlign.center),
            ),
    );
  }
}
