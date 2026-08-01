import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/device.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';

class ConnectionScreen extends StatefulWidget {
  const ConnectionScreen({super.key});

  @override
  State<ConnectionScreen> createState() => _ConnectionScreenState();
}

class _ConnectionScreenState extends State<ConnectionScreen> {
  bool _finding = false;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Scaffold(
      appBar: AppBar(title: const Text('الاتصال بالجهاز')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Icon(
                    Icons.car_repair,
                    size: 64,
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'فاحص برو X1',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'اتصل بالجهاز عبر بلوتوث أو USB أو WiFi',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (state.status == DeviceStatus.connecting)
                    const Column(
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text(
                          'جاري إنشاء الاتصال بالجهاز...',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ],
                    )
                  else ...[
                    const SizedBox(height: 4),
                    const Text(
                      'اختر طريقة الاتصال',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _methodTile(
                      icon: Icons.bluetooth,
                      label: 'البلوتوث',
                      subtitle: 'اتصال لاسلكي سريع',
                      method: ConnectionMethod.bluetooth,
                      state: state,
                    ),
                    _methodTile(
                      icon: Icons.usb,
                      label: 'كابل USB',
                      subtitle: 'أسرع نقل بيانات',
                      method: ConnectionMethod.usb,
                      state: state,
                    ),
                    _methodTile(
                      icon: Icons.wifi,
                      label: 'WiFi',
                      subtitle: 'لأعمال البرمجة والفحوصات الثقيلة',
                      method: ConnectionMethod.wifi,
                      state: state,
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'لم يتم العثور على الجهاز؟',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'تأكد من أن الجهاز مشحون ومُشغّل، ثم ابحث عن الأجهزة المتاحة.',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 14),
                  OutlinedButton.icon(
                    onPressed: _finding ? null : () => _searchDevices(context),
                    icon: _finding
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.search),
                    label: Text(_finding ? 'جاري البحث...' : 'بحث عن الأجهزة'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _methodTile({
    required IconData icon,
    required String label,
    required String subtitle,
    required ConnectionMethod method,
    required AppState state,
  }) {
    final selected =
        state.isConnected && state.device?.connectionMethod == method;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      color: selected ? AppColors.primary : AppColors.surfaceLight,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: selected ? AppColors.primary : AppColors.border,
        ),
      ),
      child: ListTile(
        onTap: () async {
          if (state.status == DeviceStatus.connecting) return;
          final navigator = Navigator.of(context);
          await state.connect(method);
          if (!mounted) return;
          navigator.pop();
        },
        leading: Icon(icon, color: selected ? Colors.black : AppColors.primary),
        title: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: selected ? Colors.black : AppColors.textPrimary,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 12,
            color: selected ? Colors.black.withValues(alpha: 0.7) : AppColors.textHint,
          ),
        ),
        trailing: Icon(
          selected ? Icons.check_circle : Icons.chevron_left,
          color: selected ? Colors.black : AppColors.textHint,
        ),
      ),
    );
  }

  void _searchDevices(BuildContext context) async {
    setState(() => _finding = true);
    await Future<void>.delayed(const Duration(seconds: 3));
    if (!context.mounted) return;
    setState(() => _finding = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم العثور على: فاحص برو X1')),
    );
  }
}
