import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class MainDrawer extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onSelect;

  const MainDrawer({
    super.key,
    required this.currentIndex,
    required this.onSelect,
  });

  static const _items = [
    (Icons.home_outlined, Icons.home, 'الرئيسية'),
    (Icons.monitor_heart_outlined, Icons.monitor_heart, 'الفحص'),
    (Icons.show_chart, Icons.show_chart, 'الأوسيلوسكوب'),
    (Icons.memory_outlined, Icons.memory, 'البرمجة'),
    (Icons.settings_outlined, Icons.settings, 'الإعدادات'),
  ];

  @override
  Widget build(BuildContext context) {
    return NavigationDrawer(
      backgroundColor: AppColors.surface,
      indicatorColor: AppColors.primary.withValues(alpha: 0.18),
      selectedIndex: currentIndex,
      onDestinationSelected: (index) {
        onSelect(index);
        Navigator.of(context).pop();
      },
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.car_repair,
                  color: Colors.black,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'فاحص برو X1',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'فحص • أوسيلوسكوب • برمجة',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        for (final (icon, selectedIcon, label) in _items)
          NavigationDrawerDestination(
            icon: Icon(icon),
            selectedIcon: Icon(selectedIcon),
            label: Text(label),
          ),
        const SizedBox(height: 12),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Icon(
                Icons.battery_charging_full,
                size: 18,
                color: AppColors.success,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'بطارية 18600 mAh',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
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
