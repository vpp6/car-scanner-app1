import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class BatteryIndicator extends StatelessWidget {
  final int level;
  final int capacityMah;
  final bool charging;

  const BatteryIndicator({
    super.key,
    required this.level,
    required this.capacityMah,
    this.charging = false,
  });

  Color get _color {
    if (level <= 20) return AppColors.danger;
    if (level <= 50) return AppColors.warning;
    return AppColors.success;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (charging) ...[
              const Icon(Icons.bolt, color: AppColors.warning, size: 18),
              const SizedBox(width: 6),
            ],
            Text(
              '$level%',
              style: TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.w800,
                color: _color,
              ),
            ),
          ],
        ),
        Text(
          '$capacityMah mAh',
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        const SizedBox(height: 10),
        Container(
          width: 120,
          height: 14,
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(7),
            border: Border.all(color: AppColors.border),
          ),
          padding: const EdgeInsets.all(2),
          child: FractionallySizedBox(
            alignment: Alignment.centerRight,
            widthFactor: level / 100,
            child: Container(
              decoration: BoxDecoration(
                color: _color,
                borderRadius: BorderRadius.circular(5),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
