import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../widgets/connection_status_chip.dart';
import '../widgets/section_title.dart';
import '../widgets/side_menu_button.dart';
import 'connection_screen.dart';
import 'vehicle_select_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final device = state.device;

    return Scaffold(
      appBar: AppBar(
        leading: const SideMenuButton(),
        title: const Text('الإعدادات'),
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
          if (device != null) ...[
            const SectionTitle(title: 'الجهاز'),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.car_repair, color: AppColors.primary),
                    title: Text(device.name,
                        style: const TextStyle(color: AppColors.textPrimary)),
                    subtitle: Text(
                      device.model,
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.confirmation_number_outlined,
                        color: AppColors.textHint),
                    title: const Text('الرقم التسلسلي',
                        style: TextStyle(color: AppColors.textPrimary)),
                    trailing: Text(device.serial,
                        style: const TextStyle(color: AppColors.textSecondary)),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.memory, color: AppColors.textHint),
                    title: const Text('إصدار البرنامج الثابت',
                        style: TextStyle(color: AppColors.textPrimary)),
                    trailing: Text(device.firmware,
                        style: const TextStyle(color: AppColors.textSecondary)),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.bolt, color: AppColors.warning),
                    title: const Text('شحن الجهاز',
                        style: TextStyle(color: AppColors.textPrimary)),
                    trailing: Text(
                      device.charging ? 'يتم الشحن' : 'متوقف',
                      style: TextStyle(
                        color: device.charging
                            ? AppColors.warning
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SectionTitle(title: 'المركبة والاتصال'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.directions_car,
                      color: AppColors.secondary),
                  title: const Text('المركبة',
                      style: TextStyle(color: AppColors.textPrimary)),
                  subtitle: Text(
                    state.vehicle?.shortName ?? 'غير محددة',
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                  trailing: const Icon(Icons.chevron_left,
                      color: AppColors.textHint),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => const VehicleSelectScreen()),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.link, color: AppColors.primary),
                  title: const Text('الجهاز',
                      style: TextStyle(color: AppColors.textPrimary)),
                  subtitle: Text(
                    device != null
                        ? '${device.name} • ${device.methodLabel}'
                        : 'غير متصل',
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                  trailing: state.isConnected
                      ? TextButton(
                          onPressed: () => state.disconnect(),
                          child: const Text('قطع الاتصال'),
                        )
                      : const Icon(Icons.chevron_left,
                          color: AppColors.textHint),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => const ConnectionScreen()),
                  ),
                ),
              ],
            ),
          ),
          const SectionTitle(title: 'البروتوكولات المدعومة'),
          Card(
            child: Column(
              children: [
                _protocolRow(
                  title: 'CAN',
                  subtitle: 'ناقل بيانات التحكم التقليدي',
                  enabled: true,
                ),
                _protocolRow(
                  title: 'CAN FD',
                  subtitle: 'ناقل بيانات عالي السرعة',
                  enabled: device?.canFdSupported ?? false,
                ),
                _protocolRow(
                  title: 'DoIP',
                  subtitle: 'البروتوكول عبر الإيثرنت',
                  enabled: device?.doipSupported ?? false,
                ),
                _protocolRow(
                  title: 'OBD-II / EOBD',
                  subtitle: 'معايير التشخيص العالمية',
                  enabled: true,
                ),
              ],
            ),
          ),
          const SectionTitle(title: 'عام'),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  secondary: const Icon(Icons.notifications_none,
                      color: AppColors.textHint),
                  title: const Text('إشعارات نهاية الفحص',
                      style: TextStyle(color: AppColors.textPrimary)),
                  value: true,
                  onChanged: (_) {},
                ),
                const Divider(height: 1),
                SwitchListTile(
                  secondary: const Icon(Icons.cloud_done,
                      color: AppColors.textHint),
                  title: const Text('تحديث تلقائي لقاعدة البيانات',
                      style: TextStyle(color: AppColors.textPrimary)),
                  value: true,
                  onChanged: (_) {},
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.info_outline, color: AppColors.textHint),
                  title: const Text('حول التطبيق',
                      style: TextStyle(color: AppColors.textPrimary)),
                  trailing: const Text('v2.4.0',
                      style: TextStyle(color: AppColors.textSecondary)),
                  onTap: () => _aboutDialog(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _protocolRow({
    required String title,
    required String subtitle,
    required bool enabled,
  }) {
    return ListTile(
      leading: Icon(
        enabled ? Icons.check_circle : Icons.radio_button_unchecked,
        color: enabled ? AppColors.success : AppColors.textHint,
      ),
      title: Text(title,
          style: const TextStyle(color: AppColors.textPrimary)),
      subtitle: Text(subtitle,
          style: const TextStyle(color: AppColors.textSecondary)),
    );
  }

  void _aboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حول التطبيق'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.car_repair, size: 48, color: AppColors.primary),
            SizedBox(height: 12),
            Text('فاحص برو X1', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            SizedBox(height: 4),
            Text('إصدار التطبيق v2.4.0', style: TextStyle(color: AppColors.textSecondary)),
            SizedBox(height: 12),
            Text('فحص الأنظمة • الأوسيلوسكوب 4 قنوات • البرمجة والتكويد'),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('حسناً'),
          ),
        ],
      ),
    );
  }
}
