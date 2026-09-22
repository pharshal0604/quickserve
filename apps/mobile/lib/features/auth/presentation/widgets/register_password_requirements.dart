import 'package:flutter/material.dart';

import 'package:quickserve_mobile/config/theme/app_colors.dart';
import 'package:quickserve_mobile/config/theme/app_spacing.dart';

/// Displays the password rules and their current state.
class PasswordRequirements extends StatelessWidget {
  /// Creates the password-requirements list.
  const PasswordRequirements({
    super.key,
    required this.hasValidLength,
    required this.hasUppercase,
    required this.hasLowercase,
    required this.hasDigit,
  });

  /// Whether the password is between 8 and 128 characters.
  final bool hasValidLength;

  /// Whether the password includes an uppercase letter.
  final bool hasUppercase;

  /// Whether the password includes a lowercase letter.
  final bool hasLowercase;

  /// Whether the password includes a digit.
  final bool hasDigit;

  @override
  Widget build(BuildContext context) {
    final textScaler = MediaQuery.textScalerOf(context);
    final iconSize = textScaler.scale(18).clamp(18.0, 24.0).toDouble();
    final rules = [
      ('8–128 characters', hasValidLength),
      ('One uppercase letter', hasUppercase),
      ('One lowercase letter', hasLowercase),
      ('One digit', hasDigit),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final rule in rules)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  rule.$2 ? Icons.check_circle_outline : Icons.cancel_outlined,
                  size: iconSize,
                  color: rule.$2
                      ? AppColors.success
                      : Theme.of(context).colorScheme.error,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    rule.$1,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: rule.$2
                          ? AppColors.success
                          : Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
