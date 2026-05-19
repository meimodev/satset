import 'package:flutter/material.dart';
import '../colors.dart';

class SatDivider extends StatelessWidget {
  const SatDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return const Divider(
      color: AppColors.secondaryOverride,
      thickness: 0.5,
      height: 12,
    );
  }
}
