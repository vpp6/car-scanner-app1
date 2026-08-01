import 'package:flutter/material.dart';

import '../models/device.dart';
import '../theme/app_colors.dart';

class ConnectionStatusChip extends StatelessWidget {
  final DeviceStatus status;

  const ConnectionStatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      DeviceStatus.disconnected => ('غير متصل', AppColors.textHint),
      DeviceStatus.scanning => ('جاري البحث', AppColors.secondary),
      DeviceStatus.connecting => ('جاري الاتصال', AppColors.warning),
      DeviceStatus.connected => ('متصل', AppColors.success),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
