import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/device.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../widgets/battery_indicator.dart';
import '../widgets/connection_status_chip.dart';
import '../widgets/section_title.dart';
import '../widgets/side_menu_button.dart';
import 'connection_screen.dart';
import 'main_shell.dart';
import 'vehicle_select_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Scaffold(
      appBar: AppBar(
        leading: const SideMenuButton(),
        title: const Text('لوحة التحكم'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: ConnectionStatusChip(status: state.status),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          _deviceCard(context, state),
          const SizedBox(height: 8),
          if (state.isConnected && state.device != null)
            _batteryCard(state.device!, state.batteryLevel),
          const SizedBox(height: 8),
          SectionTitle(
            title: 'إجراءات سريعة',
            trailing: Text(
              state.isConnected ? 'الجهاز جاهز' : 'تتطلب الاتصال',
              style: TextStyle(
                fontSize: 12,
                color: state.isConnected
                    ? AppColors.success
                    : AppColors.textHint,
              ),
            ),
          ),
          _quickActions(context, state),
          const SizedBox(height: 8),
          const SectionTitle(title: 'المركبة المتصلة'),
          _vehicleCard(context, state),
          const SizedBox(height: 8),
          const SectionTitle(title: 'مواصفات الجهاز'),
          _specsCard(state),
        ],
      ),
    );
  }

  Widget _deviceCard(BuildContext context, AppState state) {
    final device = state.device;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(
                Icons.car_repair,
                color: AppColors.primary,
                size: 34,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    device?.name ?? 'فاحص برو X1',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    device != null
                        ? '${device.model} • ${device.methodLabel}'
                        : 'اضغط للاتصال بالجهاز',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (!state.isConnected)
              IconButton.filled(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ConnectionScreen()),
                ),
                icon: const Icon(Icons.link, color: Colors.black),
              )
            else
              IconButton(
                onPressed: () => state.disconnect(),
                icon: const Icon(Icons.link_off, color: AppColors.textHint),
              ),
          ],
        ),
      ),
    );
  }

  Widget _batteryCard(DeviceInfo device, int batteryLevel) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          children: [
            Text(
              'بطارية الجهاز',
              style: TextStyle(
                fontSize: 13,
                color: batteryLevel <= 20
                    ? AppColors.danger
                    : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            BatteryIndicator(
              level: batteryLevel,
              capacityMah: device.batteryCapacityMah,
              charging: device.charging,
            ),
          ],
        ),
      ),
    );
  }

  Widget _quickActions(BuildContext context, AppState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _QuickAction(
            icon: Icons.monitor_heart,
            label: 'فحص شامل',
            color: AppColors.primary,
            onTap: state.isConnected
                ? () => _goToTab(context, 1)
                : () => _requireConnection(context),
          ),
          _QuickAction(
            icon: Icons.show_chart,
            label: 'الأوسيلوسكوب',
            color: AppColors.secondary,
            onTap: state.isConnected
                ? () => _goToTab(context, 2)
                : () => _requireConnection(context),
          ),
          _QuickAction(
            icon: Icons.memory,
            label: 'البرمجة',
            color: AppColors.warning,
            onTap: state.isConnected
                ? () => _goToTab(context, 3)
                : () => _requireConnection(context),
          ),
          _QuickAction(
            icon: Icons.error_outline,
            label: 'كود فوري',
            color: AppColors.danger,
            onTap: state.isConnected
                ? () => _goToTab(context, 1)
                : () => _requireConnection(context),
          ),
        ],
      ),
    );
  }

  Widget _vehicleCard(BuildContext context, AppState state) {
    final vehicle = state.vehicle;
    if (vehicle == null) {
      return Card(
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          leading: const Icon(Icons.directions_car, color: AppColors.textHint),
          title: const Text(
            'لم يتم تحديد مركبة',
            style: TextStyle(color: AppColors.textPrimary),
          ),
          subtitle: const Text(
            'حدد المركبة لبدء فحص الأنظمة',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          trailing: const Icon(Icons.chevron_left, color: AppColors.textHint),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const VehicleSelectScreen()),
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.secondary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.directions_car,
                color: AppColors.secondary,
                size: 30,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${vehicle.make} ${vehicle.model} ${vehicle.year}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${vehicle.engine} • ${vehicle.odometer} كم',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              vehicle.plate,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _specsCard(AppState state) {
    final device = state.device;
    if (device == null) return const SizedBox.shrink();
    return Card(
      child: Column(
        children: [
          _specRow(
            icon: Icons.battery_charging_full,
            label: 'البطارية',
            value: '${device.batteryCapacityMah} mAh • ${device.batteryLevel}%',
            color: AppColors.success,
          ),
          const Divider(height: 1),
          _specRow(
            icon: Icons.hub,
            label: 'CAN FD',
            value: device.canFdSupported ? 'مدعوم' : 'غير مدعوم',
            color: device.canFdSupported
                ? AppColors.primary
                : AppColors.textHint,
          ),
          const Divider(height: 1),
          _specRow(
            icon: Icons.lan,
            label: 'DoIP',
            value: device.doipSupported ? 'مدعوم (عبر Ethernet)' : 'غير مدعوم',
            color: device.doipSupported
                ? AppColors.primary
                : AppColors.textHint,
          ),
          const Divider(height: 1),
          _specRow(
            icon: Icons.monitor_heart,
            label: 'الأوسيلوسكوب',
            value: device.oscilloscope4ch ? '4 قنوات ملونة' : 'غير متوفر',
            color: device.oscilloscope4ch
                ? AppColors.secondary
                : AppColors.textHint,
          ),
        ],
      ),
    );
  }

  Widget _specRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      leading: Icon(icon, color: color, size: 24),
      title: Text(
        label,
        style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
      ),
      trailing: Text(
        value,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  void _goToTab(BuildContext context, int index) {
    final shell = context.findAncestorStateOfType<MainShellState>();
    shell?.switchTo(index);
  }

  void _requireConnection(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('قم بالاتصال بالجهاز أولاً')),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Material(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              height: 110,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.14),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: color, size: 24),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
